//
// Model.swift
// Sessions
//
// Copyright (c) 2020 Hironori Ichimiya <hiron@hironytic.com>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

import Foundation
import UIKit
import RealmSwift
import Combine

struct Session {
    var id: String
    var title: String
    var abstract: String
    var speakerName: String
    var speakerIcon: Data?
    var startsAt: Date
    var track: String
    var length: Int
    var isStarred: Bool

    init(id: String, title: String, abstract: String, speakerName: String, speakerIcon: Data? = nil, startsAt: Date, track: String, length: Int, isStarred: Bool) {
        self.id = id
        self.title = title
        self.abstract = abstract
        self.speakerName = speakerName
        self.speakerIcon = speakerIcon
        self.startsAt = startsAt
        self.track = track
        self.length = length
        self.isStarred = isStarred
    }

    init(from sessionObject: SessionObject) {
        id = sessionObject.id
        title = sessionObject.title
        abstract = sessionObject.abstract
        speakerName = sessionObject.speakerName
        speakerIcon = sessionObject.speakerIcon
        startsAt = sessionObject.startsAt
        track = sessionObject.track
        length = sessionObject.length
        isStarred = sessionObject.isStarred
    }
    
    func toSessionObject() -> SessionObject {
        let obj = SessionObject()
        obj.id = id
        obj.title = title
        obj.abstract = abstract
        obj.speakerName = speakerName
        obj.speakerIcon = speakerIcon
        obj.startsAt = startsAt
        obj.track = track
        obj.length = length
        obj.isStarred = isStarred
        return obj
    }
}

class SessionObject: Object {
    @objc dynamic var id: String = ""
    @objc dynamic var title: String = ""
    @objc dynamic var abstract: String = ""
    @objc dynamic var speakerName: String = ""
    @objc dynamic var speakerIcon: Data? = nil
    @objc dynamic var startsAt: Date = Date(timeIntervalSince1970: 0)
    @objc dynamic var track: String = ""
    @objc dynamic var length: Int = 0
    @objc dynamic var isStarred: Bool = false

    override class func primaryKey() -> String? {
        return "id"
    }
}

private var realm: Realm = { () -> Realm in
    do {
        let documentDirUrl = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
        let realmFileUrl = documentDirUrl.appendingPathComponent("sessions.realm")
        let fm = FileManager.default
        if !fm.fileExists(atPath: realmFileUrl.path) {
            guard let initialDataUrl = Bundle.main.url(forResource: "initial", withExtension: "realm") else {
                fatalError("initial data file not found")
            }
            try fm.copyItem(at: initialDataUrl, to: realmFileUrl)
        }
        
        let config = Realm.Configuration(fileURL: realmFileUrl, objectTypes: [SessionObject.self])
        return try Realm(configuration: config)
    } catch let error {
        fatalError("Failed to create Realm object!!: \(error)")
    }
}()

class SessionStore {
    struct Changes {
        let sessions: [Session]
        let deletions: [Int]
        let insertions: [Int]
        let modifications: [Int]
    }
    
    static let sharedInstance = SessionStore()
    
    var sessions: [Session]
    var changes: AnyPublisher<Changes, Never> { changesSubject.eraseToAnyPublisher() }
    
    private var notificationToken: NotificationToken!
    private let changesSubject = PassthroughSubject<Changes, Never>()
    
    private init() {
        let sessionsResults = realm
            .objects(SessionObject.self)
            .sorted(by: [SortDescriptor(keyPath: "startsAt"), SortDescriptor(keyPath: "track")])
        sessions = sessionsResults.map { Session(from: $0) }
        
        notificationToken = sessionsResults.observe { [weak self] changes in
            guard let self = self else { return }
            
            switch changes {
            case .update(let results, let deletions, let insertions, let modifications):
                self.sessions = results.map { Session(from: $0) }
                let changes = Changes(sessions: self.sessions,
                                      deletions: deletions,
                                      insertions: insertions,
                                      modifications: modifications)
                self.changesSubject.send(changes)
                
            default:
                break
            }
        }
    }
    
    deinit {
        notificationToken.invalidate()
    }
    
    func replaceAllSessions(_ sessions: [Session]) throws {
        let sessionObjs = sessions.map { $0.toSessionObject() }
        
        try realm.write {
            realm.delete(realm.objects(SessionObject.self))
            realm.add(sessionObjs)
        }
    }
    
    func observableSession(of sessionId: String) -> ObservableSession? {
        return ObservableSession(sessionId: sessionId)
    }
    
    func changeSession(of sessionId: String, isStarred: Bool) throws {
        guard let obj = realm.object(ofType: SessionObject.self, forPrimaryKey: sessionId) else { return }
        try realm.write {
            obj.isStarred = isStarred
        }
    }
}

class ObservableSession {
    var session: Session
    var change: AnyPublisher<Session, Never> { changeSubject.eraseToAnyPublisher() }

    private var notificationToken: NotificationToken!
    private let changeSubject = PassthroughSubject<Session, Never>()
    
    fileprivate init?(sessionId: String) {
        guard let obj = realm.object(ofType: SessionObject.self, forPrimaryKey: sessionId) else { return nil }
        session = Session(from: obj)
        notificationToken = obj.observe { [weak self] changes in
            guard let self = self else { return }
            
            switch changes {
            case .change:
                self.session = Session(from: obj)
                self.changeSubject.send(self.session)
            
            default:
                break
            }
        }
    }
    
    deinit {
        notificationToken.invalidate()
    }
}

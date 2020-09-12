//
// SessionDetailViewController.swift
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

import UIKit
import Combine

class SessionDetailViewController: UIViewController {
    var cancellables = Set<AnyCancellable>()
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var minutesLabel: UILabel!
    @IBOutlet weak var startsAtLabel: UILabel!
    @IBOutlet weak var trackLabel: UILabel!
    @IBOutlet weak var speakerIcon: UIImageView!
    @IBOutlet weak var speakerLabel: UILabel!
    @IBOutlet weak var abstractLabel: UILabel!
    @IBOutlet weak var starIcon: UIButton!
    
    private(set) var sessionId: String = ""
    private(set) var isAuxiliary: Bool = false
    private var obsSession: ObservableSession?
    
    static func instantiate(sessionId: String, isAuxiliary: Bool) -> SessionDetailViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        let viewController = storyboard.instantiateViewController(identifier: "SessionDetail") as! SessionDetailViewController
        viewController.sessionId = sessionId
        viewController.isAuxiliary = isAuxiliary
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if isAuxiliary {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close", style: .plain, target: self, action: #selector(closeButtonDidTap(_:)))
        }
        
        starIcon.imageView?.contentMode = .scaleAspectFit

        let sessionStore = SessionStore.sharedInstance
        if let obsSession = sessionStore.observableSession(of: sessionId) {
            self.obsSession = obsSession
            update(from: obsSession.session)
            obsSession.change
                .sink { [weak self] session in
                    self?.update(from: session)
                }
                .store(in: &cancellables)

            // Register to quick actions
            let targetContentIdentifier = "com.hironytic.Sessions.SessionDetail/\(sessionId)"
            let shortcutItem = UIMutableApplicationShortcutItem(type: "com.hironytic.Sessions.SessionDetail",
                                                                localizedTitle: obsSession.session.title,
                                                                localizedSubtitle: nil,
                                                                icon: nil,
                                                                userInfo: ["sessionId": sessionId as NSSecureCoding])
            shortcutItem.targetContentIdentifier = targetContentIdentifier
            var shortcutItems = UIApplication.shared.shortcutItems ?? []
            shortcutItems.removeAll(where: { $0.targetContentIdentifier as? String ?? "" == targetContentIdentifier })
            shortcutItems.insert(shortcutItem, at: 0)
            UIApplication.shared.shortcutItems = shortcutItems
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let userActivity = NSUserActivity(activityType: "com.hironytic.Sessions.SessionDetail")
        userActivity.userInfo = [
            "sessionId": sessionId,
            "isAuxiliary": isAuxiliary,
        ]
        if let scene = view.window?.windowScene {
            scene.userActivity = userActivity
            scene.title = titleLabel.text
        }
        
        if let activationConditions = view.window?.windowScene?.activationConditions {
            let targetContentIdentifier = "com.hironytic.Sessions.SessionDetail/\(sessionId)"
            let predicate = NSPredicate(format: "Self == %@", targetContentIdentifier)
            activationConditions.canActivateForTargetContentIdentifierPredicate = predicate
            activationConditions.prefersToActivateForTargetContentIdentifierPredicate = predicate
        }
    }
    
    private func update(from session: Session) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        titleLabel.text = session.title
        minutesLabel.text = "\(session.length) min."
        startsAtLabel.text = dateFormatter.string(from: session.startsAt)
        trackLabel.text = session.track
        speakerLabel.text = session.speakerName
        speakerIcon.image = session.speakerIcon.map { UIImage(data: $0) } ?? UIImage(systemName: "person.fill")
        speakerIcon.layer.cornerRadius = speakerIcon.frame.height / 2.0
        starIcon.setImage(session.isStarred ? UIImage(systemName: "star.fill") : UIImage(systemName: "star"), for: .normal)
        abstractLabel.text = session.abstract
        view.window?.windowScene?.title = session.title
    }
    
    @IBAction func starIconDidTap(_ sender: Any) {
        guard let session = obsSession?.session else { return }
        
        let sessionStore = SessionStore.sharedInstance
        try? sessionStore.changeSession(of: sessionId, isStarred: !session.isStarred)
    }
    
    @objc
    private func closeButtonDidTap(_ sender: Any) {
        guard let scene = view.window?.windowScene else { return }
        let options = UIWindowSceneDestructionRequestOptions()
        options.windowDismissalAnimation = .standard
        UIApplication.shared.requestSceneSessionDestruction(scene.session, options: options)
    }
}

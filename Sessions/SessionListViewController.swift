//
// SessionListViewController.swift
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

class SessionListViewController: UITableViewController {
    var cancellables = Set<AnyCancellable>()
    var isViewAppeared: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dragDelegate = self
        
        let sessionStore = SessionStore.sharedInstance
        sessions = sessionStore.sessions
        
        sessionStore.changes
            .sink { [weak self] changes in
                guard let self = self else { return }
                
                self.sessions = changes.sessions
                
                if self.isViewAppeared {
                    self.tableView.beginUpdates()
                    self.tableView.deleteRows(at: changes.deletions.map { IndexPath(row: $0, section: 0) }, with: .fade)
                    self.tableView.insertRows(at: changes.insertions.map { IndexPath(row: $0, section: 0) }, with: .fade)
                    self.tableView.reloadRows(at: changes.modifications.map { IndexPath(row: $0, section: 0) }, with: .fade)
                    self.tableView.endUpdates()
                } else {
                    self.tableView.reloadData()
                }
            }
            .store(in: &cancellables)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        view.window?.windowScene?.userActivity = nil

        isViewAppeared = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        isViewAppeared = false
        super.viewWillDisappear(animated)
    }

    var sessions: [Session] = []
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sessions.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let session = sessions[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! SessionListCell

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        cell.startsAtLabel.text = dateFormatter.string(from: session.startsAt) + " " + session.track
        cell.minutesLabel.text = "\(session.length) min."
        cell.titleLabel.text = session.title
        cell.speakerLabel.text = session.speakerName
        cell.speakerIcon.image = session.speakerIcon.map { UIImage(data: $0) } ?? UIImage(systemName: "person.fill")
        cell.speakerIcon.layer.cornerRadius = cell.speakerIcon.frame.height / 2.0
        cell.starIcon.image = session.isStarred ? UIImage(systemName: "star.fill") : nil
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let session = sessions[indexPath.row]

        let detailVc = SessionDetailViewController.instantiate(sessionId: session.id)
        navigationController?.pushViewController(detailVc, animated: true)
    }
}

extension SessionListViewController: UITableViewDragDelegate {
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let session = sessions[indexPath.row]
        let userActivity = NSUserActivity(activityType: "com.hironytic.Sessions.SessionDetail")
        userActivity.userInfo = [
            "sessionId": session.id
        ]
        
        let itemProvider = NSItemProvider(object: userActivity)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        return [dragItem]
    }
}

class SessionListCell: UITableViewCell {
    @IBOutlet weak var startsAtLabel: UILabel!
    @IBOutlet weak var minutesLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var speakerLabel: UILabel!
    @IBOutlet weak var speakerIcon: UIImageView!
    @IBOutlet weak var starIcon: UIImageView!
}

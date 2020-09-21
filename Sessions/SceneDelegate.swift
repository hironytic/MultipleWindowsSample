//
// SceneDelegate.swift
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

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
        
        if let shortcutItem = connectionOptions.shortcutItem {
            setupViewController(for: shortcutItem)
        } else if let activity = connectionOptions.userActivities.first ?? session.stateRestorationActivity {
            setupViewController(with: activity)
        }
    }
    
    func setupViewController(with activity: NSUserActivity) {
        guard activity.activityType == "com.hironytic.Sessions.SessionDetail" else { return }
        guard let sessionId = activity.userInfo?["sessionId"] as? String else { return }
        let isAuxiliary = activity.userInfo?["isAuxiliary"] as? Bool ?? false
        setupDetailViewController(sessionId: sessionId, isAuxiliary: isAuxiliary)
    }
    
    func setupViewController(for shortcutItem: UIApplicationShortcutItem) {
        guard shortcutItem.type == "com.hironytic.Sessions.SessionDetail" else { return }
        guard let sessionId = shortcutItem.userInfo?["sessionId"] as? String else { return }
        setupDetailViewController(sessionId: sessionId, isAuxiliary: false)
    }
    
    func setupDetailViewController(sessionId:  String, isAuxiliary: Bool) {
        guard let navigationController = window?.rootViewController as? UINavigationController else { return }
        let detailVc = SessionDetailViewController.instantiate(sessionId: sessionId, isAuxiliary: isAuxiliary)
        navigationController.popToRootViewController(animated: false)
        navigationController.pushViewController(detailVc, animated: false)
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        print("[sceneDelegate] sceneDidBecomeActive")
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
        print("[sceneDelegate] sceneWillResignActive")
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        print("[sceneDelegate] sceneWillEnterForeground")
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        print("[sceneDelegate] sceneDidEnterBackground")
    }

    func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
        return scene.userActivity
    }

    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        setupViewController(for: shortcutItem)
        completionHandler(true)
    }
}


//
//  AppDelegate.swift
//  ChatDemo
//
//  Created by vishal on 14/07/19.
//  Copyright © 2019 vishal. All rights reserved.
//

import UIKit
import CoreData

let appdelegate = UIApplication.shared.delegate as! AppDelegate
let window = UIApplication.shared.windows[0]



@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var objAPI : SocketManagerAPI!
    var bgSessionCompletionHandler: (() -> Void)?
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        objAPI = SocketManagerAPI.shared
        MTPLAPIManager.shared.setupReachability()

        if UserDefaults.standard.userID != nil {
            appdelegate.objAPI.connectSocket(completion: nil)
            let  storyboard = UIStoryboard.init(name: "Main", bundle: Bundle.main)
            if #available(iOS 13.0, *) {
                
            } else {
                let navigation = storyboard.instantiateViewController(withIdentifier: "NavigationController") as! UINavigationController
                let home = storyboard.instantiateViewController(withIdentifier: "ChatListViewController") as! ChatListViewController
                navigation.viewControllers.append(home)
                window?.rootViewController = navigation
                window?.makeKeyAndVisible()
            }
        }
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }

    // MARK: UISceneSession Lifecycle

    @available(iOS 13.0, *)
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    @available(iOS 13.0,*)
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "ChatDemo")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            print(" ------ 🛤 ------> \(container.persistentStoreCoordinator.persistentStores.first?.url?.absoluteString ?? "Null") <------ 🛤 ------")
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        
        bgSessionCompletionHandler = completionHandler
    }
}


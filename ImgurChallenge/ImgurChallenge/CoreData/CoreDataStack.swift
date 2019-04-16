//
//  CoreDataStack.swift
//  ImgurChallenge
//
//  Created by Matt Bearson on 4/10/19.
//  Copyright © 2019 Matt Bearson. All rights reserved.
//

import Foundation
import CoreData

class CoreDataStack: NSObject {
    
    static let shared = CoreDataStack()
    var container: NSPersistentContainer?
    
    private override init() {
        container = NSPersistentContainer(name: "ImgurChallenge")
    }
    
    func loadStore(completionHandler: @escaping () -> ()) {
        self.container?.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
    }
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        guard let context = self.container?.viewContext
            else { debugPrint("CoreDataStack error 1"); return }
        context.undoManager = nil
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    // MARK: - Core Data Deletion support
    
    func deleteAll(entityName: String) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        deleteRequest.resultType = .resultTypeObjectIDs
        guard let context = self.container?.viewContext
            else { debugPrint("error in deleteAll"); return }
        do {
            let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
            let objectIDArray = result?.result as? [NSManagedObjectID]
            let changes: [AnyHashable : Any] = [NSDeletedObjectsKey : objectIDArray as Any]
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
        } catch {
            debugPrint(error.localizedDescription)
        }
    }
}

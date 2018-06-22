//
//  OfflineFilesTableViewController.swift
//  AmahiAnywhere
//
//  Created by codedentwickler on 6/15/18.
//  Copyright © 2018 Amahi. All rights reserved.
//

import UIKit
import CoreData

class OfflineFilesTableViewController : CoreDataTableViewController {
    
    internal var fileSort = OfflineFileSort.dateAdded
    internal var docController: UIDocumentInteractionController?
    
    internal var presenter: OfflineFilesPresenter!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        debugPrint("Active Downloads \(DownloadService.shared.activeDownloads)")
        
        presenter = OfflineFilesPresenter(self)

        self.navigationItem.title = StringLiterals.OFFLINE
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        tableView.addGestureRecognizer(longPressGesture)
        
        // Setup Core Data for TableView
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let stack = delegate.stack
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "OfflineFile")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "downloadDate", ascending: false)]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
    }
    
    @objc func handleLongPress(sender: UILongPressGestureRecognizer){
        if sender.state == UIGestureRecognizerState.began {
            let touchPoint = sender.location(in: tableView)
            if let indexPath = tableView.indexPathForRow(at: touchPoint) {
                
                let offlineFile = self.fetchedResultsController!.object(at: indexPath) as! OfflineFile

                let delete = self.creatAlertAction(StringLiterals.DELETE, style: .default) { (action) in
                    
                    // Delete file in downloads directory
                    let fileManager = FileManager.default
                    do {
                        try fileManager.removeItem(at: fileManager.localFilePathInDownloads(for: offlineFile)!)
                    } catch let error {
                        debugPrint("Couldn't Delete file from Downloads \(error.localizedDescription)")
                    }
                    
                    let delegate = UIApplication.shared.delegate as! AppDelegate
                    let stack = delegate.stack
                    
                    // Delete Offline File from core date and persist new changes immediately
                    stack.context.delete(offlineFile)
                    try? stack.saveContext()
                    debugPrint("File was deleted from Downloads")
                }!
                
                let share = self.creatAlertAction(StringLiterals.SHARE, style: .default) { (action) in
                    guard let url = FileManager.default.localFilePathInDownloads(for: offlineFile) else { return }
                    self.shareFile(at: url)
                }!
                
                let cancel = self.creatAlertAction(StringLiterals.CANCEL, style: .cancel, clicked: nil)!
                
                self.createActionSheet(title: "",
                                       message: StringLiterals.CHOOSE_ONE,
                                       ltrActions: [delete, share, cancel],
                                       preferredActionPosition: 0)
            }
        }
    }
}

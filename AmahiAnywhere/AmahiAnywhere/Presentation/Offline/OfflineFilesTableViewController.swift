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
     
        presenter = OfflineFilesPresenter(self)

        self.navigationItem.title = StringLiterals.OFFLINE
        
        // Setup Core Data Fetch for TableView
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let stack = delegate.stack
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "OfflineFile")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "downloadDate", ascending: false)]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
    }
}

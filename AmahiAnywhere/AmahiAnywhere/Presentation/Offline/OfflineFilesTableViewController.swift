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
    
    private var fileSort = OfflineFileSort.dateAdded
    private var docController: UIDocumentInteractionController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
     
        title = StringLiterals.OFFLINE
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let stack = delegate.stack
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "OfflineFile")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: false)]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let offlineFile = fetchedResultsController!.object(at: indexPath) as! OfflineFile
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "OfflineFileTableViewCell", for: indexPath) as! OfflineFileTableViewCell
        cell.fileNameLabel?.text = offlineFile.name
        cell.fileSizeLabel?.text = offlineFile.getFileSize()
        cell.downloadDateLabel?.text = offlineFile.downloadDate?.asString
        return cell
    }
}

// MARK: - OfflineFileTableViewCell

class OfflineFileTableViewCell: UITableViewCell {
    
    @IBOutlet weak var fileNameLabel: UILabel!
    @IBOutlet weak var fileSizeLabel: UILabel!
    @IBOutlet weak var downloadDateLabel: UILabel!
    
}

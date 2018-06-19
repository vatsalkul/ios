//
//  OfflineFilesTableViewController+UITableViewDelegates.swift
//  AmahiAnywhere
//
//  Created by codedentwickler on 6/17/18.
//  Copyright © 2018 Amahi. All rights reserved.
//

import Foundation

extension OfflineFilesTableViewController {
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let offlineFile = fetchedResultsController!.object(at: indexPath) as! OfflineFile
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "OfflineFileTableViewCell", for: indexPath) as! OfflineFileTableViewCell
        cell.fileNameLabel?.text = offlineFile.name
        cell.fileSizeLabel?.text = offlineFile.getFileSize()
        cell.downloadDateLabel?.text = offlineFile.downloadDate?.asString
        cell.progressView.setProgress(offlineFile.progress, animated: false)
        
        if offlineFile.progress == 1 {
            cell.progressView.isHidden = true
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
            let offlineFile = self.fetchedResultsController!.object(at: indexPath) as! OfflineFile
            
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
        }
        delete.backgroundColor = UIColor.red
        
        let share = UITableViewRowAction(style: .normal, title: "Share") { (action, indexPath) in
            let offlineFile = self.fetchedResultsController!.object(at: indexPath) as! OfflineFile
            
            guard let url = FileManager.default.localFilePathInDownloads(for: offlineFile) else { return }
            self.shareFile(at: url)
        }
        share.backgroundColor = UIColor.blue
        
        return [share, delete]
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let offlineFiles : [OfflineFile] = fetchedResultsController?.fetchedObjects as! [OfflineFile]
        if offlineFiles[indexPath.row].stateEnum == .downloaded {
            presenter.handleOfflineFile(fileIndex: indexPath.row, files: offlineFiles)
        }
        tableView.deselectRow(at: indexPath, animated: false)
    }
}

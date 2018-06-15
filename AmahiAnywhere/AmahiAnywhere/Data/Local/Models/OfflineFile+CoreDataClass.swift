//
//  OfflineFile+CoreDataClass.swift
//  AmahiAnywhere
//
//  Created by codedentwickler on 6/15/18.
//  Copyright © 2018 Amahi. All rights reserved.
//
//

import Foundation
import CoreData


public class OfflineFile: NSManagedObject {

    // MARK: Initializer
    
    convenience init(name: String,
                     share: String,
                     mime: String,
                     size: Int64,
                     localPath: String,
                     fileUri: String,
                     downloadId: Int64,
                     state: Int16,
                     context: NSManagedObjectContext) {
        
        // An EntityDescription is an object that has access to all
        // the information you provided in the Entity part of the model
        // you need it to create an instance of this class.
        if let ent = NSEntityDescription.entity(forEntityName: "OfflineFile", in: context) {
            self.init(entity: ent, insertInto: context)
            
            self.name = name
            self.share = share
            self.mime = mime
            self.size = size
            self.localPath = localPath
            self.remoteFileUri = fileUri
            self.downloadId = downloadId
            self.downloadDate = Date()
            self.state = state
        } else {
            fatalError("Unable to find Entity name!")
        }
    }
    
    public func getFileSize() -> String {
        return ByteCountFormatter().string(fromByteCount: size)
    }
}

extension OfflineFile {
    static let nameSorter: (OfflineFile, OfflineFile) -> Bool = { $0.name!.localizedCaseInsensitiveCompare($1.name!) == ComparisonResult.orderedAscending }
    static let downloadDateSorter: (OfflineFile, OfflineFile) -> Bool = { $0.downloadDate! > $1.downloadDate! }
}

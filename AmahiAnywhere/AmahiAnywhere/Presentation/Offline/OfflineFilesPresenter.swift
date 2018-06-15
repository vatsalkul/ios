//
//  OfflineFilesPresenter.swift
//  AmahiAnywhere
//
//  Created by codedentwickler on 6/15/18.
//  Copyright © 2018 Amahi. All rights reserved.
//

import Foundation
import Lightbox

protocol OfflineFilesView : BaseView {
    func initFiles(_ files: [OfflineFile])
    
    func updateFiles(_ files: [OfflineFile])
    
    func present(_ controller: UIViewController)
    
    func playMedia(at url: URL)
    
    func webViewOpenContent(at url: URL, mimeType: MimeType)
    
    func shareFile(at url: URL)
}

class OfflineFilesPresenter: BasePresenter {
    
    weak private var view: OfflineFilesView?
    
    init(_ view: OfflineFilesView) {
        self.view = view
    }
    
    func detachView() {
        self.view = nil
    }
    
    func loadOfflineFiles() {
        
    }
    
    func filterFiles(_ searchText: String, files: [OfflineFile], sortOrder: OfflineFileSort) {
        if searchText.count > 0 {
            let filteredFiles = files.filter { file in
                return file.name!.localizedCaseInsensitiveContains(searchText)
            }
            self.reorderFiles(files: filteredFiles, sortOrder: sortOrder)
        } else {
            self.reorderFiles(files: files, sortOrder: sortOrder)
        }
    }
    
    func reorderFiles(files: [OfflineFile], sortOrder: OfflineFileSort) {
        let sortedFiles = files.sorted(by: getSorter(sortOrder))
        self.view?.updateFiles(sortedFiles)
    }
    
    private func getSorter(_ sortOrder: OfflineFileSort) -> ((OfflineFile, OfflineFile) -> Bool) {
        switch sortOrder {
        case .dateAdded:
            return OfflineFile.downloadDateSorter
        case .name:
            return OfflineFile.nameSorter
        }
    }
    
    func handleFileOpening(fileIndex: Int, files: [OfflineFile]) {
        let file = files[fileIndex]
        
        let type = Mimes.shared.match(file.mime!)
        
        switch type {
            
        case MimeType.image:
            // prepare ImageViewer
            let controller = LightboxController(images: prepareImageArray(files), startIndex: fileIndex)
            controller.dynamicBackground = true
            self.view?.present(controller)
            break
            
        case MimeType.video, MimeType.audio:
            // TODO: open VideoPlayer and play the file
            let url = URL(string: file.localPath!)
            self.view?.playMedia(at: url!)
            return
            
        case MimeType.code, MimeType.presentation, MimeType.sharedFile, MimeType.document, MimeType.spreadsheet:
            if fileExists(fileName: file.localPath!) {
                if type == MimeType.sharedFile {
                    self.view?.shareFile(at: localPath(for: file))
                } else {
                    self.view?.webViewOpenContent(at: localPath(for: file), mimeType: type)
                }
            } else {
                debugPrint("OFFLINE FILE DOES NOT EXIST IN EXPECTED LOCATION !!!")
            }
            break
            
        default:
            // TODO: show list of apps that can open the file
            return
        }
    }
    
    private func localPath(for file: OfflineFile) -> URL {

        let fileManager = FileManager.default
        let tempDirectory = fileManager.temporaryDirectory
        let cacheFolderPath = tempDirectory.appendingPathComponent("cache")

        return cacheFolderPath.appendingPathComponent(file.localPath!)
    }

    private func fileExists(fileName: String) -> Bool {
        
        let fileManager = FileManager.default
        let tempDirectory = fileManager.temporaryDirectory
        let cacheFolderPath = tempDirectory.appendingPathComponent("cache")
        
        let pathComponent = cacheFolderPath.appendingPathComponent(fileName)
        let filePath = pathComponent.path
        if fileManager.fileExists(atPath: filePath) {
            return true
        } else {
            return false
        }
    }
    
    private func prepareImageArray(_ files: [OfflineFile]) -> [LightboxImage] {
        var images: [LightboxImage] = [LightboxImage] ()
        for file in files {
            if (Mimes.shared.match(file.mime!) == MimeType.image) {
                images.append(LightboxImage(imageURL: URL(string: file.localPath!)!, text: file.name!))
            }
        }
        return images
    }
}

enum OfflineFileSort {
    case dateAdded
    case name
}

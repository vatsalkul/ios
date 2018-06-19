//
//  FilesPresenter.swift
//  AmahiAnywhere
//
//  Created by Chirag Maheshwari on 08/03/18.
//  Copyright © 2018 Amahi. All rights reserved.
//

import Foundation
import Lightbox
import CoreData

internal protocol FilesView : BaseView {
    func initFiles(_ files: [ServerFile])
    
    func updateFiles(_ files: [ServerFile])
    
    func updateRefreshing(isRefreshing: Bool)
    
    func present(_ controller: UIViewController)
    
    func playMedia(at url: URL)
    
    func webViewOpenContent(at url: URL, mimeType: MimeType)
    
    func shareFile(at url: URL)
    
    func updateDownloadProgress(for row: Int, downloadJustStarted: Bool, progress: Float)
    
    func dismissProgressIndicator(at url: URL, completion: @escaping () -> Void)
}

internal class FilesPresenter: BasePresenter {
    
    weak private var view: FilesView?
    lazy private var offlineFiles : [String: OfflineFile] = self.loadOfflineFiles()
    
    init(_ view: FilesView) {
        self.view = view
    }
    
    func detachView() {
        self.view = nil
    }
    
    func getFiles(_ share: ServerShare, directory: ServerFile? = nil) {
        
        self.view?.updateRefreshing(isRefreshing: true)
        
        ServerApi.shared?.getFiles(share: share, directory: directory) { (serverFilesResponse) in
            
            self.view?.updateRefreshing(isRefreshing: false)
            
            guard let serverFiles = serverFilesResponse else {
                self.view?.showError(message: StringLiterals.GENERIC_NETWORK_ERROR)
                return
            }
            
            self.view?.initFiles(serverFiles)
            self.view?.updateFiles(serverFiles.sorted(by: ServerFile.lastModifiedSorter))
        }
    }
    
    func filterFiles(_ searchText: String, files: [ServerFile], sortOrder: FileSort) {
        if searchText.count > 0 {
            let filteredFiles = files.filter { file in
                return file.name!.localizedCaseInsensitiveContains(searchText)
            }
            self.reorderFiles(files: filteredFiles, sortOrder: sortOrder)
        } else {
            self.reorderFiles(files: files, sortOrder: sortOrder)
        }
    }
    
    func reorderFiles(files: [ServerFile], sortOrder: FileSort) {
        let sortedFiles = files.sorted(by: getSorter(sortOrder))
        self.view?.updateFiles(sortedFiles)
    }
    
    private func getSorter(_ sortOrder: FileSort) -> ((ServerFile, ServerFile) -> Bool) {
        switch sortOrder {
        case .modifiedTime:
            return ServerFile.lastModifiedSorter
        case .name:
            return ServerFile.nameSorter
        }
    }
    
    func handleFileOpening(fileIndex: Int, files: [ServerFile]) {
        let file = files[fileIndex]
        
        let type = Mimes.shared.match(file.mime_type!)
        
        switch type {
            
        case MimeType.image:
            // prepare ImageViewer
            let controller = LightboxController(images: prepareImageArray(files), startIndex: fileIndex)
            controller.dynamicBackground = true
            self.view?.present(controller)
            break
            
        case MimeType.video, MimeType.audio:
            // TODO: open VideoPlayer and play the file
            let url = ServerApi.shared!.getFileUri(file)
            self.view?.playMedia(at: url)
            return
            
        case MimeType.code, MimeType.presentation, MimeType.sharedFile, MimeType.document, MimeType.spreadsheet:
            if FileManager.default.fileExistsInCache(file){
                let path = FileManager.default.localPathInCache(for: file)
                if type == MimeType.sharedFile {
                    self.view?.shareFile(at: path)
                } else {
                    self.view?.webViewOpenContent(at: path, mimeType: type)
                }
            } else {
                downloadAndOpenFile(at: fileIndex, file, mimeType: type)
            }
            break
            
        default:
            // TODO: show list of apps that can open the file
            return
        }
    }
    
    public func makeFileAvailableOffline(_ serverFile: ServerFile) {
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let stack = delegate.stack
        
        let offlineFile = OfflineFile(name: serverFile.getNameOnly(),
                                      mime: serverFile.mime_type!,
                                      size: serverFile.size!,
                                      mtime: serverFile.mtime!,
                                      fileUri: ServerApi.shared!.getFileUri(serverFile).absoluteString,
                                      localPath: serverFile.getPath(),
                                      progress: 1,
                                      state: OfflineFileState.downloading,
                                      context: stack.context)
        
        DownloadService.shared.startDownload(offlineFile)
    }
    
    private func downloadAndOpenFile(at fileIndex: Int ,_ serverFile: ServerFile, mimeType: MimeType) {
        
        self.view?.updateDownloadProgress(for: fileIndex, downloadJustStarted: true, progress: 0.0)
        
        // cleanup temp files in background
        DispatchQueue.global(qos: .background).async {
            FileManager.default.cleanUpFiles(in: FileManager.default.temporaryDirectory,
                                             folderName: "cache")
        }
        
        Network.shared.downloadFileToStorage(file: serverFile, progressCompletion: { progress in
            self.view?.updateDownloadProgress(for: fileIndex, downloadJustStarted: false, progress: progress)
        }, completion: { (wasSuccessful) in
            
            if !wasSuccessful  {
                self.view?.showError(message: StringLiterals.ERROR_DOWNLOADING_FILE)
                return
            }
            
            let filePath = FileManager.default.localPathInCache(for: serverFile)
            
            self.view?.dismissProgressIndicator(at: filePath, completion: {
                
                if mimeType == MimeType.sharedFile {
                    self.view?.shareFile(at: filePath)
                } else {
                    self.view?.webViewOpenContent(at: filePath, mimeType: mimeType)
                }
            })
        })
    }
    
    private func prepareImageArray(_ files: [ServerFile]) -> [LightboxImage] {
        var images: [LightboxImage] = [LightboxImage] ()
        for file in files {
            if (Mimes.shared.match(file.mime_type!) == MimeType.image) {
                images.append(LightboxImage(imageURL: ServerApi.shared!.getFileUri(file), text: file.name!))
            }
        }
        return images
    }
    
    private func loadOfflineFiles() ->  [String : OfflineFile] {
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "OfflineFile")
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let stack = delegate.stack
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
        let offlineFiles : [OfflineFile] = fetchedResultsController.fetchedObjects as! [OfflineFile]
     
        var dictionary = [String : OfflineFile]()
            
        for file in offlineFiles {
            dictionary[file.name!] = file
        }
        
        return dictionary
    }
    
    func checkFileOfflineState(_ file: ServerFile) -> OfflineFileState {
        
        if let offlineFile = offlineFiles[file.name!] {
            
            if file.mtime! != offlineFile.mtime! || file.size! != offlineFile.size {
                return .outdated
            }
            
            return offlineFile.stateEnum
        } else {
            return .none
        }
    }
}

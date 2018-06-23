//
//  DownloadService+URLSessionDelegate.swift
//  AmahiAnywhere
//
//  Created by codedentwickler on 6/18/18.
//  Copyright © 2018 Amahi. All rights reserved.
//

import Foundation

// MARK: - URLSessionDelegate

extension DownloadService: URLSessionDelegate {
    
    // Standard background session handler
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
                let completionHandler = appDelegate.backgroundSessionCompletionHandler {
                appDelegate.backgroundSessionCompletionHandler = nil
                completionHandler()
            }
        }
    }
}

extension DownloadService: URLSessionDownloadDelegate {
    
    // Stores downloaded file
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        debugPrint("Download Has Completed")
    
        guard let sourceURL = downloadTask.originalRequest?.url else { return }
        guard let download = DownloadService.shared.activeDownloads[sourceURL] else { return }
        DownloadService.shared.activeDownloads[sourceURL] = nil
        
        let destinationURL = FileManager.default.localFilePathInDownloads(for: download.offlineFile)!
        debugPrint("DestinationURL::: \(destinationURL)")
        
        let fileManager = FileManager.default
        try? fileManager.removeItem(at: destinationURL)
        do {
            try fileManager.moveItem(at: location, to: destinationURL)
            download.offlineFile.stateEnum = .downloaded
            
        } catch let error {
            debugPrint("Could not move file to disk: \(error.localizedDescription)")
        }
    }
    
    // Updates progress info
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64, totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {

        guard let url = downloadTask.originalRequest?.url,
            let download = DownloadService.shared.activeDownloads[url]  else { return }

        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        download.progress = progress
        download.offlineFile.progress = progress
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        debugPrint("Download completed: \(task), error: \(error?.localizedDescription ?? "")")
    }
}

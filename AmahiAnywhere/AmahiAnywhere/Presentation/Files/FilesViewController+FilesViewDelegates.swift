//
//  FilesViewController+FilesViewDelegates.swift
//  AmahiAnywhere
//
//  Created by codedentwickler on 6/17/18.
//  Copyright © 2018 Amahi. All rights reserved.
//

import AVKit
import Foundation
import MediaPlayer

// MARK: Files View implementations

extension FilesViewController: FilesView {
    
    func dismissProgressIndicator(at url: URL, completion: @escaping () -> Void) {
        downloadProgressAlertController?.dismiss(animated: true, completion: {
            completion()
        })
        downloadProgressAlertController = nil
        progressView = nil
        isAlertShowing = false
    }
    
    func updateDownloadProgress(for row: Int, downloadJustStarted: Bool , progress: Float) {
        
        if downloadJustStarted {
            setupDownloadProgressIndicator()
            downloadProgressAlertController?.title = String(format: StringLiterals.DOWNLOADING_FILE, self.filteredFiles[row].name!)
        }
        
        if !isAlertShowing {
            self.isAlertShowing = true
            present(downloadProgressAlertController!, animated: true, completion: nil)
        }
        
        progressView?.setProgress(progress, animated: true)
    }
    
    func shareFile(at url: URL, from sender : UIView? ) {
        let linkToShare = [url]
        
        let activityController = UIActivityViewController(activityItems: linkToShare, applicationActivities: nil)
        if let popoverController = activityController.popoverPresentationController, let sender = sender {
            popoverController.sourceView = sender
            popoverController.sourceRect = sender.bounds
        }
        self.present(activityController, animated: true, completion: nil)
    }
    
    func webViewOpenContent(at url: URL, mimeType: MimeType) {
        let webViewVc = self.viewController(viewControllerClass: WebViewController.self,
                                            from: StoryBoardIdentifiers.MAIN)
        webViewVc.url = url
        webViewVc.mimeType = mimeType
        self.navigationController?.pushViewController(webViewVc, animated: true)
    }
    
    func playMedia(at url: URL) {
        let videoPlayerVc = self.viewController(viewControllerClass: VideoPlayerViewController.self,
                                                from: StoryBoardIdentifiers.VIDEO_PLAYER)
        videoPlayerVc.mediaURL = url
        self.present(videoPlayerVc)
    }
    
    func playAudio(_ items: [AVPlayerItem], startIndex: Int) {
        
        let avPlayerVC = AVPlayerViewController()
        player = AVQueuePlayer(items: items)
        player.actionAtItemEnd = .advance
        avPlayerVC.player = player

        present(avPlayerVC, animated: true) {

            for item in items {
                NotificationCenter.default.addObserver(self,
                                                       selector: #selector(self.nextAudio),
                                                       name: .AVPlayerItemDidPlayToEndTime,
                                                       object: item)
            }

            // display the details of the first item
            self.setNowPlayingInfo(item: items[0])

            self.player.play()
        }
    }
    
    func setNowPlayingInfo(item: AVPlayerItem) {

        //print("display_details")

        // Get Now Playing information and set it appropriately
        let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
        var nowPlayingInfo = nowPlayingInfoCenter.nowPlayingInfo ?? [String: Any]()

        let metadataList = item.asset.metadata

        for item in metadataList {

            guard let key = item.commonKey, let value = item.value else {
                continue
            }

            switch key {
            case .commonKeyTitle : nowPlayingInfo[MPMediaItemPropertyTitle] = (value as? String)!
            case .commonKeyArtist: nowPlayingInfo[MPMediaItemPropertyArtist] = (value as? String)!
            case .commonKeyAlbumName: nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = (value as? String)!
            case .commonKeyArtwork:
                let image = UIImage(data: value as! Data)
                let mediaImageArtwork = MPMediaItemArtwork(boundsSize: (image?.size)!, requestHandler: { (size) -> UIImage in
                    return image!
                })
                nowPlayingInfo[MPMediaItemPropertyArtwork] = mediaImageArtwork
            default:
                continue
            }
        }

        nowPlayingInfo[MPMediaItemPropertyMediaType] = MPNowPlayingInfoMediaType.audio.rawValue

        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
    }

    @objc func nextAudio(notification: Notification) {

        // print("next_audio")

        // AmahiLogger.log("nextAudio was called")
        guard player != nil else { return }

        let currentItem = player.currentItem!
        self.setNowPlayingInfo(item: currentItem)
    }
    
    override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        let affectedKeyPathsMappingByKey: [String: Set<String>] = [
            "rate":         [#keyPath(FilesViewController.player.rate)]
        ]
        
        return affectedKeyPathsMappingByKey[key] ?? super.keyPathsForValuesAffectingValue(forKey: key)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        // print("observe value")
        // Make sure the this KVO callback was intended for this view controller.
        let ctx = context
        guard ctx == &playerKVOContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: ctx)
            return
        }
        
        if keyPath == #keyPath(AVPlayerItem.status) {
            let status: AVPlayerItemStatus
            
            // Get the status change from the change dictionary
            if let statusNumber = change?[.newKey] as? NSNumber {
                status = AVPlayerItemStatus(rawValue: statusNumber.intValue)!
            } else {
                status = .unknown
            }

            // Switch over the status
            if status == .readyToPlay {
                // Player item is ready to play.
                print("item ready to play!")
            } else {
                print("item status is \(status): \(change?[.newKey] as? NSNumber)")
            }
        }
    }
    
    func present(_ controller: UIViewController) {
        self.present(controller, animated: true)
    }
    
    func initFiles(_ files: [ServerFile]) {
        self.serverFiles = files
    }
    
    func updateFiles(_ files: [ServerFile]) {
        self.filteredFiles = files
        filesTableView.reloadData()
    }
    
    func updateRefreshing(isRefreshing: Bool) {
        if isRefreshing {
            refreshControl?.beginRefreshing()
        } else {
            refreshControl?.endRefreshing()
        }
    }
}

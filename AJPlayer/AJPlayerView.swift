//
//  AJPlayerController.swift
//  AJPlayer
//
//  Created by DinDin on 2024/8/21.
//

import UIKit
import AVFoundation

open class AJPlayerView: UIView, Loggable {
    
    open var player = AVPlayer()
    open var playerLayerView = AJPlayerLayerView()
    private var waitForDurationValidBlock: (() -> ())?
    var rateObserver: NSKeyValueObservation?


    lazy var viewModel: AJPlayerViewModel = {
        let vm = AJPlayerViewModel()
        vm.delegate = self
        return vm
    }()
    
    open func setResources(_ resources: [AJPlayerResource]) {
        viewModel.setResources(resources)
    }
    
    open func configPlayerBy(_ resource: AJPlayerResource, at index: Int) {
        // Update state
        viewModel.changeState(to: .initial)
        // Reset Player Layer
        playerLayerView.playerLayer.player = nil
        // Reset ControlView
//        getCurrentControlView().resetControlView()
        let videoOutput = viewModel.videoOutput
        resource.playerItem.add(videoOutput)
        // reset duration's isValid state
        viewModel.durationIsValid = false
        waitForDurationValidBlock = nil
        viewModel.shouldSeekTo = 0
        player = AVPlayer(playerItem: resource.playerItem)
        // Reset Player Layer
        playerLayerView.playerLayer.player = player
        addToView()
        addObserversTo(resource.playerItem)
        // change resourece
        if let currentResourceItem = viewModel.currentResource?.playerItem {
            removeObserversFrom(currentResourceItem)
        }
        viewModel.currentResource = resource
        viewModel.currentResourceIndex = index
        
        play()
    }
    
    func addToView() {
        self.addSubview(playerLayerView)
        playerLayerView.frame = self.bounds
        playerLayerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    open func clearResource() {
        
        viewModel.clearResource()
        // Update state
        playerLayerView.playerLayer.player = nil
        // reset duration's isValid state
        waitForDurationValidBlock = nil
        // remove current observers
        if let currentResourceItem = viewModel.currentResource?.playerItem {
            removeObserversFrom(currentResourceItem)
        }
        player.replaceCurrentItem(with: nil)
    }
    

    
    open func updateStatus(includeLoading: Bool = false) {
        if includeLoading {
            guard let playerItem = player.currentItem else { return }
            if playerItem.isPlaybackLikelyToKeepUp || playerItem.isPlaybackBufferFull {
                viewModel.changeState(to: .bufferFinished)
            } else if playerItem.status == .failed {
                viewModel.changeState(to: .error(playerItem.error))
            } else {
                viewModel.changeState(to: .buffering)
            }
        }
        
        // value 0.0 pauses the video, while a value of 1.0 plays the current item at its natural rate.
        if player.rate == 0.0 {
            viewModel.isPlaying = false
            if let error = player.error {
                viewModel.changeState(to: .error(error)); return
            }
            guard let currentItem = player.currentItem else { viewModel.changeState(to: .empty); return }
            if player.currentTime() >= currentItem.duration {
                videoPlayDidEnd()
            }
        } else {
            viewModel.isPlaying = true
        }
    }
    
    open func play(with rate: Float? = nil) {
        if let rate = rate {
            viewModel.sppedRatio = rate
            player.playImmediately(atRate: rate)
            viewModel.changeState(to: .playing)
            viewModel.listenerMap.allObjects.forEach({ $0.playStateDidChangeTo(playing: true )})
        } else {
            player.play()
            viewModel.changeState(to: .playing)
            viewModel.listenerMap.allObjects.forEach({ $0.playStateDidChangeTo(playing: true )})
        }
    }
    
    open func play(with rate: Float?, startAtPercentDuration percent: Double) {
        play(with: rate)
        if viewModel.durationIsValid {
            guard let duration = player.currentItem?.duration else { return }
            let targetTime = floor(duration.seconds * percent)
            viewModel.state = .buffering
            seek(to: targetTime) { [weak self](isComplete) in
                guard let self = self else { return }
                if isComplete {
                    viewModel.state = .readyToPlay
                } else {
                    self.log(type: .debug, msg: "seek fail")
                }
            }
        } else {
            // create block and when duration valid will execute this block
            waitForDurationValidBlock = { [weak self] in
                guard let self = self  else { return }
                guard let duration = self.player.currentItem?.duration else { return }
                let targetTime = floor(duration.seconds * percent)
                viewModel.state = .buffering
                self.seek(to: targetTime, force: true) { [weak self](isComplete) in
                    guard let self = self else { return }
                    if isComplete {
                        viewModel.state = .readyToPlay
                    } else {
                        self.log(type: .debug, msg: "seek fail")
                    }
                }
            }
        }
    }
    
 
    
    
    
    open func seek(to seconds: TimeInterval, force: Bool = false, completion: ((Bool) -> Void)?) {
        if seconds.isNaN { completion?(false); return }
        if player.currentItem?.status == .readyToPlay || force {
            let targetTime = CMTimeMake(value: Int64(seconds), timescale: 1)
            player.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero) { (isFinished) in
                completion?(isFinished)
            }
        } else {
            viewModel.shouldSeekTo = seconds
            completion?(false)
        }
    }
}

extension AJPlayerView {
    
    private func addObserversTo(_ item: AVPlayerItem) {
        // NotificationCenter Observers
        let notiCenter = NotificationCenter.default
        notiCenter.addObserver(self,
                               selector: #selector(videoPlayDidEnd),
                               name: .AVPlayerItemDidPlayToEndTime,
                               object: item)
        notiCenter.addObserver(self,
                               selector: #selector(failedToPlayToEndTime(_:)),
                               name: .AVPlayerItemFailedToPlayToEndTime,
                               object: item)
        
        // KVO Observers
        // Player Status
        rateObserver = player.observe(
            \.rate,
            options: [.initial, .new, .old],
            changeHandler: { [weak self] (player, change) in
                self?.updateStatus()
            }
        )
        // AVPlayerItemStatusUnknown, AVPlayerItemStatusReadyToPlay, AVPlayerItemStatusFailed
        item.addObserver(self, forKeyPath: "status", options: [.new, .initial], context: nil)
        // 當前影片的進度緩衝
        item.addObserver(self, forKeyPath: "loadedTimeRanges", options: [.new, .initial], context: nil)
        // 緩衝區空的，需等待數據
        item.addObserver(self, forKeyPath: "playbackBufferEmpty", options: [.new, .initial], context: nil)
        // 緩衝區有足夠的數據能播放
        item.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: [.new, .initial], context: nil)
        
        item.addObserver(self, forKeyPath: "duration", options: [.new, .initial], context: nil)
    }
    
    private func removeObserversFrom(_ item: AVPlayerItem) {
        let notiCenter = NotificationCenter.default
        notiCenter.removeObserver(self,
                                  name: .AVPlayerItemDidPlayToEndTime,
                                  object: item)
        notiCenter.removeObserver(self,
                                  name: .AVPlayerItemFailedToPlayToEndTime,
                                  object: item)
        
        rateObserver?.invalidate()
        rateObserver = nil
        
        item.removeObserver(self, forKeyPath: "status")
        item.removeObserver(self, forKeyPath: "loadedTimeRanges")
        item.removeObserver(self, forKeyPath: "playbackBufferEmpty")
        item.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
        item.removeObserver(self, forKeyPath: "duration")
    }
    
    @objc private func videoPlayDidEnd() {
        viewModel.changeState(to: .playedToTheEnd)
    }
    
    @objc func failedToPlayToEndTime(_ notification: Notification) {
        if let error = notification.userInfo!["AVPlayerItemFailedToPlayToEndTimeErrorKey"] as? Error {
            viewModel.changeState(to: .error(error))
        }
    }
}

extension AJPlayerView {
    // MARK: - KVO and notification
    
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let keyPath = keyPath else { return }
        // Handle PlayerItem Status
        if
            let playerItem = object as? AVPlayerItem {
            switch keyPath {
            case "status":
                let newStatus: AVPlayerItem.Status
                if let newStatusAsNumber = change?[NSKeyValueChangeKey.newKey] as? NSNumber {
                    newStatus = AVPlayerItem.Status(rawValue: newStatusAsNumber.intValue)!
                } else {
                    newStatus = .unknown
                }
                switch newStatus {
                case .readyToPlay:
                    log(type: .debug, msg: "\(classForCoder.self) kvo state readyToPlay")
                    viewModel.changeState(to: .readyToPlay)
                case .failed:
                    log(type: .debug, msg: "\(classForCoder.self) kvo state fail")
                    viewModel.changeState(to: .error(playerItem.error))
                case .unknown:
                    log(type: .debug, msg: "\(classForCoder.self) kvo state unknown")
                @unknown default:
                    log(type: .debug, msg: "\(classForCoder.self) kvo state unknown case from new version")
                }
            case "loadedTimeRanges":
                // 計算緩衝進度
                if let timeInterval = availableDuration() {
                    let duration = playerItem.duration
                    let totalDuration = CMTimeGetSeconds(duration)
                    // TODO: - loadedTime changed
//                    getCurrentControlView().updateLoadedTime(timeInterval, totalDuration: totalDuration)
                }
            case "playbackBufferEmpty":
                // 緩衝為空的時候
                if playerItem.isPlaybackBufferEmpty {
                    viewModel.changeState(to: .buffering)
                }
            case "playbackLikelyToKeepUp":
                if playerItem.isPlaybackBufferEmpty && viewModel.state == .readyToPlay {
                    viewModel.changeState(to: .bufferFinished)
                }
            case "duration":
                if !playerItem.duration.isIndefinite && !viewModel.durationIsValid {
                    waitForDurationValidBlock?()
                    viewModel.durationIsValid = true
                }
            default: break
            }
        }
    }
    
    private func availableDuration() -> TimeInterval? {
        if
            let loadedTimeRanges = player.currentItem?.loadedTimeRanges,
            let first = loadedTimeRanges.first {
            let timeRange = first.timeRangeValue
            let startSeconds = CMTimeGetSeconds(timeRange.start)
            let durationSeconds = CMTimeGetSeconds(timeRange.duration)
            let result = startSeconds + durationSeconds
            return result
        } else {
            return nil
        }
    }
}


extension AJPlayerView: AJPlayerViewModelDelegate {
     func readyToSeek() {
         seek(to: viewModel.shouldSeekTo) { [weak self](isCompleted) in
            guard let self = self else { return }
            if isCompleted {
                viewModel.shouldSeekTo = 0
                viewModel.state = .readyToPlay
            } else {
                self.log(type: .debug, msg: "seek fail")
            }
        }
    }
    func updateStateAndVideoTime() {
        guard let playerItem = player.currentItem else { return }
        if playerItem.duration.timescale > 0 {
            let currentTime = CMTimeGetSeconds(player.currentTime())
            let totalTime = TimeInterval(playerItem.duration.value) / TimeInterval(playerItem.duration.timescale)
            // Notify time change
//            getCurrentControlView().updateCurrentTime(currentTime, total: totalTime)
        }
    }
}

//
//  AJPlayerPresnter.swift
//  AJPlayer
//
//  Created by DinDin on 2024/8/21.
//

import Foundation
import AVFoundation

@objc public protocol AJPlayerControllerListener: AnyObject {
    func playStateDidChangeTo(playing: Bool)
}

open class AJPlayerSetting {
    public var fastForwardSpeed: Float = 1.0
    public var voiceAdjustSpeed: Float = 1.0
    public var brightnessAdjustSpeed: Float = 1.0
}

protocol AJPlayerViewModelDelegate: AnyObject {
    func updateStateAndVideoTime()
    func configPlayerBy(_ resource: AJPlayerResource, at index: Int)
    func readyToSeek()
}

class AJPlayerViewModel: NSObject {
    open var durationIsValid: Bool = false
    open var isPlayingBeforeSeeking: Bool = false
    open var isAutoPlay: Bool = false
    open var currentResourceIndex: Int = 0
    open var currentResource: AJPlayerResource?
    open var resources: [AJPlayerResource] = []
    open var sppedRatio: Float = 1
    open var playerSetting: AJPlayerSetting = AJPlayerSetting()
    open weak var delegate: AJPlayerViewModelDelegate?
    open var isPlaying: Bool = false {
        didSet {
            if oldValue != isPlaying {
//                delegate?.playerController(self, isPlaying: isPlaying)
            }
        }
    }
    open var state: AJPlayerState = .empty

    open var shouldSeekTo: TimeInterval = 0
    
    let listenerMap: NSHashTable<AJPlayerControllerListener> = NSHashTable<AJPlayerControllerListener>.weakObjects()


    fileprivate weak var timer: Timer?

    open func setResources(_ resources: [AJPlayerResource]) {
        self.resources = resources
        if let firstItem = resources.first {
            delegate?.configPlayerBy(firstItem, at: 0)
        }
    }
    
    
    func changeState(to: AJPlayerState) {
        if state == to { return }
        switch (state, to) {
        case (_, .initial):
      
            state = to
        case (_, .playing):
           
            activeTimer()
            state = to
        case (_, .pause):
      
            stopTimer()
            state = to
        case (_, .buffering):
         
            state = to
        case (_, .bufferFinished):
            
            state = to
        case (_, .readyToPlay):
            
            if isAutoPlay {
                if shouldSeekTo > 0 {
                    state = .buffering
                    delegate?.readyToSeek()
                } else {
                    state = to
                }
            } else {
                state = to
            }
            
        case (_, .playedToTheEnd):
          
            timer?.invalidate()
            state = to
        case (_, .error(let error)):
            break
        default:
            state = to
        }
    }
    

    
    fileprivate func activeTimer() {
        if !(timer?.isValid ?? false) {
            timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { [weak self](_) in
                guard let self = self else { return }
                self.delegate?.updateStateAndVideoTime()
            })
        }
        timer?.fireDate = Date()
    }
    
    fileprivate func stopTimer() {
        timer?.invalidate()
    }
    
    open func clearResource() {
        // Update state
        changeState(to: .empty)
        // Reset Player Layer
        // reset duration's isValid state
        durationIsValid = false
        shouldSeekTo = 0
        // remove current observers
        currentResource = nil
        currentResourceIndex = 0
    }

}

//
//  AJPlayerState.swift
//  AJPlayer
//
//  Created by DinDin on 2024/8/21.
//

import Foundation

public enum AJPlayerState: Equatable {
    
    case empty
    case initial
    case playing
    case pause
    case readyToPlay
    case buffering
    case bufferFinished
    case playedToTheEnd
    case error(Error?)
    
    public static func ==(lhs: AJPlayerState, rhs: AJPlayerState) -> Bool {
        switch (lhs, rhs) {
        case (.empty, .empty):
            return true
        case (.initial, .initial):
            return true
        case (.playing, .playing):
            return true
        case (.pause, .pause):
            return true
        case (.readyToPlay, .readyToPlay):
            return true
        case (.buffering, .buffering):
            return true
        case (.bufferFinished, .bufferFinished):
            return true
        case (.playedToTheEnd, .playedToTheEnd):
            return true
        case (.error(_), .error(_)):
            return true
        default: return false
        }
    }
}

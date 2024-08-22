//
//  AJPlayerResource.swift
//  AJPlayer
//
//  Created by DinDin on 2024/8/21.
//

import Foundation
import AVFoundation

public class AJPlayerResource {
    
    public var resourceKey: String
    public var playerItem: AVPlayerItem
    
    convenience public init(_ url: URL) {
        let asset = AVURLAsset(url: url)
        self.init(asset)
    }
    
    convenience public init(_ asset: AVURLAsset) {
        let playerItem = AVPlayerItem(asset: asset)
        self.init(playerItem)
    }
    
    public init(_ item: AVPlayerItem) {
        self.resourceKey = (item.asset as! AVURLAsset).url.absoluteString
        self.playerItem = item
    }
}

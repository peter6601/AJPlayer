//
//  AJPlayerAsset.swift
//  AJPlayer
//
//  Created by DinDin on 2024/9/2.
//

import Foundation
import UIKit

public enum AJPlayerAsset: String {
    case play
    case pause
    case sliderThumb
    case fullScreen
    case endFullScreen
    case seek
    case playNext
    case replay
    case brightness
    case volume_on
    case volume_off
    case brightness_on
}

open class AJPImageResource {
    
    static public func get(_ asset: AJPlayerAsset) -> UIImage? {
        let frameworkBundle = Bundle(for: AJPImageResource.self)
        let bundleURL = frameworkBundle.resourceURL?.appendingPathComponent("AJPlayer.bundle")
        let resourceBundle = Bundle(url: bundleURL!)
        let image = UIImage(named: asset.rawValue, in: resourceBundle, compatibleWith: nil)
        return image?.withRenderingMode(.alwaysOriginal)
    }
}

//
//  AJPlayerUtility.swift
//  AJPlayer
//
//  Created by DinDin on 2024/9/2.
//

import Foundation
import UIKit

class MSSPlayerUtility {
    static func formatSecondsToString(_ seconds: TimeInterval) -> String {
        if seconds.isNaN {
            return "00:00"
        } else {
            let min = Int(floor(seconds) / 60)
            let sec = Int(floor(seconds).truncatingRemainder(dividingBy: 60))
            return String(format: "%02d:%02d", min, sec)
        }
    }
    
    static func getTextSizeBy(_ text: String, font: UIFont, superView: UIView) -> CGSize {
        let options: NSStringDrawingOptions = [.usesFontLeading, .usesLineFragmentOrigin]
        let attributes = [NSAttributedString.Key.font: font]
        let constrainedSize = CGSize(width: superView.bounds.width - 40,
                                     height: CGFloat.greatestFiniteMagnitude)
        var bounds = (text as NSString).boundingRect(with: constrainedSize,
                                                     options: options,
                                                     attributes: attributes,
                                                     context: nil)
        bounds.size = CGSize(width: bounds.width, height: bounds.height + 20)
        return bounds.size
    }
}

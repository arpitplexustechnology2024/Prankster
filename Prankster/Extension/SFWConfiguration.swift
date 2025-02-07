//
//  File.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 30/11/24.
//

import Foundation
import UIKit
import SwiftFortuneWheel

// MARK: - Configuration Extension
private let blackColor = UIColor(white: 51.0 / 255.0, alpha: 1.0)
private let borderColor = UIColor(hex: "35417C")  // નવો બૉર્ડર કલર
private let circleStrokeWidth: CGFloat = 3  // બૉર્ડરની જાડાઈ
private let _position: SFWConfiguration.Position = .top

extension UIColor {
    static let gradientPairs: [(start: String, end: String)] = [
        ("30BEFF", "30BEFF"), // Blue gradient
        ("FF7BCA", "FF7BCA"), // Pink gradient
        ("54CE0D", "54CE0D"), // Orange gradient
        ("CD14CE", "CD14CE"), // Green gradient
    ]
    
    convenience init(hex: String) {
        // જો hex string ખાલી હોય તો clear color રીટર્ન કરો
        if hex.isEmpty {
            self.init(white: 0, alpha: 0)  // Clear color
            return
        }
        
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
    
    static func getGradientColors(size: CGSize) -> [UIColor] {
        return gradientPairs.compactMap { pair in
            if pair.start.isEmpty || pair.end.isEmpty {
                return .clear
            }
            let startColor = UIColor(hex: pair.start)
            let endColor = UIColor(hex: pair.end)
            return gradientColor(from: startColor, to: endColor, size: size)
        }
    }
}

extension SFWConfiguration {
    static func gradientColorsConfiguration(wheelSize: CGSize) -> SFWConfiguration {
        let spin = SFWConfiguration.SpinButtonPreferences(size: CGSize(width: 80, height: 80))
        
        let gradientColors = UIColor.getGradientColors(size: wheelSize)
        let sliceColorType = SFWConfiguration.ColorType.customPatternColors(colors: gradientColors, defaultColor: .clear)
        
        // સ્લાઇસ વચ્ચેની લાઇન (બૉર્ડર) સેટ કરવી
        let slicePreferences = SFWConfiguration.SlicePreferences(
            backgroundColorType: sliceColorType,
            strokeWidth: 3,  // સ્લાઇસ વચ્ચેની લાઇનની જાડાઈ
            strokeColor: borderColor  // સ્લાઇસ વચ્ચેની લાઇનનો કલર
        )
        
        let anchorImage = SFWConfiguration.AnchorImage(imageName: "anchorImage", size: CGSize(width: 8, height: 8), verticalOffset: -10)
        
        // બહારની રિંગ (સર્કલ) માટેની પ્રેફરન્સ
        let circlePreferences = SFWConfiguration.CirclePreferences(
            strokeWidth: circleStrokeWidth,  // બહારની રિંગની જાડાઈ
            strokeColor: borderColor  // બહારની રિંગનો કલર
        )
        
        var wheelPreferences = SFWConfiguration.WheelPreferences(
            circlePreferences: circlePreferences,
            slicePreferences: slicePreferences,
            startPosition: .top
        )
        
        wheelPreferences.imageAnchor = anchorImage
        
        let configuration = SFWConfiguration(wheelPreferences: wheelPreferences, spinButtonPreferences: spin)
        
        return configuration
    }
}

// MARK: - Preferences Extensions
extension ImagePreferences {
    static var prizeImagePreferences: ImagePreferences {
        let preferences = ImagePreferences(preferredSize: CGSize(width: 65, height: 65),
                                       verticalOffset: 15)
        return preferences
    }
}

extension UIColor {
    static func gradientColor(from color1: UIColor, to color2: UIColor, size: CGSize) -> UIColor? {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(origin: .zero, size: size)
        gradientLayer.colors = [color1.cgColor, color2.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        
        UIGraphicsBeginImageContextWithOptions(gradientLayer.frame.size, false, 0.0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        gradientLayer.render(in: context)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image.map { UIColor(patternImage: $0) }
    }
}

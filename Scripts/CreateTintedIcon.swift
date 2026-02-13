import Foundation
import AppKit

func createTintedIcon() {
    let fileManager = FileManager.default
    // Paths
    let currentDirectory = fileManager.currentDirectoryPath
    let sourcePath = currentDirectory + "/BikeComputer/Assets.xcassets/AppIcon.appiconset/bike_icon.png"
    let destinationPath = currentDirectory + "/BikeComputer/Assets.xcassets/AppIcon.appiconset/bike_icon_tinted.png"

    guard let image = NSImage(contentsOfFile: sourcePath) else {
        print("Error: Could not load source image at \(sourcePath)")
        exit(1)
    }

    guard let tiffData = image.tiffRepresentation,
          let bitmapRep = NSBitmapImageRep(data: tiffData) else {
        print("Error: Could not create bitmap representation")
        exit(1)
    }

    let width = bitmapRep.pixelsWide
    let height = bitmapRep.pixelsHigh
    
    // Create output bitmap
    guard let outputRep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: width,
        pixelsHigh: height,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        print("Error: Could not create output bitmap")
        exit(1)
    }

    // Process pixels
    // We assume the source is Black background with Red foreground.
    // We want conversion: Alpha = Source.Red, Color = White.
    
    for y in 0..<height {
        for x in 0..<width {
            var red: CGFloat = 0
            // Get pixel color (normalized 0-1)
            // Note: getPixel returns components in reference to color space, but simpler is to use colorAt
            if let color = bitmapRep.colorAt(x: x, y: y) {
                 // Use the maximum of RGB as the alpha, or specifically Red if it's red-on-black.
                 // Since the icon is "Neon Red", Red component is high, others are low.
                 // Let's use the Red component as the Alpha for the new white icon.
                 // This preserves antialiasing.
                 red = color.redComponent
                 
                 // If the background is not perfectly black, we might want to threshold?
                 // But "matte black" usually means (0,0,0) or close.
                 // Let's assume standard behavior: R -> A.
                 
                 let alpha = red
                 let newColor = NSColor(deviceRed: 1.0, green: 1.0, blue: 1.0, alpha: alpha)
                 outputRep.setColor(newColor, atX: x, y: y)
            }
        }
    }

    // Save result
    guard let pngData = outputRep.representation(using: .png, properties: [:]) else {
        print("Error: Could not convert to PNG data")
        exit(1)
    }

    do {
        try pngData.write(to: URL(fileURLWithPath: destinationPath))
        print("Success: Created tinted icon at \(destinationPath)")
    } catch {
        print("Error: Failed to write file: \(error)")
        exit(1)
    }
}

createTintedIcon()

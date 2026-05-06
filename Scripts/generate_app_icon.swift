import AppKit
import Foundation

struct Palette {
    let backgroundTop: NSColor
    let backgroundBottom: NSColor
    let accent: NSColor
    let accentSoft: NSColor
    let card: NSColor
    let line: NSColor
    let shadow: NSColor
}

let outputDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("Planner/Assets.xcassets/AppIcon.appiconset", isDirectory: true)

let warmPalette = Palette(
    backgroundTop: NSColor(calibratedRed: 1.00, green: 0.56, blue: 0.36, alpha: 1),
    backgroundBottom: NSColor(calibratedRed: 0.98, green: 0.73, blue: 0.25, alpha: 1),
    accent: NSColor(calibratedRed: 0.16, green: 0.40, blue: 0.95, alpha: 1),
    accentSoft: NSColor(calibratedRed: 0.43, green: 0.61, blue: 1.00, alpha: 1),
    card: NSColor(calibratedRed: 0.99, green: 0.98, blue: 0.96, alpha: 1),
    line: NSColor(calibratedRed: 0.16, green: 0.22, blue: 0.34, alpha: 0.9),
    shadow: NSColor(calibratedWhite: 0, alpha: 0.18)
)

let darkPalette = Palette(
    backgroundTop: NSColor(calibratedRed: 0.13, green: 0.19, blue: 0.30, alpha: 1),
    backgroundBottom: NSColor(calibratedRed: 0.23, green: 0.30, blue: 0.46, alpha: 1),
    accent: NSColor(calibratedRed: 1.00, green: 0.58, blue: 0.32, alpha: 1),
    accentSoft: NSColor(calibratedRed: 1.00, green: 0.77, blue: 0.42, alpha: 1),
    card: NSColor(calibratedRed: 0.96, green: 0.96, blue: 0.98, alpha: 1),
    line: NSColor(calibratedRed: 0.19, green: 0.23, blue: 0.31, alpha: 0.92),
    shadow: NSColor(calibratedWhite: 0, alpha: 0.28)
)

let tintedPalette = Palette(
    backgroundTop: NSColor(calibratedWhite: 0.92, alpha: 1),
    backgroundBottom: NSColor(calibratedWhite: 0.84, alpha: 1),
    accent: NSColor(calibratedRed: 0.12, green: 0.18, blue: 0.27, alpha: 1),
    accentSoft: NSColor(calibratedRed: 0.30, green: 0.36, blue: 0.45, alpha: 1),
    card: NSColor(calibratedWhite: 0.98, alpha: 1),
    line: NSColor(calibratedRed: 0.12, green: 0.18, blue: 0.27, alpha: 0.88),
    shadow: NSColor(calibratedWhite: 0, alpha: 0.12)
)

func roundedRect(_ rect: CGRect, radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

func fill(_ path: NSBezierPath, color: NSColor) {
    color.setFill()
    path.fill()
}

func stroke(_ path: NSBezierPath, color: NSColor, width: CGFloat) {
    color.setStroke()
    path.lineWidth = width
    path.stroke()
}

func drawCheckmark(in rect: CGRect, color: NSColor, lineWidth: CGFloat) {
    let path = NSBezierPath()
    path.move(to: CGPoint(x: rect.minX + rect.width * 0.12, y: rect.midY))
    path.line(to: CGPoint(x: rect.minX + rect.width * 0.38, y: rect.minY + rect.height * 0.22))
    path.line(to: CGPoint(x: rect.maxX - rect.width * 0.10, y: rect.maxY - rect.height * 0.16))
    path.lineCapStyle = .round
    path.lineJoinStyle = .round
    stroke(path, color: color, width: lineWidth)
}

func drawPlannerIcon(size: CGFloat, palette: Palette) -> NSImage {
    let canvasSize = NSSize(width: size, height: size)
    let image = NSImage(size: canvasSize)
    image.lockFocus()

    guard let context = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    context.setAllowsAntialiasing(true)
    context.setShouldAntialias(true)
    context.interpolationQuality = .high

    let fullRect = CGRect(origin: .zero, size: canvasSize)
    let radius = size * 0.23
    let backgroundPath = roundedRect(fullRect, radius: radius)
    backgroundPath.addClip()

    let gradient = NSGradient(colors: [palette.backgroundTop, palette.backgroundBottom])!
    gradient.draw(in: backgroundPath, angle: -55)

    let glowPath = NSBezierPath()
    glowPath.move(to: CGPoint(x: size * 0.60, y: size))
    glowPath.curve(
        to: CGPoint(x: size, y: size * 0.55),
        controlPoint1: CGPoint(x: size * 0.86, y: size * 0.98),
        controlPoint2: CGPoint(x: size * 0.98, y: size * 0.82)
    )
    glowPath.line(to: CGPoint(x: size, y: size))
    glowPath.close()
    fill(glowPath, color: NSColor.white.withAlphaComponent(0.16))

    let dotRadius = size * 0.05
    let dot1 = roundedRect(CGRect(x: size * 0.18, y: size * 0.80, width: dotRadius, height: dotRadius), radius: dotRadius / 2)
    let dot2 = roundedRect(CGRect(x: size * 0.29, y: size * 0.80, width: dotRadius, height: dotRadius), radius: dotRadius / 2)
    fill(dot1, color: NSColor.white.withAlphaComponent(0.30))
    fill(dot2, color: NSColor.white.withAlphaComponent(0.20))

    let cardRect = CGRect(x: size * 0.17, y: size * 0.16, width: size * 0.66, height: size * 0.66)
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -size * 0.03), blur: size * 0.07, color: palette.shadow.cgColor)
    fill(roundedRect(cardRect, radius: size * 0.15), color: palette.card)
    context.restoreGState()

    let headerRect = CGRect(x: cardRect.minX, y: cardRect.maxY - size * 0.17, width: cardRect.width, height: size * 0.17)
    let headerPath = roundedRect(headerRect, radius: size * 0.12)
    fill(headerPath, color: palette.accent)

    let tabWidth = size * 0.07
    let tabHeight = size * 0.05
    let tabY = cardRect.maxY - size * 0.035
    for originX in [cardRect.minX + size * 0.11, cardRect.minX + size * 0.30, cardRect.minX + size * 0.49] {
        fill(
            roundedRect(CGRect(x: originX, y: tabY, width: tabWidth, height: tabHeight), radius: tabHeight / 2),
            color: NSColor.white.withAlphaComponent(0.88)
        )
    }

    let rowHeight = size * 0.12
    let rows: [CGFloat] = [size * 0.54, size * 0.40, size * 0.26]
    for (index, y) in rows.enumerated() {
        let bulletRect = CGRect(x: cardRect.minX + size * 0.08, y: y, width: size * 0.09, height: rowHeight * 0.72)
        if index == 1 {
            drawCheckmark(in: bulletRect, color: palette.accent, lineWidth: size * 0.024)
        } else {
            fill(roundedRect(bulletRect, radius: size * 0.035), color: index == 0 ? palette.accentSoft : palette.accent.withAlphaComponent(0.85))
        }

        let lineRect = CGRect(x: cardRect.minX + size * 0.23, y: y + rowHeight * 0.10, width: size * 0.33, height: rowHeight * 0.18)
        let linePath = roundedRect(lineRect, radius: lineRect.height / 2)
        fill(linePath, color: palette.line.withAlphaComponent(index == 1 ? 0.92 : 0.72))

        let shortLineRect = CGRect(x: cardRect.minX + size * 0.23, y: y - rowHeight * 0.13, width: size * (index == 2 ? 0.20 : 0.26), height: rowHeight * 0.14)
        fill(roundedRect(shortLineRect, radius: shortLineRect.height / 2), color: palette.line.withAlphaComponent(0.28))
    }

    let cornerBadgeRect = CGRect(x: size * 0.64, y: size * 0.19, width: size * 0.12, height: size * 0.12)
    fill(roundedRect(cornerBadgeRect, radius: size * 0.04), color: palette.accentSoft)
    drawCheckmark(in: cornerBadgeRect.insetBy(dx: size * 0.02, dy: size * 0.02), color: NSColor.white, lineWidth: size * 0.018)

    image.unlockFocus()
    return image
}

func writePNG(_ image: NSImage, to url: URL) throws {
    guard
        let tiffData = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiffData),
        let pngData = bitmap.representation(using: .png, properties: [:])
    else {
        throw NSError(domain: "AppIconGenerator", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create PNG data."])
    }

    try pngData.write(to: url, options: .atomic)
}

let outputs: [(String, CGFloat, Palette)] = [
    ("icon-ios-1024.png", 1024, warmPalette),
    ("icon-ios-dark-1024.png", 1024, darkPalette),
    ("icon-ios-tinted-1024.png", 1024, tintedPalette),
    ("icon-mac-16.png", 16, warmPalette),
    ("icon-mac-32.png", 32, warmPalette),
    ("icon-mac-32@2x.png", 64, warmPalette),
    ("icon-mac-128.png", 128, warmPalette),
    ("icon-mac-128@2x.png", 256, warmPalette),
    ("icon-mac-256.png", 256, warmPalette),
    ("icon-mac-256@2x.png", 512, warmPalette),
    ("icon-mac-512.png", 512, warmPalette),
    ("icon-mac-512@2x.png", 1024, warmPalette)
]

for (name, renderSize, palette) in outputs {
    let url = outputDirectory.appendingPathComponent(name)
    let image = drawPlannerIcon(size: renderSize, palette: palette)
    try writePNG(image, to: url)
    print("Wrote \(name)")
}

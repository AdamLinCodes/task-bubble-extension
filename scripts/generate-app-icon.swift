import AppKit
import Foundation

private let canvasSize = NSSize(width: 1024, height: 1024)

private func scaledRect(_ rect: NSRect, by scale: CGFloat) -> NSRect {
  NSRect(
    x: rect.origin.x * scale,
    y: rect.origin.y * scale,
    width: rect.width * scale,
    height: rect.height * scale
  )
}

private func applePath(in rect: NSRect) -> NSBezierPath {
  let path = NSBezierPath()
  let w = rect.width
  let h = rect.height
  let x = rect.minX
  let y = rect.minY

  func point(_ horizontal: CGFloat, _ vertical: CGFloat) -> NSPoint {
    NSPoint(x: x + w * horizontal, y: y + h * (1 - vertical))
  }

  path.move(to: point(0.50, 0.20))
  path.curve(
    to: point(0.12, 0.39),
    controlPoint1: point(0.36, 0.08),
    controlPoint2: point(0.14, 0.16)
  )
  path.curve(
    to: point(0.32, 0.94),
    controlPoint1: point(0.03, 0.62),
    controlPoint2: point(0.15, 0.91)
  )
  path.curve(
    to: point(0.50, 0.88),
    controlPoint1: point(0.41, 0.98),
    controlPoint2: point(0.45, 0.88)
  )
  path.curve(
    to: point(0.68, 0.94),
    controlPoint1: point(0.55, 0.88),
    controlPoint2: point(0.59, 0.98)
  )
  path.curve(
    to: point(0.88, 0.39),
    controlPoint1: point(0.85, 0.91),
    controlPoint2: point(0.97, 0.62)
  )
  path.curve(
    to: point(0.50, 0.20),
    controlPoint1: point(0.86, 0.16),
    controlPoint2: point(0.64, 0.08)
  )
  path.close()
  return path
}

private func drawIcon(scale: CGFloat) {
  let backgroundRect = scaledRect(NSRect(x: 72, y: 72, width: 880, height: 880), by: scale)
  let background = NSBezierPath(
    roundedRect: backgroundRect,
    xRadius: 210 * scale,
    yRadius: 210 * scale
  )

  let backgroundShadow = NSShadow()
  backgroundShadow.shadowColor = NSColor.black.withAlphaComponent(0.20)
  backgroundShadow.shadowBlurRadius = 38 * scale
  backgroundShadow.shadowOffset = NSSize(width: 0, height: -18 * scale)
  backgroundShadow.set()

  NSGradient(
    starting: NSColor(calibratedRed: 1.00, green: 0.99, blue: 0.96, alpha: 1),
    ending: NSColor(calibratedRed: 0.91, green: 0.93, blue: 0.88, alpha: 1)
  )?.draw(in: background, angle: -90)

  NSGraphicsContext.saveGraphicsState()
  NSShadow().set()

  let appleRect = scaledRect(NSRect(x: 218, y: 205, width: 588, height: 590), by: scale)
  let apple = applePath(in: appleRect)
  let appleShadow = NSShadow()
  appleShadow.shadowColor = NSColor.black.withAlphaComponent(0.28)
  appleShadow.shadowBlurRadius = 34 * scale
  appleShadow.shadowOffset = NSSize(width: 0, height: -22 * scale)
  appleShadow.set()

  NSGradient(
    starting: NSColor(calibratedRed: 1.00, green: 0.25, blue: 0.20, alpha: 1),
    ending: NSColor(calibratedRed: 0.70, green: 0.02, blue: 0.05, alpha: 1)
  )?.draw(in: apple, angle: -58)
  NSGraphicsContext.restoreGraphicsState()

  NSGraphicsContext.saveGraphicsState()
  let stemTransform = NSAffineTransform()
  stemTransform.translateX(by: 521 * scale, yBy: 778 * scale)
  stemTransform.rotate(byDegrees: -10)
  stemTransform.concat()
  let stem = NSBezierPath(
    roundedRect: NSRect(x: -12 * scale, y: -4 * scale, width: 24 * scale, height: 105 * scale),
    xRadius: 12 * scale,
    yRadius: 12 * scale
  )
  NSColor(calibratedRed: 0.32, green: 0.16, blue: 0.08, alpha: 1).setFill()
  stem.fill()
  NSGraphicsContext.restoreGraphicsState()

  NSGraphicsContext.saveGraphicsState()
  let leafTransform = NSAffineTransform()
  leafTransform.translateX(by: 604 * scale, yBy: 810 * scale)
  leafTransform.rotate(byDegrees: 28)
  leafTransform.concat()
  let leaf = NSBezierPath(
    ovalIn: NSRect(x: -83 * scale, y: -30 * scale, width: 166 * scale, height: 60 * scale))
  NSGradient(
    starting: NSColor(calibratedRed: 0.35, green: 0.72, blue: 0.24, alpha: 1),
    ending: NSColor(calibratedRed: 0.12, green: 0.42, blue: 0.12, alpha: 1)
  )?.draw(in: leaf, angle: -30)
  NSGraphicsContext.restoreGraphicsState()

  let shine = NSBezierPath()
  shine.move(to: NSPoint(x: 358 * scale, y: 651 * scale))
  shine.curve(
    to: NSPoint(x: 315 * scale, y: 493 * scale),
    controlPoint1: NSPoint(x: 314 * scale, y: 620 * scale),
    controlPoint2: NSPoint(x: 294 * scale, y: 551 * scale)
  )
  shine.lineWidth = 23 * scale
  shine.lineCapStyle = .round
  NSColor.white.withAlphaComponent(0.24).setStroke()
  shine.stroke()
}

private func writeIcon(pixelSize: Int, to url: URL) throws {
  guard
    let representation = NSBitmapImageRep(
      bitmapDataPlanes: nil,
      pixelsWide: pixelSize,
      pixelsHigh: pixelSize,
      bitsPerSample: 8,
      samplesPerPixel: 4,
      hasAlpha: true,
      isPlanar: false,
      colorSpaceName: .deviceRGB,
      bytesPerRow: 0,
      bitsPerPixel: 0
    )
  else {
    throw CocoaError(.fileWriteUnknown)
  }

  representation.size = canvasSize
  guard let context = NSGraphicsContext(bitmapImageRep: representation) else {
    throw CocoaError(.fileWriteUnknown)
  }

  NSGraphicsContext.saveGraphicsState()
  NSGraphicsContext.current = context
  context.cgContext.clear(CGRect(origin: .zero, size: canvasSize))
  context.cgContext.setShouldAntialias(true)
  context.cgContext.setAllowsAntialiasing(true)
  drawIcon(scale: 1)
  NSGraphicsContext.restoreGraphicsState()

  guard let data = representation.representation(using: .png, properties: [:]) else {
    throw CocoaError(.fileWriteUnknown)
  }
  try data.write(to: url, options: .atomic)
}

guard CommandLine.arguments.count == 2 else {
  fputs("Usage: swift generate-app-icon.swift OUTPUT_ICONSET_DIRECTORY\n", stderr)
  exit(2)
}

let outputDirectory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

let icons: [(pixels: Int, filename: String)] = [
  (16, "icon_16x16.png"),
  (32, "icon_16x16@2x.png"),
  (32, "icon_32x32.png"),
  (64, "icon_32x32@2x.png"),
  (128, "icon_128x128.png"),
  (256, "icon_128x128@2x.png"),
  (256, "icon_256x256.png"),
  (512, "icon_256x256@2x.png"),
  (512, "icon_512x512.png"),
  (1024, "icon_512x512@2x.png"),
]

for icon in icons {
  try writeIcon(pixelSize: icon.pixels, to: outputDirectory.appendingPathComponent(icon.filename))
}

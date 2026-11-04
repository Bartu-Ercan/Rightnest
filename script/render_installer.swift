import AppKit

// Static Finder background; no window creation or application activation.
let size = NSSize(width: 800, height: 500)
let background = NSColor(srgbRed: 0.969, green: 0.976, blue: 0.988, alpha: 1)
let tile = NSColor(srgbRed: 0.933, green: 0.949, blue: 0.973, alpha: 1)
let ink = NSColor(srgbRed: 0.086, green: 0.086, blue: 0.086, alpha: 1)
let secondary = NSColor(srgbRed: 0.325, green: 0.384, blue: 0.478, alpha: 1)
let blue = NSColor(srgbRed: 0.141, green: 0.373, blue: 0.800, alpha: 1)
let rule = NSColor(srgbRed: 0.839, green: 0.871, blue: 0.922, alpha: 1)
let image = NSImage(size: size)
for scale in [1, 2] {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 800*scale, pixelsHigh: 500*scale,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = size
    NSGraphicsContext.saveGraphicsState()
    let bitmapContext = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = NSGraphicsContext(cgContext: bitmapContext.cgContext, flipped: true)
    // Use top-left coordinates to match Finder's icon locations.
    let flip = NSAffineTransform(); flip.translateX(by: 0, yBy: size.height); flip.scaleX(by: 1, yBy: -1); flip.concat()
    background.setFill(); NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()
    func text(_ value: String, x: CGFloat, y: CGFloat, width: CGFloat, font: NSFont, color: NSColor, centered: Bool = false) {
        let paragraph = NSMutableParagraphStyle(); paragraph.alignment = centered ? .center : .left
        (value as NSString).draw(in: NSRect(x: x, y: y, width: width, height: 55),
            withAttributes: [.font: font, .foregroundColor: color, .paragraphStyle: paragraph])
    }
    text("Rightnest", x: 48, y: 35, width: 520, font: .systemFont(ofSize: 34, weight: .semibold), color: ink)
    text("A familiar corner. On your right.", x: 49, y: 83, width: 600, font: .systemFont(ofSize: 15), color: secondary)
    let corner = NSBezierPath(); corner.move(to: NSPoint(x: 706, y: 44)); corner.line(to: NSPoint(x: 752, y: 44)); corner.line(to: NSPoint(x: 752, y: 90)); corner.lineWidth = 4; corner.lineCapStyle = .round; blue.setStroke(); corner.stroke()
    rule.setFill(); NSRect(x: 48, y: 125, width: 704, height: 1).fill()
    text("Drag Rightnest into Applications", x: 48, y: 151, width: 704, font: .systemFont(ofSize: 18, weight: .medium), color: ink, centered: true)
    tile.setFill()
    for x in [122.0, 502.0] {
        NSBezierPath(roundedRect: NSRect(x: x, y: 208, width: 176, height: 152), xRadius: 26, yRadius: 26).fill()
    }
    let arrow = NSBezierPath(); arrow.move(to: NSPoint(x: 365, y: 274)); arrow.line(to: NSPoint(x: 435, y: 274)); arrow.move(to: NSPoint(x: 422, y: 261)); arrow.line(to: NSPoint(x: 435, y: 274)); arrow.line(to: NSPoint(x: 422, y: 287)); arrow.lineWidth = 3; arrow.lineCapStyle = .round; arrow.lineJoinStyle = .round; blue.setStroke(); arrow.stroke()
    rule.setFill(); NSRect(x: 48, y: 403, width: 704, height: 1).fill()
    text("Then open Rightnest from Applications.", x: 48, y: 424, width: 704, font: .systemFont(ofSize: 14, weight: .medium), color: ink, centered: true)
    text("Set up Window Control permission when the app asks.", x: 48, y: 450, width: 704, font: .systemFont(ofSize: 12), color: secondary, centered: true)
    NSGraphicsContext.restoreGraphicsState()
    let arrowPixel = rep.colorAt(x: 400*scale, y: 274*scale)!.usingColorSpace(.deviceRGB)!
    precondition(abs(arrowPixel.blueComponent-0.800) < 0.1 && arrowPixel.redComponent < 0.25,
        "1x and2x must draw the arrow at the same logical position")
    image.addRepresentation(rep)
}
let output = CommandLine.arguments.dropFirst().first ?? "Assets/installer-background.tiff"
// Finder needs the 1x TIFF directory first; NSImage writes the largest first.
let temporary = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("rightnest-art-"+UUID().uuidString)
try FileManager.default.createDirectory(at: temporary, withIntermediateDirectories: true)
defer { try? FileManager.default.removeItem(at: temporary) }
var parts: [String] = []
for (index, rep) in image.representations.sorted(by: { $0.pixelsWide < $1.pixelsWide }).enumerated() {
    let path = temporary.appendingPathComponent("\(index).tiff")
    try (rep as! NSBitmapImageRep).tiffRepresentation!.write(to: path)
    // Individual bitmap TIFF export loses logical DPI; restore it before grouping.
    let dpi = String(rep.pixelsWide*72/800)
    let metadata = Process(); metadata.executableURL = URL(fileURLWithPath: "/usr/bin/sips")
    metadata.arguments = ["-s", "dpiWidth", dpi, "-s", "dpiHeight", dpi, path.path]
    try metadata.run(); metadata.waitUntilExit()
    guard metadata.terminationStatus == 0 else { throw NSError(domain: "RightnestInstallerDPI", code: 1) }
    let compressed = temporary.appendingPathComponent(index == 0 ? "background.tiff" : "background@2x.tiff")
    try tiffutil(["-lzw", path.path, "-out", compressed.path])
    parts.append(compressed.path)
}
func tiffutil(_ arguments: [String]) throws {
    let process = Process(); process.executableURL = URL(fileURLWithPath: "/usr/bin/tiffutil"); process.arguments = arguments
    try process.run(); process.waitUntilExit()
    guard process.terminationStatus == 0 else { throw NSError(domain: "RightnestInstallerArtwork", code: Int(process.terminationStatus)) }
}
// cathidpicheck derives the scale from the @2x filename. Compress each part
// first; rewriting a multi-directory TIFF can lose the per-directory DPI.
try tiffutil(["-cathidpicheck"]+parts+["-out", output])
let decoded = NSImage(contentsOfFile: output)!
precondition(decoded.representations.count == 2 && decoded.representations.allSatisfy { $0.size == size }, "Retina background must keep an 800×500 point canvas at both resolutions")
// The 1x PNG is also used as an accessible documentation illustration.
let png = (image.representations.first! as! NSBitmapImageRep).representation(using: .png, properties: [:])!
try png.write(to: URL(fileURLWithPath: output).deletingPathExtension().appendingPathExtension("png"))

// Documentation illustration using the exact background and system folder icon.
let preview = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 800, pixelsHigh: 500,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
let context = NSGraphicsContext(bitmapImageRep: preview)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(cgContext: context.cgContext, flipped: true)
let top = NSAffineTransform(); top.translateX(by: 0, yBy: 500); top.scaleX(by: 1, yBy: -1); top.concat()
image.draw(in: NSRect(origin: .zero, size: size), from: .zero, operation: .copy, fraction: 1, respectFlipped: true, hints: nil)
let appIcon = NSImage(contentsOfFile: "Assets/app-icon.png")!
let folderIcon = NSWorkspace.shared.icon(forFile: "/Applications")
for (x, icon, label) in [(210.0, appIcon, "Rightnest"), (590.0, folderIcon, "Applications")] {
    icon.draw(in: NSRect(x: x-56, y: 218, width: 112, height: 112), from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
    let paragraph = NSMutableParagraphStyle(); paragraph.alignment = .center
    (label as NSString).draw(in: NSRect(x: x-88, y: 335, width: 176, height: 24),
        withAttributes: [.font: NSFont.systemFont(ofSize: 14), .foregroundColor: ink, .paragraphStyle: paragraph])
}
NSGraphicsContext.restoreGraphicsState()
try preview.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "Assets/installer-preview.png"))

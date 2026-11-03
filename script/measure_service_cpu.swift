import AppKit
import CoreGraphics
import Foundation

// Read-only, finite monitor. It neither activates apps nor dispatches AX actions.
// Run against an already installed release and a prepared foreground static fixture.
struct MeasurementFailure: Error { let message: String }
let args = CommandLine.arguments
guard args.count == 4, let pid = Int32(args[1]), pid > 0 else {
    fputs("Usage: ServiceCPU <pid> <expected-bundle-id> <report-directory>\n", stderr)
    exit(2)
}
let expected = args[2]
let directory = URL(fileURLWithPath: args[3], isDirectory: true)
try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
var report: [String: Any] = ["application": expected, "servicePID": pid,
    "os": ProcessInfo.processInfo.operatingSystemVersionString,
    "method": "External ps cumulative CPU; 30s warmup, five 60s windows; read-only foreground/panel checks"]
@MainActor func write(_ name: String) throws {
    let data = try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
    try data.write(to: directory.appendingPathComponent(name), options: .atomic)
}
func sample() throws -> (cpu: Double, rss: Int) {
    let process = Process(), output = Pipe()
    process.executableURL = URL(fileURLWithPath: "/bin/ps")
    process.arguments = ["-p", String(pid), "-o", "time=,rss="]
    process.standardOutput = output
    try process.run(); process.waitUntilExit()
    let raw = String(data: output.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    let fields = raw.split(whereSeparator: { $0.isWhitespace })
    guard process.terminationStatus == 0, fields.count == 2, let rss = Int(fields[1]) else { throw MeasurementFailure(message: "Service process ended") }
    var cpu = 0.0
    for field in fields[0].split(separator: ":") {
        guard let value = Double(field) else { throw MeasurementFailure(message: "Unrecognized cumulative CPU time") }
        cpu = cpu*60+value
    }
    return (cpu, rss)
}
func verify() throws {
    guard NSWorkspace.shared.frontmostApplication?.bundleIdentifier == expected else { throw MeasurementFailure(message: "Foreground changed; discard this run") }
    guard let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]],
          windows.contains(where: { window in
              guard window[kCGWindowOwnerPID as String] as? Int32 == pid,
                    (window[kCGWindowAlpha as String] as? Double ?? 0) > 0,
                    let bounds = window[kCGWindowBounds as String] as? NSDictionary,
                    let rect = CGRect(dictionaryRepresentation: bounds) else { return false }
              return abs(rect.height-26) <= 1 && (abs(rect.width-102) <= 1 || abs(rect.width-66) <= 1)
          }) else { throw MeasurementFailure(message: "Control panel not visible; discard this run") }
}
func waitSeconds(_ count: Int) throws {
    for _ in 0..<count { RunLoop.current.run(until: Date().addingTimeInterval(1)); try verify() }
}
do {
    try verify(); report["phase"] = "warmup"; try write("progress.json")
    try waitSeconds(30)
    var percentages: [Double] = [], memory: [Int] = []
    for _ in 0..<5 {
        let start = ProcessInfo.processInfo.systemUptime, before = try sample()
        try waitSeconds(60)
        let after = try sample()
        guard after.cpu >= before.cpu else { throw MeasurementFailure(message: "Process CPU counter reset") }
        percentages.append(100*(after.cpu-before.cpu)/(ProcessInfo.processInfo.systemUptime-start))
        memory.append(after.rss)
        report["phase"] = "idle"; report["windowCPUPercent"] = percentages; report["rssKiB"] = memory
        report["meanCPUPercent"] = percentages.reduce(0,+)/Double(percentages.count)
        try write("progress.json")
    }
    report["result"] = percentages.reduce(0,+)/Double(percentages.count) < 1 ? "passed" : "failed CPU target"
} catch {
    report["result"] = "failed"
    report["error"] = (error as? MeasurementFailure)?.message ?? String(describing: error)
}
try write("result.json")
print(String(data: try JSONSerialization.data(withJSONObject: report, options: [.sortedKeys]), encoding: .utf8) ?? "")

if report["result"] as? String != "passed" { exit(1) }

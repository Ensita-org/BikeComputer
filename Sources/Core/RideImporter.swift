import Foundation
import SwiftData
#if canImport(ZipFoundation)
import ZipFoundation
#endif

enum ImportError: LocalizedError {
    case noValidRides
    case unreadableFile
    case zipNotSupported

    var errorDescription: String? {
        switch self {
        case .noValidRides:
            return String(localized: "No valid GPX rides found in the file.")
        case .unreadableFile:
            return String(localized: "The file could not be read.")
        case .zipNotSupported:
            return "ZIP import requires the ZipFoundation package. In Xcode: File > Add Package Dependencies > https://github.com/weichsel/ZipFoundation.git"
        }
    }
}

struct RideImporter {

    /// Import a single GPX file from raw data.
    static func importGPX(data: Data, into context: ModelContext) throws {
        guard let ride = GPXParser().parse(data: data) else {
            throw ImportError.noValidRides
        }
        insert(ride, into: context)
        try context.save()
    }

    /// Extract all GPX files from a ZIP archive and import each one.
    static func importZIP(url: URL, into context: ModelContext) throws {
        #if canImport(ZipFoundation)
        guard let archive = Archive(url: url, accessMode: .read) else {
            throw ImportError.unreadableFile
        }
        var imported = 0
        for entry in archive
            where !entry.path.hasPrefix("__MACOSX") && entry.path.hasSuffix(".gpx") {
            var data = Data()
            _ = try archive.extract(entry) { chunk in data.append(chunk) }
            if let ride = GPXParser().parse(data: data) {
                insert(ride, into: context)
                imported += 1
            }
        }
        guard imported > 0 else { throw ImportError.noValidRides }
        try context.save()
        #else
        throw ImportError.zipNotSupported
        #endif
    }

    // MARK: - Private

    private static func isDuplicate(_ ride: ParsedRide, in context: ModelContext) -> Bool {
        let ts = ride.timestamp
        let predicate = #Predicate<Activity> { $0.timestamp == ts }
        let descriptor = FetchDescriptor(predicate: predicate)
        return (try? context.fetchCount(descriptor)) ?? 0 > 0
    }

    private static func insert(_ ride: ParsedRide, into context: ModelContext) {
        guard !isDuplicate(ride, in: context) else { return }
        let activity = Activity(
            timestamp: ride.timestamp,
            distance: ride.distance,
            duration: ride.duration
        )
        activity.averageSpeed = ride.averageSpeed
        activity.maxSpeed = ride.maxSpeed
        activity.routeData = try? JSONEncoder().encode(ride.points)
        context.insert(activity)
    }
}

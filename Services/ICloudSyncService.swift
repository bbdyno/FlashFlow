import Foundation

actor ICloudSyncService {
    private struct CloudSnapshotEnvelope: Codable, Sendable {
        let version: Int
        let updatedAt: Date
        let backupData: Data

        init(updatedAt: Date, backupData: Data) {
            self.version = 1
            self.updatedAt = updatedAt
            self.backupData = backupData
        }
    }

    private enum Constants {
        static let defaultContainerIdentifier = "iCloud.com.bbdyno.app.flashFlow"
        static let snapshotFileName = "flashforge-sync-v1.json"
        static let localRevisionKey = "FlashForge.iCloud.localRevision"
    }

    private enum DateCoding {
        static let fractionalFormatter: ISO8601DateFormatter = {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return formatter
        }()

        static let legacyFormatter: ISO8601DateFormatter = {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            return formatter
        }()

        static func decode(_ value: String) -> Date? {
            fractionalFormatter.date(from: value) ?? legacyFormatter.date(from: value)
        }
    }

    private let repository: CardRepository
    private let fileManager: FileManager
    private let notificationCenter: NotificationCenter
    private let userDefaults: UserDefaults
    private let ubiquityContainerIdentifier: String
    private let containerURLOverride: URL?

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private var hasBootstrapped = false
    private var suppressNextLocalPush = false

    init(
        repository: CardRepository,
        fileManager: FileManager = .default,
        notificationCenter: NotificationCenter = .default,
        userDefaults: UserDefaults = .standard,
        ubiquityContainerIdentifier: String = Constants.defaultContainerIdentifier,
        containerURLOverride: URL? = nil
    ) {
        self.repository = repository
        self.fileManager = fileManager
        self.notificationCenter = notificationCenter
        self.userDefaults = userDefaults
        self.ubiquityContainerIdentifier = ubiquityContainerIdentifier
        self.containerURLOverride = containerURLOverride

        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(DateCoding.fractionalFormatter.string(from: date))
        }
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            if let date = DateCoding.decode(value) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unsupported date format: \(value)"
            )
        }
    }

    func bootstrap() async {
        guard !hasBootstrapped else {
            return
        }
        hasBootstrapped = true

        do {
            try await repository.prepare()
            try await syncBidirectionally()
            publishStatus(isSyncing: false, errorMessage: nil)
        } catch {
            publishStatus(isSyncing: false, errorMessage: error.localizedDescription)
            return
        }
    }

    func handleLocalDataDidChange() async {
        if suppressNextLocalPush {
            suppressNextLocalPush = false
            return
        }

        do {
            try await repository.prepare()
            try await pushLocalSnapshot()
            publishStatus(isSyncing: false, errorMessage: nil)
        } catch {
            publishStatus(isSyncing: false, errorMessage: error.localizedDescription)
            return
        }
    }

    func syncFromCloudNow() async {
        publishStatus(isSyncing: true, errorMessage: nil)
        do {
            try await repository.prepare()
            try await syncBidirectionally()
            publishStatus(isSyncing: false, errorMessage: nil)
        } catch {
            publishStatus(isSyncing: false, errorMessage: error.localizedDescription)
            return
        }
    }

    private func syncBidirectionally() async throws {
        let localHasDecks = try await repository.hasAnyDecks()
        let remoteEnvelope = try loadRemoteEnvelope()
        let localRevisionDate = localRevisionDate

        guard let remoteEnvelope else {
            if localHasDecks {
                try await pushLocalSnapshot()
            }
            return
        }

        guard let localRevisionDate else {
            if localHasDecks {
                try await pushLocalSnapshot()
            } else {
                try await importRemoteEnvelope(remoteEnvelope)
            }
            return
        }

        if remoteEnvelope.updatedAt > localRevisionDate {
            try await importRemoteEnvelope(remoteEnvelope)
        } else if remoteEnvelope.updatedAt < localRevisionDate {
            try await pushLocalSnapshot()
        }
    }

    private func importRemoteEnvelope(_ envelope: CloudSnapshotEnvelope) async throws {
        try await repository.importBackupData(envelope.backupData)
        localRevisionDate = envelope.updatedAt
        suppressNextLocalPush = true

        await MainActor.run {
            notificationCenter.post(name: .deckDataDidChange, object: nil)
        }
    }

    private func pushLocalSnapshot() async throws {
        let backupData = try await repository.exportBackupData()
        let updatedAt = Date()
        let envelope = CloudSnapshotEnvelope(updatedAt: updatedAt, backupData: backupData)
        try writeRemoteEnvelope(envelope)
        localRevisionDate = updatedAt
    }

    private func loadRemoteEnvelope() throws -> CloudSnapshotEnvelope? {
        guard let fileURL = try cloudSnapshotFileURL() else {
            return nil
        }

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        let data = try Data(contentsOf: fileURL)
        return try decoder.decode(CloudSnapshotEnvelope.self, from: data)
    }

    private func writeRemoteEnvelope(_ envelope: CloudSnapshotEnvelope) throws {
        guard let fileURL = try cloudSnapshotFileURL() else {
            return
        }

        let data = try encoder.encode(envelope)
        try data.write(to: fileURL, options: .atomic)
    }

    private func cloudSnapshotFileURL() throws -> URL? {
        if let containerURLOverride {
            try fileManager.createDirectory(at: containerURLOverride, withIntermediateDirectories: true)
            return containerURLOverride.appendingPathComponent(Constants.snapshotFileName)
        }

        guard let containerRoot = fileManager.url(forUbiquityContainerIdentifier: ubiquityContainerIdentifier) else {
            return nil
        }

        let documentsURL = containerRoot.appendingPathComponent("Documents", isDirectory: true)
        try fileManager.createDirectory(at: documentsURL, withIntermediateDirectories: true)
        return documentsURL.appendingPathComponent(Constants.snapshotFileName)
    }

    private var localRevisionDate: Date? {
        get {
            userDefaults.object(forKey: Constants.localRevisionKey) as? Date
        }
        set {
            userDefaults.set(newValue, forKey: Constants.localRevisionKey)
        }
    }

    private func publishStatus(isSyncing: Bool, errorMessage: String?) {
        var userInfo: [String: Any] = [
            ICloudSyncNotificationKey.isSyncing: isSyncing
        ]
        if let localRevisionDate {
            userInfo[ICloudSyncNotificationKey.lastSyncedAt] = localRevisionDate
        }
        if let errorMessage, !errorMessage.isEmpty {
            userInfo[ICloudSyncNotificationKey.errorMessage] = errorMessage
        }
        notificationCenter.post(name: .iCloudSyncStatusDidChange, object: nil, userInfo: userInfo)
    }
}

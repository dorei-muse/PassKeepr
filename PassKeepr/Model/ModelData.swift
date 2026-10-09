import Foundation
import os

private let logger = Logger(subsystem: "com.hanshaw.passKeepr", category: "ModelData")

@MainActor
class ModelData: ObservableObject {
    struct PassKeeprData: Codable {
        var passObjects: [PassObject]
        var tutorialStage: Int
    }

    let filename: String = "PassKeeprData.json"

    @Published var passObjects: [PassObject] = [] // Holds all PassObjects in a single array
    @Published var tutorialStage: Int = 0

    init() {
        Task { await loadFromDisk() }
    }

    static func loadShared() async -> ModelData {
        let modelData = ModelData()
        await modelData.loadFromDisk()
        return modelData
    }

    func loadFromDisk() async {
        do {
            let loadedData: PassKeeprData = try await load(filename)
            passObjects = loadedData.passObjects
            tutorialStage = loadedData.tutorialStage
        } catch {
            logger.error("Failed to load pass data: \(error.localizedDescription)")
        }
    }

    func encodePassObjects() async throws {
        let data = PassKeeprData(passObjects: passObjects, tutorialStage: tutorialStage)
        try await encode(filename, data)
    }

    func save() {
        Task {
            do {
                try await encodePassObjects()
            } catch {
                logger.error("Failed to save pass data: \(error.localizedDescription)")
            }
        }
    }

    func load<T: Decodable>(_ filename: String) async throws -> T {
        guard let applicationSupportDirectory = AppSupportDirectory.url else {
            throw PersistenceError.missingDirectory
        }
        let file = applicationSupportDirectory.appendingPathComponent(filename)
        let data = try Data(contentsOf: file)
        return try JSONDecoder().decode(T.self, from: data)
    }

    func encode<T: Encodable>(_ filename: String, _ data: T) async throws {
        guard let applicationSupportDirectory = AppSupportDirectory.url else {
            throw PersistenceError.missingDirectory
        }
        let file = applicationSupportDirectory.appendingPathComponent(filename)
        try FileManager.default.createDirectory(at: applicationSupportDirectory, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let encodedData = try encoder.encode(data)
        try encodedData.write(to: file, options: .atomic)
    }

    func deleteItemByID(_ idToDelete: UUID) {
        if let index = passObjects.firstIndex(where: { $0.id == idToDelete }) {
            passObjects.remove(at: index)
            save()
        }
    }

    func deleteAllItems() {
        passObjects.removeAll()
        save()
    }

    func deleteDataFile() {
        guard let applicationSupportDirectory = AppSupportDirectory.url else { return }
        let fileURL = applicationSupportDirectory.appendingPathComponent(filename)

        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
        } catch {
            logger.error("Error deleting data file: \(error.localizedDescription)")
        }
    }
}

enum PersistenceError: Error {
    case missingDirectory
}

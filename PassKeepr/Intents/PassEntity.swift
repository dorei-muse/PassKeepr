import AppIntents
import Foundation

struct PassEntity: AppEntity {
    var id: UUID
    var title: String
    var barcodeType: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Pass")
    }

    static var defaultQuery = PassEntityQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)", subtitle: "\(barcodeType)")
    }
}

struct PassEntityQuery: EntityQuery {
    func entities(for _: [UUID]) async throws -> [PassEntity] {
        []
    }

    func suggestedEntities() async throws -> [PassEntity] {
        []
    }
}

import SwiftData
@testable import DaisyDos

/// Test utilities for creating isolated in-memory SwiftData containers
enum TestHelpers {
    /// Creates an in-memory ModelContainer for testing with all DaisyDos models
    /// - Returns: A fresh ModelContainer configured for in-memory testing
    /// - Throws: If the container cannot be created (schema issues, etc.)
    static func createTestContainer() throws -> ModelContainer {
        // Use the same versioned schema as the main app
        let schema = Schema(versionedSchema: DaisyDosSchemaV7.self)

        // Configure for in-memory testing with CloudKit explicitly disabled
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none  // Explicitly disable CloudKit validation
        )

        // Create container without migration plan for testing
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    /// Creates a test ModelContext from a fresh container
    /// - Returns: A ModelContext ready for testing
    /// - Throws: If the container cannot be created
    static func createTestContext() throws -> ModelContext {
        let container = try createTestContainer()
        return ModelContext(container)
    }
}

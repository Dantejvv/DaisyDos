//
//  DaisyDosMigrationPlan.swift
//  DaisyDos
//
//  Created by Dante Vercelli on 9/23/25.
//

import Foundation
import SwiftData

/// Migration plan for DaisyDos database schema versions
/// V4 adds logbook support with TaskLogEntry and CompletionAggregate models
struct DaisyDosMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [DaisyDosSchemaV3.self, DaisyDosSchemaV4.self]
    }

    static var stages: [MigrationStage] {
        // Lightweight migration from V3 to V4 (adding new models)
        // SwiftData handles this automatically - no custom migration needed
        []
    }

}
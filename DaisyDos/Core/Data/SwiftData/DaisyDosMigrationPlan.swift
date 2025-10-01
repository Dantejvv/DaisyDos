//
//  DaisyDosMigrationPlan.swift
//  DaisyDos
//
//  Created by Dante Vercelli on 9/23/25.
//

import Foundation
import SwiftData

/// Migration plan for DaisyDos database schema versions
/// Simple approach: Clear existing data when schema changes to avoid migration complexity
struct DaisyDosMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [DaisyDosSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        // Starting fresh with priority-enabled schema
        []
    }

}
//
//  DaisyDosMigrationPlan.swift
//  DaisyDos
//
//  Created by Dante Vercelli on 9/23/25.
//

import Foundation
import SwiftData

/// Migration plan for DaisyDos database schema versions
/// Simple approach: Start fresh with current schema version
struct DaisyDosMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [DaisyDosSchemaV3.self]
    }

    static var stages: [MigrationStage] {
        // No migration stages - using V3 as baseline schema
        []
    }

}
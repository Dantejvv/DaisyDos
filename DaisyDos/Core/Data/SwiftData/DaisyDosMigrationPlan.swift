//
//  DaisyDosMigrationPlan.swift
//  DaisyDos
//
//  Created by Dante Vercelli on 9/23/25.
//

import Foundation
import SwiftData

/// Migration plan for DaisyDos database schema versions
/// Handles migration from V1 (basic Task model) to V2 (enhanced Task model with attachments)
struct DaisyDosMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [DaisyDosSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        // No migrations needed - starting fresh with V2
        []
    }

}
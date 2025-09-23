//
//  DaisyDosMigrationPlan.swift
//  DaisyDos
//
//  Created by Dante Vercelli on 9/23/25.
//

import Foundation
import SwiftData

struct DaisyDosMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [DaisyDosSchemaV1.self]
    }
    static var stages: [MigrationStage] {
        [] // V1 baseline - no migrations needed yet
    }
}
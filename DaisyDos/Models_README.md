# Models Directory Structure

This file documents the planned model organization for DaisyDos. The current implementation uses a simple structure with schema files at the root level, but will be reorganized as the project grows.

## Current Structure
```
DaisyDos/
├── DaisyDosSchemaV1.swift     # Versioned schema definition
├── DaisyDosMigrationPlan.swift # Migration plan
├── Item.swift                  # Placeholder model (to be replaced)
└── Models_README.md           # This documentation file
```

## Future Structure (Phase 1.2+)
```
DaisyDos/
├── Models/
│   ├── Core/                   # Core @Model classes
│   │   ├── Task.swift         # Task model with @Model macro
│   │   ├── Habit.swift        # Habit model with @Model macro
│   │   ├── Tag.swift          # Tag model with @Model macro
│   │   └── Subtask.swift      # Subtask model (if needed)
│   │
│   ├── Schema/                 # Schema versions and migrations
│   │   ├── DaisyDosSchemaV1.swift
│   │   ├── DaisyDosMigrationPlan.swift
│   │   └── (future schema versions)
│   │
│   ├── Recurring/              # Recurrence rule business logic
│   │   └── RecurrenceRule.swift
│   │
│   └── Settings/               # Settings-related models
│       ├── UserPreferences.swift
│       ├── LocalSettings.swift
│       └── PrivacySettings.swift
```

## Implementation Notes

### Current Schema (V1)
- Contains only `Item.self` as a placeholder
- Ready for migration to include `Task.self, Habit.self, Tag.self` in future versions

### Migration Strategy
When adding the actual Task/Habit/Tag models:
1. Create the new models in the appropriate directories
2. Create DaisyDosSchemaV2 with the new models
3. Add migration stages to DaisyDosMigrationPlan
4. Update ModelContainer to use the new schema

### Next Steps (Phase 1.2)
1. Create the actual Task, Habit, and Tag @Model classes
2. Implement relationships between models
3. Update the schema to include the new models
4. Test migration from V1 to V2
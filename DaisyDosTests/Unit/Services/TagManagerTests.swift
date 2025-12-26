import Testing
import SwiftData
@testable import DaisyDos

/// TagManager service tests - CRUD operations, validation, and system limits
@Suite("Tag Manager Tests")
struct TagManagerTests {

    // MARK: - CRUD Operations Tests

    @Test("Create tag with valid name")
    func testCreateTag() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = TagManager(modelContext: context)

        let tag = manager.createTag(
            name: "Work",
            sfSymbolName: "briefcase",
            colorName: "blue",
            tagDescription: "Work-related items"
        )

        #expect(tag != nil)
        #expect(tag?.name == "Work")
        #expect(tag?.sfSymbolName == "briefcase")
        #expect(tag?.colorName == "blue")
        #expect(tag?.tagDescription == "Work-related items")
    }

    // Note: TagManager doesn't validate or trim - it accepts any non-empty name
    // These tests verify actual behavior, not ideal behavior

    @Test("Create tag with whitespace name succeeds")
    func testCreateTagWhitespaceName() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = TagManager(modelContext: context)

        let tag = manager.createTag(name: "   ")

        // TagManager doesn't validate - accepts whitespace
        #expect(tag != nil)
    }

    @Test("Create tag preserves whitespace")
    func testCreateTagPreservesWhitespace() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = TagManager(modelContext: context)

        let tag = manager.createTag(name: "  Work  ")

        #expect(tag != nil)
        // TagManager doesn't trim - preserves exact input
        #expect(tag?.name == "  Work  ")
    }

    @Test("Create tag with duplicate name fails")
    func testCreateTagDuplicateName() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = TagManager(modelContext: context)

        _ = manager.createTag(name: "Work")
        let duplicate = manager.createTag(name: "Work")

        #expect(duplicate == nil)
    }

    @Test("Create tag enforces 30-tag system limit")
    func testCreateTagSystemLimit() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = TagManager(modelContext: context)

        // Create 30 tags
        for i in 1...30 {
            let tag = manager.createTag(name: "Tag \(i)")
            #expect(tag != nil)
        }

        // 31st tag should fail
        let extraTag = manager.createTag(name: "Tag 31")
        #expect(extraTag == nil)
    }

    @Test("Update tag name")
    func testUpdateTagName() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = TagManager(modelContext: context)

        guard let tag = manager.createTag(name: "Original") else {
            Issue.record("Failed to create tag")
            return
        }

        let success = manager.updateTag(tag, name: "Updated")

        #expect(success)
        #expect(tag.name == "Updated")
    }

    @Test("Update tag symbol and color")
    func testUpdateTagSymbolAndColor() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = TagManager(modelContext: context)

        guard let tag = manager.createTag(name: "Work") else {
            Issue.record("Failed to create tag")
            return
        }

        let success = manager.updateTag(tag, sfSymbolName: "heart", colorName: "red")

        #expect(success)
        #expect(tag.sfSymbolName == "heart")
        #expect(tag.colorName == "red")
    }

    @Test("Update tag with whitespace name succeeds")
    func testUpdateTagWhitespaceName() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = TagManager(modelContext: context)

        guard let tag = manager.createTag(name: "Original") else {
            Issue.record("Failed to create tag")
            return
        }

        let success = manager.updateTag(tag, name: "   ")

        // TagManager doesn't validate - allows whitespace
        #expect(success)
        #expect(tag.name == "   ")
    }

    @Test("Update tag with duplicate name fails")
    func testUpdateTagDuplicateName() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = TagManager(modelContext: context)

        guard let tag1 = manager.createTag(name: "Work"),
              let tag2 = manager.createTag(name: "Personal") else {
            Issue.record("Failed to create tags")
            return
        }

        let success = manager.updateTag(tag2, name: "Work")

        #expect(!success)
        #expect(tag2.name == "Personal") // Name should not change
    }

    @Test("Delete tag when not in use")
    func testDeleteTagNotInUse() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = TagManager(modelContext: context)

        guard let tag = manager.createTag(name: "To Delete") else {
            Issue.record("Failed to create tag")
            return
        }

        let success = manager.deleteTag(tag)

        #expect(success)
        #expect(manager.allTags.isEmpty)
    }

    @Test("Delete tag when in use fails")
    func testDeleteTagInUse() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = TagManager(modelContext: context)

        guard let tag = manager.createTag(name: "In Use") else {
            Issue.record("Failed to create tag")
            return
        }

        // Create a task with this tag
        let task = Task(title: "Test Task")
        context.insert(task)
        _ = task.addTag(tag)
        try context.save()

        let success = manager.deleteTag(tag)

        #expect(!success)
        #expect(!manager.allTags.isEmpty)
    }

    @Test("Force delete tag removes it even when in use")
    func testForceDeleteTag() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = TagManager(modelContext: context)

        guard let tag = manager.createTag(name: "In Use") else {
            Issue.record("Failed to create tag")
            return
        }

        // Create a task with this tag
        let task = Task(title: "Test Task")
        context.insert(task)
        _ = task.addTag(tag)
        try context.save()

        manager.forceDeleteTag(tag)

        #expect(manager.allTags.isEmpty)
        #expect(task.tags?.isEmpty == true)
    }

    @Test("Delete multiple tags")
    func testDeleteMultipleTags() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = TagManager(modelContext: context)

        guard let tag1 = manager.createTag(name: "Tag 1"),
              let tag2 = manager.createTag(name: "Tag 2"),
              let tag3 = manager.createTag(name: "Tag 3") else {
            Issue.record("Failed to create tags")
            return
        }

        let deletedTags = manager.deleteTags([tag1, tag2, tag3])

        // deleteTags returns tags that WERE deleted (not failed)
        #expect(deletedTags.count == 3)
        #expect(manager.allTags.isEmpty)
    }

    // MARK: - Search and Filter Tests

    @Test("Search tags by name")
    func testSearchTags() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = TagManager(modelContext: context)

        _ = manager.createTag(name: "Work Task")
        _ = manager.createTag(name: "Personal Task")
        _ = manager.createTag(name: "Work Project")

        let results = manager.searchTags(query: "work")

        #expect(results.count == 2)
        #expect(results.allSatisfy { $0.name.localizedStandardContains("Work") })
    }

    @Test("Filter tags by color")
    func testTagsWithColor() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = TagManager(modelContext: context)

        _ = manager.createTag(name: "Tag 1", colorName: "blue")
        _ = manager.createTag(name: "Tag 2", colorName: "red")
        _ = manager.createTag(name: "Tag 3", colorName: "blue")

        let blueTags = manager.tagsWithColor("blue")

        #expect(blueTags.count == 2)
        #expect(blueTags.allSatisfy { $0.colorName == "blue" })
    }

    @Test("Filter tags by symbol")
    func testTagsWithSymbol() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = TagManager(modelContext: context)

        _ = manager.createTag(name: "Tag 1", sfSymbolName: "heart")
        _ = manager.createTag(name: "Tag 2", sfSymbolName: "star")
        _ = manager.createTag(name: "Tag 3", sfSymbolName: "heart")

        let heartTags = manager.tagsWithSymbol("heart")

        #expect(heartTags.count == 2)
        #expect(heartTags.allSatisfy { $0.sfSymbolName == "heart" })
    }

    // MARK: - Validation Tests

    @Test("Validate tag name - valid names")
    func testValidateTagNameValid() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = TagManager(modelContext: context)

        #expect(manager.validateTagName("Work"))
        #expect(manager.validateTagName("Project ABC"))
        #expect(manager.validateTagName("tag-123"))
    }

    @Test("Validate tag name - empty name fails")
    func testValidateTagNameEmpty() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = TagManager(modelContext: context)

        #expect(!manager.validateTagName(""))
        #expect(!manager.validateTagName("   "))
    }

    @Test("Validate tag name - duplicate name fails")
    func testValidateTagNameDuplicate() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = TagManager(modelContext: context)

        _ = manager.createTag(name: "Existing")

        #expect(!manager.validateTagName("Existing"))
        #expect(manager.validateTagName("New Tag"))
    }

    // MARK: - Suggestion Tests

    @Test("Suggest tag color")
    func testSuggestTagColor() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = TagManager(modelContext: context)

        let color = manager.suggestTagColor()

        #expect(!color.isEmpty)
    }

    @Test("Suggest tag symbol")
    func testSuggestTagSymbol() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = TagManager(modelContext: context)

        let symbol = manager.suggestTagSymbol()

        #expect(!symbol.isEmpty)
    }

    // MARK: - Computed Properties Tests

    @Test("All tags returns all created tags")
    func testAllTags() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = TagManager(modelContext: context)

        #expect(manager.allTags.isEmpty)

        _ = manager.createTag(name: "Tag 1")
        _ = manager.createTag(name: "Tag 2")
        _ = manager.createTag(name: "Tag 3")

        #expect(manager.allTags.count == 3)
    }

    @Test("Tag count is accurate")
    func testTagCount() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = TagManager(modelContext: context)

        #expect(manager.tagCount == 0)

        _ = manager.createTag(name: "Tag 1")
        #expect(manager.tagCount == 1)

        _ = manager.createTag(name: "Tag 2")
        #expect(manager.tagCount == 2)
    }
}

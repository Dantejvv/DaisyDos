//
//  NavigationRouteTests.swift
//  DaisyDosTests
//
//  Created by Claude Code on 1/8/26.
//

import Testing
import Foundation
@testable import DaisyDos

/// Comprehensive tests for NavigationRoute deep linking
@Suite("NavigationRoute Tests")
struct NavigationRouteTests {

    // MARK: - URL Parsing Tests

    @Suite("URL Parsing")
    struct URLParsingTests {

        @Test("Parse valid tab URLs")
        func testParseTabURLs() {
            let testCases: [(String, NavigationRoute)] = [
                ("daisydos://today", .today),
                ("daisydos://tasks", .tasks),
                ("daisydos://habits", .habits),
                ("daisydos://logbook", .logbook),
                ("daisydos://settings", .settings)
            ]

            for (urlString, expectedRoute) in testCases {
                let url = URL(string: urlString)!
                let route = NavigationRoute.parse(from: url)
                #expect(route == expectedRoute, "Failed to parse \(urlString)")
            }
        }

        @Test("Parse task URL with valid UUID")
        func testParseTaskURL() {
            let uuid = UUID()
            let url = URL(string: "daisydos://task/\(uuid.uuidString)")!

            let route = NavigationRoute.parse(from: url)

            #expect(route == .task(uuid))
        }

        @Test("Parse habit URL with valid UUID")
        func testParseHabitURL() {
            let uuid = UUID()
            let url = URL(string: "daisydos://habit/\(uuid.uuidString)")!

            let route = NavigationRoute.parse(from: url)

            #expect(route == .habit(uuid))
        }

        @Test("Reject invalid URL scheme")
        func testRejectInvalidScheme() {
            let invalidURLs = [
                "https://today",
                "http://task/123",
                "myapp://today",
                "daisydos-wrong://tasks"
            ]

            for urlString in invalidURLs {
                let url = URL(string: urlString)!
                let route = NavigationRoute.parse(from: url)
                #expect(route == nil, "Should reject URL with wrong scheme: \(urlString)")
            }
        }

        @Test("Reject malformed UUID in task URL")
        func testRejectMalformedTaskUUID() {
            let invalidURLs = [
                "daisydos://task/not-a-uuid",
                "daisydos://task/12345",
                "daisydos://task/",
                "daisydos://task"
            ]

            for urlString in invalidURLs {
                let url = URL(string: urlString)!
                let route = NavigationRoute.parse(from: url)
                #expect(route == nil, "Should reject malformed task URL: \(urlString)")
            }
        }

        @Test("Reject malformed UUID in habit URL")
        func testRejectMalformedHabitUUID() {
            let invalidURLs = [
                "daisydos://habit/not-a-uuid",
                "daisydos://habit/12345",
                "daisydos://habit/",
                "daisydos://habit"
            ]

            for urlString in invalidURLs {
                let url = URL(string: urlString)!
                let route = NavigationRoute.parse(from: url)
                #expect(route == nil, "Should reject malformed habit URL: \(urlString)")
            }
        }

        @Test("Reject unknown routes")
        func testRejectUnknownRoutes() {
            let unknownURLs = [
                "daisydos://unknown",
                "daisydos://profile",
                "daisydos://calendar",
                "daisydos://"
            ]

            for urlString in unknownURLs {
                let url = URL(string: urlString)!
                let route = NavigationRoute.parse(from: url)
                #expect(route == nil, "Should reject unknown route: \(urlString)")
            }
        }

        @Test("Parse is case insensitive for route type")
        func testCaseInsensitiveParsing() {
            let testCases = [
                "daisydos://TODAY",
                "daisydos://Today",
                "daisydos://TASKS",
                "daisydos://Tasks"
            ]

            for urlString in testCases {
                let url = URL(string: urlString)!
                let route = NavigationRoute.parse(from: url)
                #expect(route != nil, "Should parse case-insensitive URL: \(urlString)")
            }
        }
    }

    // MARK: - URL Generation Tests

    @Suite("URL Generation")
    struct URLGenerationTests {

        @Test("Generate tab URLs")
        func testGenerateTabURLs() {
            let testCases: [(NavigationRoute, String)] = [
                (.today, "daisydos://today"),
                (.tasks, "daisydos://tasks"),
                (.habits, "daisydos://habits"),
                (.logbook, "daisydos://logbook"),
                (.settings, "daisydos://settings")
            ]

            for (route, expectedURLString) in testCases {
                let url = route.url
                #expect(url != nil)
                #expect(url?.absoluteString == expectedURLString)
            }
        }

        @Test("Generate task URL with UUID")
        func testGenerateTaskURL() {
            let uuid = UUID()
            let route = NavigationRoute.task(uuid)

            let url = route.url

            #expect(url != nil)
            #expect(url?.absoluteString == "daisydos://task/\(uuid.uuidString)")
        }

        @Test("Generate habit URL with UUID")
        func testGenerateHabitURL() {
            let uuid = UUID()
            let route = NavigationRoute.habit(uuid)

            let url = route.url

            #expect(url != nil)
            #expect(url?.absoluteString == "daisydos://habit/\(uuid.uuidString)")
        }

        @Test("URL scheme constant is correct")
        func testSchemeConstant() {
            #expect(NavigationRoute.scheme == "daisydos")
        }
    }

    // MARK: - Round Trip Tests

    @Suite("Round Trip")
    struct RoundTripTests {

        @Test("Round trip: generate then parse tab routes")
        func testRoundTripTabRoutes() {
            let routes: [NavigationRoute] = [.today, .tasks, .habits, .logbook, .settings]

            for originalRoute in routes {
                let url = originalRoute.url!
                let parsedRoute = NavigationRoute.parse(from: url)
                #expect(parsedRoute == originalRoute, "Round trip failed for \(originalRoute)")
            }
        }

        @Test("Round trip: generate then parse task route")
        func testRoundTripTaskRoute() {
            let uuid = UUID()
            let originalRoute = NavigationRoute.task(uuid)

            let url = originalRoute.url!
            let parsedRoute = NavigationRoute.parse(from: url)

            #expect(parsedRoute == originalRoute)
        }

        @Test("Round trip: generate then parse habit route")
        func testRoundTripHabitRoute() {
            let uuid = UUID()
            let originalRoute = NavigationRoute.habit(uuid)

            let url = originalRoute.url!
            let parsedRoute = NavigationRoute.parse(from: url)

            #expect(parsedRoute == originalRoute)
        }
    }

    // MARK: - Route Properties Tests

    @Suite("Route Properties")
    struct RoutePropertiesTests {

        @Test("targetTab returns correct tab for each route")
        func testTargetTab() {
            let testCases: [(NavigationRoute, TabType)] = [
                (.today, .today),
                (.tasks, .tasks),
                (.habits, .habits),
                (.logbook, .logbook),
                (.settings, .settings),
                (.task(UUID()), .tasks),
                (.habit(UUID()), .habits)
            ]

            for (route, expectedTab) in testCases {
                #expect(route.targetTab == expectedTab, "Wrong targetTab for \(route)")
            }
        }

        @Test("requiresNavigation is true for entity routes")
        func testRequiresNavigationEntity() {
            #expect(NavigationRoute.task(UUID()).requiresNavigation == true)
            #expect(NavigationRoute.habit(UUID()).requiresNavigation == true)
        }

        @Test("requiresNavigation is false for tab routes")
        func testRequiresNavigationTab() {
            let tabRoutes: [NavigationRoute] = [.today, .tasks, .habits, .logbook, .settings]

            for route in tabRoutes {
                #expect(route.requiresNavigation == false, "Tab route should not require navigation: \(route)")
            }
        }
    }

    // MARK: - Hashable Conformance Tests

    @Suite("Hashable Conformance")
    struct HashableTests {

        @Test("Same routes are equal")
        func testEqualRoutes() {
            let uuid = UUID()

            #expect(NavigationRoute.today == NavigationRoute.today)
            #expect(NavigationRoute.task(uuid) == NavigationRoute.task(uuid))
            #expect(NavigationRoute.habit(uuid) == NavigationRoute.habit(uuid))
        }

        @Test("Different routes are not equal")
        func testDifferentRoutes() {
            let uuid1 = UUID()
            let uuid2 = UUID()

            #expect(NavigationRoute.today != NavigationRoute.tasks)
            #expect(NavigationRoute.task(uuid1) != NavigationRoute.task(uuid2))
            #expect(NavigationRoute.task(uuid1) != NavigationRoute.habit(uuid1))
        }

        @Test("Routes can be used in Set")
        func testSetUsage() {
            let uuid = UUID()
            var routeSet: Set<NavigationRoute> = []

            routeSet.insert(.today)
            routeSet.insert(.today) // Duplicate
            routeSet.insert(.task(uuid))

            #expect(routeSet.count == 2)
        }
    }
}

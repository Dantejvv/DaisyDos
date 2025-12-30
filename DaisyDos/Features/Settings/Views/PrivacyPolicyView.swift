//
//  PrivacyPolicyView.swift
//  DaisyDos
//
//  Created by Claude Code on 12/22/25.
//

import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppearanceManager.self) private var appearanceManager

    private let lastUpdated = "December 22, 2025"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    commitmentSection
                    dataStoredSection
                    iCloudSyncSection
                    permissionsSection
                    dataRetentionSection
                    thirdPartySection
                    privacyRightsSection
                    noTrackingSection
                    contactSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .applyAppearance(appearanceManager)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Privacy Policy")
                .font(.title.bold())
                .foregroundColor(.daisyText)

            Text("Last Updated: \(lastUpdated)")
                .font(.caption)
                .foregroundColor(.daisyTextSecondary)

            Text("DaisyDos is a privacy-first productivity application. Your data belongs to you, and we've built the app to keep it that way.")
                .font(.body)
                .foregroundColor(.daisyTextSecondary)
                .padding(.top, 4)
        }
    }

    // MARK: - Commitment Section

    private var commitmentSection: some View {
        PolicySection(title: "Our Privacy Commitment", icon: "shield.checkered") {
            VStack(alignment: .leading, spacing: 8) {
                CommitmentRow(icon: "iphone", text: "Local-First: All data stored on your device by default")
                CommitmentRow(icon: "server.rack", text: "No Servers: We do not operate servers that store your data")
                CommitmentRow(icon: "xmark.shield", text: "No Third-Party SDKs: No analytics, advertising, or tracking code")
                CommitmentRow(icon: "icloud", text: "Optional Sync: iCloud sync is disabled by default")
                CommitmentRow(icon: "dollarsign.circle", text: "No Data Sales: Your data is never sold to third parties")
                CommitmentRow(icon: "hand.raised", text: "Complete Control: Export or delete all your data anytime")
            }
        }
    }

    // MARK: - Data Stored Section

    private var dataStoredSection: some View {
        PolicySection(title: "What Data Is Stored Locally", icon: "internaldrive") {
            VStack(alignment: .leading, spacing: 12) {
                DataCategoryRow(category: "Tasks", items: [
                    "Titles, descriptions, due dates, priorities",
                    "Subtasks and completion status",
                    "Alert reminders and recurrence patterns"
                ])

                DataCategoryRow(category: "Habits", items: [
                    "Titles, descriptions, completion history",
                    "Streak data and analytics",
                    "Skip history and reasons"
                ])

                DataCategoryRow(category: "Attachments", items: [
                    "Photos you attach to tasks or habits",
                    "File metadata (size, type, date)"
                ])

                DataCategoryRow(category: "Other", items: [
                    "Tags (names, colors, icons)",
                    "Completion history (Logbook)",
                    "App settings and preferences"
                ])
            }
        }
    }

    // MARK: - iCloud Sync Section

    private var iCloudSyncSection: some View {
        PolicySection(title: "iCloud Sync (Optional)", icon: "icloud") {
            VStack(alignment: .leading, spacing: 12) {
                Text("When you enable iCloud sync:")
                    .font(.subheadline.bold())
                    .foregroundColor(.daisyText)

                VStack(alignment: .leading, spacing: 6) {
                    BulletPoint("Data syncs to your personal private iCloud database")
                    BulletPoint("Only accessible through your Apple ID")
                    BulletPoint("We (the developers) have no access to your iCloud data")
                    BulletPoint("Can be disabled anytime in Settings")
                }

                Divider()

                Text("iCloud sync is disabled by default. The app works fully offline.")
                    .font(.caption)
                    .foregroundColor(.daisyTextSecondary)
            }
        }
    }

    // MARK: - Permissions Section

    private var permissionsSection: some View {
        PolicySection(title: "Permissions", icon: "lock.shield") {
            VStack(spacing: 12) {
                PermissionRow(
                    icon: "photo",
                    title: "Photo Library",
                    description: "Only for attaching photos to tasks/habits"
                )
                PermissionRow(
                    icon: "bell",
                    title: "Notifications",
                    description: "Only for task and habit reminders"
                )
                PermissionRow(
                    icon: "icloud",
                    title: "iCloud",
                    description: "Only if you enable sync in Settings"
                )
            }
        }
    }

    // MARK: - Data Retention Section

    private var dataRetentionSection: some View {
        PolicySection(title: "Data Retention", icon: "clock.arrow.circlepath") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Active tasks and habits remain until you delete them.")
                    .font(.subheadline)
                    .foregroundColor(.daisyText)

                Text("Completed task history (Logbook):")
                    .font(.subheadline.bold())
                    .foregroundColor(.daisyText)
                    .padding(.top, 4)

                VStack(alignment: .leading, spacing: 4) {
                    RetentionRow(period: "0-90 days", description: "Full details retained")
                    RetentionRow(period: "91-365 days", description: "Summarized records")
                    RetentionRow(period: "365+ days", description: "Automatically deleted")
                }

                Text("You can manually delete any data at any time.")
                    .font(.caption)
                    .foregroundColor(.daisyTextSecondary)
                    .padding(.top, 4)
            }
        }
    }

    // MARK: - Third Party Section

    private var thirdPartySection: some View {
        PolicySection(title: "Third-Party Code", icon: "app.badge.checkmark") {
            VStack(alignment: .leading, spacing: 12) {
                Text("DaisyDos is built exclusively with Apple's native frameworks. We do NOT use:")
                    .font(.subheadline)
                    .foregroundColor(.daisyText)

                VStack(alignment: .leading, spacing: 6) {
                    NoItemRow("Analytics or crash reporting")
                    NoItemRow("Advertising or ad networks")
                    NoItemRow("Social media integrations")
                    NoItemRow("User tracking or profiling")
                    NoItemRow("Data brokers or processors")
                }

                Text("Your data never leaves Apple's ecosystem.")
                    .font(.caption.bold())
                    .foregroundColor(.daisyTextSecondary)
                    .padding(.top, 4)
            }
        }
    }

    // MARK: - Privacy Rights Section

    private var privacyRightsSection: some View {
        PolicySection(title: "Your Privacy Rights", icon: "person.badge.shield.checkmark") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Under GDPR (EU) and CCPA (California), you have the right to:")
                    .font(.subheadline)
                    .foregroundColor(.daisyText)

                VStack(alignment: .leading, spacing: 6) {
                    BulletPoint("Access and export your data")
                    BulletPoint("Correct inaccurate data")
                    BulletPoint("Delete your data")
                    BulletPoint("Restrict data processing")
                    BulletPoint("Object to data use")
                }

                Text("Since all data is stored locally by default, you have complete control without needing to contact us.")
                    .font(.caption)
                    .foregroundColor(.daisyTextSecondary)
                    .padding(.top, 4)
            }
        }
    }

    // MARK: - No Tracking Section

    private var noTrackingSection: some View {
        PolicySection(title: "No Tracking", icon: "eye.slash") {
            VStack(alignment: .leading, spacing: 6) {
                NoItemRow("Cookies or tracking technologies")
                NoItemRow("Advertising identifiers (IDFA)")
                NoItemRow("Location tracking")
                NoItemRow("Usage pattern monitoring")
                NoItemRow("User profile building")
                NoItemRow("Data sharing with advertisers")
            }
        }
    }

    // MARK: - Contact Section

    private var contactSection: some View {
        PolicySection(title: "Contact", icon: "envelope") {
            VStack(alignment: .leading, spacing: 8) {
                Text("If you have questions about this Privacy Policy or your data:")
                    .font(.subheadline)
                    .foregroundColor(.daisyText)

                Link("daisydosprivacy@gmail.com", destination: URL(string: "mailto:daisydosprivacy@gmail.com")!)
                    .font(.subheadline)

                Link(destination: URL(string: "https://dantejvv.github.io/privacy")!) {
                    HStack {
                        Text("View Full Policy Online")
                        Image(systemName: "arrow.up.right.square")
                    }
                    .font(.subheadline)
                }

                Text("For issues related to iCloud sync or Apple services, please contact Apple Support.")
                    .font(.caption)
                    .foregroundColor(.daisyTextSecondary)
            }
        }
    }
}

// MARK: - Supporting Views

private struct PolicySection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundColor(.daisyText)

            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

private struct CommitmentRow: View {
    let icon: String
    let text: String

    init(icon: String, text: String) {
        self.icon = icon
        self.text = text
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 20)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.daisyText)
        }
    }
}

private struct DataCategoryRow: View {
    let category: String
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(category)
                .font(.subheadline.bold())
                .foregroundColor(.daisyText)

            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .foregroundColor(.daisyTextSecondary)
                    Text(item)
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)
                }
            }
        }
    }
}

private struct BulletPoint: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.daisySuccess)
                .font(.caption)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.daisyText)
        }
    }
}

private struct NoItemRow: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.daisyError)
                .font(.caption)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.daisyText)
        }
    }
}

private struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.daisyText)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.daisyTextSecondary)
            }
        }
    }
}

private struct RetentionRow: View {
    let period: String
    let description: String

    var body: some View {
        HStack(spacing: 8) {
            Text(period)
                .font(.caption.bold())
                .foregroundColor(.daisyText)
                .frame(width: 80, alignment: .leading)
            Text(description)
                .font(.caption)
                .foregroundColor(.daisyTextSecondary)
        }
    }
}

#Preview {
    PrivacyPolicyView()
        .environment(AppearanceManager())
}

# Privacy Policy for DaisyDos

**Last Updated:** December 22, 2025
**Effective Date:** December 22, 2025

## Overview

DaisyDos is a privacy-first productivity application designed for iOS. Your data belongs to you, and we've built the app to keep it that way. All your information is stored locally on your device by default, and you have complete control over whether to enable cloud synchronization.

## Our Privacy Commitment

- **Local-First:** All data is stored on your device by default
- **No Servers:** We do not operate servers that store your data
- **No Third-Party SDKs:** DaisyDos contains no third-party analytics, advertising, or tracking code
- **Optional Sync:** iCloud sync is disabled by default and requires your explicit opt-in
- **No Data Sales:** Your data is never shared with or sold to third parties
- **Complete Control:** You can export or delete all your data at any time

## App Store Privacy Disclosure

When you download DaisyDos from the App Store, you'll see our privacy "nutrition label" which discloses:

| Category | What We Collect | Linked to You? | Used for Tracking? |
|----------|----------------|----------------|-------------------|
| User Content | Tasks, habits, notes, photos you create | Only if iCloud enabled | No |
| Identifiers | None collected by us | N/A | No |
| Usage Data | None | N/A | No |
| Diagnostics | None | N/A | No |

**Data Not Collected:** We do not collect location data, contacts, browsing history, search history, health data, financial data, or any sensitive information.

## What Data the App Stores Locally

When you use DaisyDos, the following information is stored **locally on your device**:

### Tasks
- Task titles and descriptions
- Due dates and priorities
- Subtask information
- Completion status and history
- Alert reminders and notification preferences
- Recurrence patterns (for repeating tasks)
- Associated tags

### Habits
- Habit titles and descriptions
- Completion tracking and history
- Streak data and analytics
- Subtask configurations
- Associated tags
- Skip history and reasons

### Attachments
- Photos you attach to tasks or habits
- File metadata (size, type, creation date)

### Tags
- Tag names, colors, and icons
- Usage associations with tasks and habits

### Completion History (Logbook)
- Historical records of completed tasks
- Completion dates and metadata
- Retained based on tiered retention policy (see Data Retention)

### App Settings
- Theme preferences (light/dark mode)
- Accent color choices
- Notification settings
- Display preferences

## iCloud Sync (Optional)

### How It Works

DaisyDos uses Apple's CloudKit framework to optionally sync your data across your devices. This feature is:

- **Disabled by default** - You must explicitly enable it in Settings
- **Uses your personal iCloud account** - Data syncs to your private iCloud storage
- **Private to you** - Data is stored in your personal private database within the app's CloudKit container, accessible only through your Apple ID
- **Can be disabled anytime** - Turn off sync in Settings at any time

### What Gets Synced

When you enable iCloud sync, the following data is synchronized to your private iCloud storage:
- All tasks, habits, and tags
- Photo attachments
- Completion history and analytics data
- App settings and preferences

### What We Cannot Access

When you use iCloud sync:
- Your data is stored in **your personal iCloud account**, not on our servers
- We (the app developers) have **no access** to your iCloud data
- Only you can access this data through your Apple ID
- Apple's iCloud Privacy Policy governs how your iCloud data is handled

### Offline Mode

- DaisyDos works completely offline
- Changes made offline are queued and synced when you reconnect
- You can use the app with iCloud sync disabled indefinitely

## Photo Attachments

When you attach photos to tasks or habits:
- Photos are stored locally on your device
- If iCloud sync is enabled, photos sync to your personal iCloud storage
- Photos are never uploaded to our servers
- You control which photos to attach (the app requests limited photo access)

## Notifications

DaisyDos uses local notifications to remind you about tasks and habits:
- All notifications are generated **locally on your device**
- No data is sent to external servers for notifications
- You control notification permissions through iOS Settings
- Notification preferences are stored locally (and synced via iCloud if enabled)

## Permissions

DaisyDos may request the following iOS permissions:

| Permission | Purpose | Required? |
|------------|---------|-----------|
| Photo Library | Attach photos to tasks and habits | Only for attachments |
| Notifications | Remind you about tasks and habits | Only for reminders |
| iCloud | Sync data across your devices | Only if you enable sync |

You can manage these permissions in iOS Settings at any time.

## Data Retention

### Active Data

Tasks and habits remain on your device until you delete them. You can delete individual items or all data through the app.

### Logbook (Completion History)

DaisyDos uses automatic tiered retention for completed task history:
- **0-90 days:** Full task details retained
- **91-365 days:** Summarized completion records (TaskLogEntry)
- **365+ days:** Automatically deleted

You can manually delete logbook entries at any time.

### When You Delete Data

- Deleted items are removed from your device immediately
- If iCloud sync is enabled, deletions sync across your devices
- Deleted data cannot be recovered (unless you have a device backup)

## Data Export and Deletion

### Export Your Data

You can export all your data from Settings. This supports your rights under GDPR (data portability) and CCPA (right to know):
- Export includes tasks, habits, tags, and completion history
- Data is exported in a standard format
- Exported files remain on your device until you delete them

### Delete All Data

You can delete all your data from Settings:
- Removes all tasks, habits, tags, and history
- Cannot be undone (unless you have a device backup)
- If iCloud sync is enabled, deletion syncs across your devices

## Third-Party Code and Services

### What We Use

DaisyDos is built exclusively with Apple's native frameworks:
- **SwiftUI** - User interface
- **SwiftData** - Local data storage
- **CloudKit** - Optional iCloud sync (only if you enable it)
- **PhotosUI** - Photo attachment picker (only accesses photos you select)
- **UserNotifications** - Local reminder notifications

### What We Do NOT Use

DaisyDos contains **no third-party code** for:
- Analytics or crash reporting
- Advertising or ad networks
- Social media integrations
- User tracking or profiling
- Data brokers or processors

This means your data never leaves Apple's ecosystem.

## Children's Privacy

DaisyDos does not knowingly collect information from children under 13. The app:
- Does not require account creation
- Stores all data locally by default
- Contains no advertising or in-app purchases targeting children

Parents should supervise their children's use of the app.

## Data Security

- All data stored locally on your device is protected by iOS's built-in security features
- If you use device encryption (iOS default), your DaisyDos data is encrypted at rest
- iCloud sync uses Apple's CloudKit encryption (data encrypted in transit and at rest)
- We do not transmit your data over the internet except through Apple's iCloud service (if enabled)

## Your Privacy Rights

### California Residents (CCPA)

You have the right to:
- **Know** what personal information is collected (see "What Data the App Stores Locally")
- **Delete** your personal information (available in Settings)
- **Opt-out** of data sales (we never sell your data)
- **Non-discrimination** for exercising your privacy rights

### European Residents (GDPR)

You have the right to:
- **Access** your personal data (export available in Settings)
- **Rectify** inaccurate data (edit any item in the app)
- **Erase** your data (delete options in Settings)
- **Data portability** (export feature)
- **Restrict processing** (disable iCloud sync)
- **Object** to processing (you control all data storage)

Since DaisyDos stores data locally by default and uses only your personal iCloud account (when enabled), you have complete control over your data without needing to contact us.

**Legal Basis for Processing (GDPR):**
- **Consent:** You choose to use the app and enable features like iCloud sync
- **Legitimate Interest:** Storing data locally to provide app functionality

## No Tracking

DaisyDos does not:
- Use cookies or tracking technologies
- Collect advertising identifiers (IDFA)
- Track your location
- Monitor your app usage patterns
- Build user profiles
- Share data with advertisers or data brokers
- Use App Tracking Transparency (because we don't track)

## Changes to This Policy

We may update this Privacy Policy occasionally. When we do:
- The "Last Updated" date will be revised
- Significant changes will be communicated through app updates
- Continued use of the app constitutes acceptance of changes

## Your Rights Summary

You have the right to:
- Use the app completely offline
- Keep all data local (never sync to cloud)
- Choose which photos to attach
- Control notification permissions
- Export all your data
- Delete all your data
- Disable iCloud sync at any time
- Understand exactly what data is stored

## Contact Information

If you have questions about this Privacy Policy or your data:

**Email:** daisydosprivacy@gmail.com
**Online:** https://dantejvv.github.io/

For issues related to iCloud sync or Apple services, please contact Apple Support.

## Questions or Concerns

We take privacy seriously. If you have any questions about how your data is handled, please contact us at the information provided above.

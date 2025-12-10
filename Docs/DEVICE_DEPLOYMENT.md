# DaisyDos - iPhone Deployment Guide

This guide will help you install and test DaisyDos on your personal iPhone for development testing.

## Prerequisites

- ✅ **Mac with Xcode installed** (latest version recommended)
- ✅ **Apple Developer account** (enrolled - $99/year)
- ✅ **iPhone with iOS 17.0 or later**
- ✅ **USB cable** (Lightning or USB-C depending on iPhone model)

## Build Status

- ✅ **Build Fixed**: SettingsView.swift type-checking error resolved
- ✅ **Build Verified**: App compiles successfully on simulator
- ✅ **Permissions Complete**: All required Info.plist descriptions added
- ✅ **Code Signing**: Automatic signing configured with team BKD7HH7ZDH

## Step-by-Step Installation

### 1. Open the Project in Xcode

```bash
cd /Users/dante/Dev/DaisyDos
open DaisyDos.xcodeproj
```

Or double-click `DaisyDos.xcodeproj` in Finder.

### 2. Connect Your iPhone

1. Connect your iPhone to your Mac using a USB cable
2. **Unlock your iPhone**
3. If prompted on your iPhone, tap **"Trust This Computer"**
4. Enter your iPhone passcode if requested

### 3. Select Your iPhone as the Build Destination

1. In Xcode, look at the top toolbar near the Run button
2. Click the device dropdown (currently shows "iPhone 16" simulator)
3. Select your physical iPhone from the list (it will show your iPhone's name)

### 4. Verify Signing Configuration

1. In Xcode's left sidebar, select the **DaisyDos project** (blue icon at the top)
2. Select the **DaisyDos target** in the center panel
3. Click the **"Signing & Capabilities"** tab
4. Verify the following:
   - ✅ "Automatically manage signing" is **checked**
   - ✅ Team: **BKD7HH7ZDH** (your development team)
   - ✅ Bundle Identifier: **dante.DaisyDos**
   - ✅ Status shows "Signing Certificate: Apple Development"

If you see any yellow warnings about provisioning profiles, Xcode should automatically resolve them.

### 5. Build and Run on Your iPhone

**Option A: Using Xcode UI**
1. Click the **Play button (▶️)** in the top-left corner of Xcode
2. Or press **⌘R** (Command + R)

**Option B: Using Command Line**
```bash
xcodebuild -scheme DaisyDos -destination 'platform=iOS,name=YOUR_IPHONE_NAME' build
```

### 6. Trust Developer Certificate (First Time Only)

When you first install an app from Xcode on your iPhone, you need to trust your developer certificate:

1. On your iPhone, you'll see an alert: **"Untrusted Developer"**
2. Go to: **Settings** → **General** → **VPN & Device Management** (or **Device Management**)
3. Under "Developer App", tap your **Apple ID** or **developer certificate**
4. Tap **"Trust [Your Apple ID]"**
5. Confirm by tapping **"Trust"**

### 7. Launch DaisyDos

- The app will automatically launch on your iPhone after building
- If it doesn't, find the **DaisyDos icon** on your home screen and tap it

## Expected App Behavior

### First Launch
- App opens to the **Today** tab (unified daily view)
- No data present (clean slate)
- All 5 tabs visible: Today, Tasks, Habits, Logbook, Settings

### Permissions Prompts
You may be asked to grant permissions for:
- 📸 **Camera** - For taking photos to attach to tasks/habits
- 🖼️ **Photo Library** - For selecting photos from your library
- 🔔 **Notifications** - For habit reminders
- 📅 **Calendar** - For calendar integration (not yet implemented)
- ✅ **Reminders** - For reminders integration (not yet implemented)

**Note**: You can grant or deny these. Only Camera, Photos, and Notifications are currently used.

### Features to Test

#### Tasks
- ✅ Create new tasks with title, description, priority
- ✅ Add due dates and recurrence patterns
- ✅ Create subtasks (one level)
- ✅ Attach photos from library or camera
- ✅ Add up to 5 tags per task
- ✅ Mark complete, edit, delete, duplicate
- ✅ Multi-select and bulk operations

#### Habits
- ✅ Create habits with title, description, frequency
- ✅ Daily subtasks that reset each day
- ✅ Photo attachments
- ✅ Mark complete, skip with reason, undo
- ✅ Streak tracking
- ✅ Tags (up to 5 per habit)

#### Tags
- ✅ Create up to 30 tags system-wide
- ✅ SF Symbol icons and system colors
- ✅ Manage from Settings → Tags

#### Today View
- ✅ Unified list of today's tasks and habits
- ✅ Sort by time, priority, type, or title
- ✅ Toggle show/hide completed items
- ✅ Quick actions: complete, edit, delete, duplicate, skip

#### Settings
- ✅ Local-only mode (default) vs. iCloud sync
- ✅ Theme: System, Light, or Dark
- ✅ Accent color selection
- ✅ Habit notification settings
- ✅ Import/Export data
- ✅ Reset & Delete options

## Troubleshooting

### Build Failed: Code Signing Error

**Error**: "No matching provisioning profile found"

**Solution**:
1. Go to **Signing & Capabilities** tab
2. Uncheck "Automatically manage signing"
3. Re-check "Automatically manage signing"
4. Xcode will regenerate the provisioning profile

### Build Failed: Device Not Found

**Error**: "No devices found for destination"

**Solution**:
1. Ensure iPhone is unlocked
2. Disconnect and reconnect USB cable
3. Trust the computer on your iPhone
4. In Xcode: Window → Devices and Simulators → Verify iPhone appears

### App Won't Launch: "Untrusted Developer"

**Solution**: Follow step 6 above to trust your developer certificate.

### CloudKit Sync Not Working

**Expected Behavior**: CloudKit sync is **disabled by default** (local-only mode).

To enable:
1. Open DaisyDos on your iPhone
2. Go to **Settings** tab
3. Toggle **"Local-Only Mode"** OFF
4. **Restart the app**
5. Verify you're signed into iCloud on your iPhone

**Note**: CloudKit requires app restart when toggling sync mode.

### Notifications Not Working

1. Go to **Settings** → **Notifications** → **DaisyDos**
2. Verify **"Allow Notifications"** is enabled
3. In DaisyDos app: **Settings** → **Habit Reminders**
4. Enable notifications and set reminder times

**Note**: Basic notification infrastructure is complete, but advanced smart scheduling for all edge cases is still in development.

## Performance Testing

### Recommended Tests

1. **Create 10-20 tasks** - Test UI responsiveness
2. **Create 5-10 habits** - Test streak calculations
3. **Add subtasks** - Test one-level hierarchy
4. **Attach photos** - Test 50MB file limit
5. **Create tags** - Test 5-tag-per-item and 30-tag system limits
6. **Test recurrence** - Create daily, weekly, monthly habits/tasks
7. **Test multi-select** - Bulk complete/delete in Today view
8. **Test search** - Search tasks, habits, logbook
9. **Toggle themes** - Test Light/Dark/System appearance
10. **Test offline** - Enable Airplane Mode, verify local-only mode works

### Known Limitations (MVP)

- ⚠️ **No onboarding flow** - App jumps straight to Today tab
- ⚠️ **Task notifications incomplete** - No due date reminders yet
- ⚠️ **Calendar integration incomplete** - Permissions exist but no functionality
- ⚠️ **Analytics incomplete** - No charts or progress visualization
- ⚠️ **CloudKit requires restart** - Changing sync mode requires app restart

## Development Build Info

- **Bundle ID**: dante.DaisyDos
- **Team ID**: BKD7HH7ZDH
- **Version**: 1.0.0 Beta
- **Target iOS**: 17.0+
- **Build Configuration**: Debug
- **Signing**: Automatic (Development)

## Next Steps After Testing

Once you've tested the core functionality on your iPhone and confirmed everything works:

1. **Document any bugs or issues** you encounter
2. **Test all critical user flows**:
   - Creating and completing tasks
   - Building habit streaks
   - Using tags across features
   - Switching between themes
3. **Verify performance** with realistic data volumes
4. **Test edge cases** (network changes, low storage, etc.)

When you're satisfied with device testing, we can proceed with:
- Public App Store release preparation
- TestFlight beta testing setup
- App Store metadata and screenshots
- Privacy policy and legal documents

## Support

For issues during device testing:
- Check Xcode's console output for error messages
- Check iPhone's Settings → General → iPhone Storage (verify app installed)
- Verify you're using iOS 17.0 or later on your iPhone

---

**Ready to test!** Follow the steps above to install DaisyDos on your iPhone. 📱✨

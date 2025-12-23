# Google Sign-In Setup Instructions

## ✅ Completed Steps

1. ✅ Xcode project created (`FairShare.xcodeproj`)
2. ✅ Google Sign-In SDK added via Swift Package Manager
3. ✅ Google Sign-In initialization code added to `FairShareApp.swift`
4. ✅ URL scheme configuration added to `Info.plist`

## 🔧 Remaining Configuration

### Step 1: Get Your Google Client ID

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to **APIs & Services** > **Credentials**
3. Create a new **OAuth 2.0 Client ID** with application type set to **iOS**
4. Copy your Client ID (format: `123456789-abcdefghijklmnop.apps.googleusercontent.com`)

### Step 2: Configure Client ID in Code

1. Open `FairShareApp.swift` in Xcode
2. Find the line: `let clientId = "YOUR_CLIENT_ID_HERE.apps.googleusercontent.com"`
3. Replace `YOUR_CLIENT_ID_HERE` with your actual Client ID

### Step 3: Configure URL Scheme in Info.plist

1. Open `Info.plist` in Xcode
2. Find the `CFBundleURLTypes` section
3. Locate the URL scheme value: `YOUR_REVERSED_CLIENT_ID_HERE`
4. Replace it with your reversed Client ID:
   - If your Client ID is: `123456789-abcdefgh.apps.googleusercontent.com`
   - Your reversed Client ID is: `com.googleusercontent.apps.123456789-abcdefgh`

### Step 4: Build and Run

1. Select an iOS 18+ simulator or device
2. Press **Cmd+R** to build and run
3. Test Google Sign-In functionality

## 📝 Notes

- The Google Sign-In SDK (version 7.1.0) has been automatically resolved
- All Swift files are included in the project
- The project is configured for iOS 18.0+ deployment target
- Bundle identifier is set to `com.fairshare.app`


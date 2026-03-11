# Codemagic CI/CD Setup

This guide will walk you through setting up Codemagic CI/CD for the Grate Genyen Raffle Flutter app to automatically build and deploy Android and iOS applications.

## 1. Connect Repository

1. Go to https://codemagic.io
2. Sign in with GitHub
3. Click "Add application" from the dashboard
4. Select your repository: `dukens11-create/raffleapp`
5. When prompted, select "Use codemagic.yaml" configuration
6. Codemagic will automatically detect the `codemagic.yaml` file in your repository
7. You should see three workflows available:
   - **Android Build** - Builds APK and AAB for Google Play
   - **iOS Build** - Builds IPA for App Store
   - **Development Build** - Quick debug builds with tests

## 2. Configure Environment Variables

In the Codemagic dashboard, you need to set up environment variables for signing and publishing.

### How to Add Variables:

1. Go to your app in Codemagic dashboard
2. Click on "Settings" → "Environment variables"
3. Create variable groups as described below

### Android Variables (android_credentials group):

Create a group named `android_credentials` and add these variables:

| Variable Name | Description | Secure |
|--------------|-------------|--------|
| `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS` | Google Play service account JSON (for publishing) | ✅ Yes |
| `FCI_KEYSTORE` | Your Android keystore file (base64 encoded) | ✅ Yes |
| `FCI_KEYSTORE_PASSWORD` | Keystore password | ✅ Yes |
| `FCI_KEY_ALIAS` | Key alias name | ❌ No |
| `FCI_KEY_PASSWORD` | Key password | ✅ Yes |

### iOS Variables (ios_credentials group):

Create a group named `ios_credentials` and add these variables:

| Variable Name | Description | Secure |
|--------------|-------------|--------|
| `APP_STORE_CONNECT_KEY_IDENTIFIER` | App Store Connect API key ID | ❌ No |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID from App Store Connect | ❌ No |
| `APP_STORE_CONNECT_PRIVATE_KEY` | Private key content (.p8 file) | ✅ Yes |
| `CERTIFICATE_PRIVATE_KEY` | Certificate private key | ✅ Yes |

### Common Variables:

These are set directly in the workflow file but can be overridden:

| Variable Name | Default Value | Description |
|--------------|---------------|-------------|
| `API_BASE_URL` | `https://grategenyen.com` | Backend API endpoint |

## 3. Android Signing Setup

### Step 1: Generate Keystore (if you don't have one)

```bash
keytool -genkey -v -keystore raffleapp.keystore \
  -alias raffleapp \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

You'll be prompted to enter:
- Keystore password (remember this!)
- Key password (remember this!)
- Your name and organization details

### Step 2: Convert Keystore to Base64

```bash
cat raffleapp.keystore | base64 > keystore_base64.txt
```

Or on macOS:
```bash
cat raffleapp.keystore | base64 -o keystore_base64.txt
```

### Step 3: Add to Codemagic

1. Open `keystore_base64.txt` and copy the entire content
2. In Codemagic, go to Environment variables
3. Add `FCI_KEYSTORE` as a secure variable
4. Paste the base64 content
5. Add `FCI_KEYSTORE_PASSWORD`, `FCI_KEY_ALIAS`, and `FCI_KEY_PASSWORD` with your values

### Step 4: Google Play Publishing (Optional)

To enable automatic publishing to Google Play:

1. Create a Google Cloud service account
2. Download the JSON key file
3. In Google Play Console, grant access to the service account
4. Convert the JSON to base64:
   ```bash
   cat service-account.json | base64 > gcloud_credentials.txt
   ```
5. Add to Codemagic as `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS`

## 4. iOS Signing Setup

### Option A: Automatic Code Signing (Recommended)

1. In Codemagic dashboard, go to your app settings
2. Navigate to "Code signing identities" → "iOS"
3. Click "Add certificate"
4. Follow the wizard to:
   - Upload or generate your certificate
   - Upload or download provisioning profiles
   - Codemagic will automatically manage signing

### Option B: Manual Code Signing

1. **Create App Store Connect API Key:**
   - Go to App Store Connect → Users and Access → Keys
   - Generate a new API key
   - Download the `.p8` file
   - Note the Key ID and Issuer ID

2. **Add to Codemagic:**
   ```bash
   # Convert .p8 to base64
   cat AuthKey_XXXXXXXXXX.p8 | base64 > api_key.txt
   ```
   
3. Add the following to Codemagic environment variables:
   - `APP_STORE_CONNECT_KEY_IDENTIFIER`: Your Key ID
   - `APP_STORE_CONNECT_ISSUER_ID`: Your Issuer ID
   - `APP_STORE_CONNECT_PRIVATE_KEY`: Content of api_key.txt

4. **Certificate and Provisioning Profile:**
   - Export your certificate as .p12
   - Convert to base64 and add as `CERTIFICATE_PRIVATE_KEY`
   - Or use Codemagic's automatic signing feature

## 5. Trigger Builds

### Automatic Builds:

Builds can be triggered automatically based on repository events:

1. Go to your app settings in Codemagic
2. Navigate to "Build triggers"
3. Enable automatic builds for:
   - Push to `main` branch → Triggers Android and iOS workflows
   - Pull requests → Triggers Development workflow
   - Specific branches or tags

### Manual Builds:

1. Go to Codemagic dashboard
2. Select your app
3. Click "Start new build"
4. Choose the workflow (Android, iOS, or Development)
5. Select the branch
6. Click "Start new build"

### Build Configuration:

Each workflow has different build durations:
- **Android Build**: 60 minutes max
- **iOS Build**: 60 minutes max
- **Development Build**: 30 minutes max

## 6. Download Artifacts

### From Codemagic Dashboard:

1. Go to your app in Codemagic
2. Click on a completed build
3. Scroll to "Artifacts" section
4. Download:
   - **Android**: `.apk` and `.aab` files
   - **iOS**: `.ipa` file

### Via Email:

- You'll receive email notifications at the configured email address (e.g., `dukens11@example.com`)
  - *Note: Update this email in `codemagic.yaml` to your actual email address*
- Emails include:
  - Build status (success/failure)
  - Direct download links to artifacts
  - Build logs for debugging

### Artifact Locations:

After a successful build, artifacts are available at:
- Android APK: `flutter_app/build/app/outputs/**/*.apk`
- Android AAB: `flutter_app/build/app/outputs/**/*.aab`
- iOS IPA: `flutter_app/build/ios/**/*.ipa`

## 7. Publishing to Stores

### Google Play Store (Android):

If Google Play publishing is configured:
1. Builds are automatically published to the **internal track**
2. You can promote from internal → alpha → beta → production in Google Play Console
3. To change the track, edit `codemagic.yaml`:
   ```yaml
   google_play:
     track: internal  # or alpha, beta, production
   ```

### Apple App Store (iOS):

If App Store Connect is configured:
1. Builds are automatically uploaded to App Store Connect
2. You can submit for review in App Store Connect
3. TestFlight builds are available automatically

## 8. Troubleshooting

### Build Fails: "Keystore not found"

- Ensure `FCI_KEYSTORE` is properly base64 encoded
- Check that the variable is marked as "Secure"
- Verify the keystore is not corrupted

### Build Fails: "Wrong keystore password"

- Double-check `FCI_KEYSTORE_PASSWORD` and `FCI_KEY_PASSWORD`
- Ensure no extra spaces or newlines in the values

### iOS Build Fails: "Code signing error"

- Verify certificates and provisioning profiles are valid
- Check that they match your app's bundle identifier
- Use Codemagic's automatic signing feature for easier setup

### Tests Fail in Development Workflow

- Check test logs in the build details
- Tests run with `flutter test` command
- Ensure all tests pass locally before pushing

### API Connection Issues

- Verify `API_BASE_URL` is set correctly: `https://grategenyen.com`
- Check that the backend is accessible from the internet
- Review app logs for connection errors

## 9. Best Practices

### Security:

- ✅ Always mark sensitive variables as "Secure"
- ✅ Never commit keystores or certificates to Git
- ✅ Rotate API keys and passwords regularly
- ✅ Use different keystores for development and production

### Workflow Optimization:

- Use **Development workflow** for quick validation
- Run **Android workflow** for Play Store releases
- Run **iOS workflow** for App Store releases
- Consider combining workflows only if needed

### Version Management:

1. Update version in `pubspec.yaml`:
   ```yaml
   version: 1.0.0+1
   ```
2. Commit and push
3. Tag the release:
   ```bash
   git tag -a v1.0.0 -m "Release version 1.0.0"
   git push origin v1.0.0
   ```
4. Codemagic can be configured to build on tags

## 10. Additional Resources

- [Codemagic Documentation](https://docs.codemagic.io/)
- [Flutter Build Guide](https://docs.flutter.dev/deployment)
- [Google Play Publishing](https://support.google.com/googleplay/android-developer/)
- [App Store Connect](https://developer.apple.com/app-store-connect/)

## Support

For issues or questions:
1. Check build logs in Codemagic dashboard
2. Review this documentation
3. Check [Codemagic Community](https://community.codemagic.io/)
4. Contact your development team

## Troubleshooting

### Build fails with "Provided Google Play service account credentials could not be used"

**Error:**
```
Provided Google Play service account credentials could not be used: Expecting value: line 1 column 1 (char 0)
```

**Cause:** The `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS` environment variable is not properly configured.

**Solutions:**

1. **Quick fix (disable Play Store publishing):**
   - Comment out the `google_play` section in `codemagic.yaml`
   - Builds will succeed and produce APK/AAB artifacts you can download manually
   - You can still distribute via other channels

2. **Proper fix (enable Play Store publishing):**
   - Follow Step 4 in the Android setup above to create service account
   - Ensure the JSON is valid (test with `cat service-account.json | jq .`)
   - Convert to base64: `cat service-account.json | base64 > gcloud_credentials.txt`
   - Copy the ENTIRE base64 output (including all lines)
   - Add to Codemagic as `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS` in the `android_credentials` group
   - Mark as secure
   - Uncomment the `google_play` section in `codemagic.yaml`
   - Trigger a new build

**Verify credentials are set:**
- Go to Codemagic dashboard → Your App → Environment variables
- Check that `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS` exists in `android_credentials` group
- Verify it's marked as secure (shows as masked)
- Ensure it's not empty

### Build succeeds but Google Play publishing fails

- Verify the service account has "Release Manager" role in Google Play Console
- Check that the app exists in Google Play Console (create it first if needed)
- Ensure the internal testing track is set up
- Review Codemagic logs for specific Google Play API errors

---

**Last Updated:** 2026-02-17

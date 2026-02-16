# Local Plugins

This directory contains locally vendored Flutter plugins that have been modified to work with this project.

## qr_code_scanner

**Version:** 1.0.1  
**Source:** https://pub.dev/packages/qr_code_scanner/versions/1.0.1  
**Date Vendored:** February 15, 2026

### Why This Plugin is Vendored Locally

The `qr_code_scanner` package version 1.0.1 from pub.dev contains a deprecated `package` attribute in its `android/src/main/AndroidManifest.xml` file. This attribute is no longer supported in modern Android Gradle Plugin versions and causes build failures with the following error:

```
Incorrect package="net.touchcapture.qr.flutterqr" found in source AndroidManifest.xml.
Setting the namespace via the package attribute in the source AndroidManifest.xml is no longer supported.
```

### Modifications Made

The following line was **removed** from `android/src/main/AndroidManifest.xml`:

```xml
<!-- REMOVED: package="net.touchcapture.qr.flutterqr" -->
```

The AndroidManifest.xml now correctly omits the deprecated package attribute, as the namespace is instead declared in the Android module's `build.gradle` file.

### Migration Path

This is a **temporary workaround**. The plugin should be updated when:

1. A newer version of `qr_code_scanner` is released that fixes this issue
2. The project migrates to an alternative QR scanning package (e.g., `mobile_scanner`, which is already a dependency)

### Maintenance

If you need to clean and rebuild:

```bash
flutter clean
flutter pub get
flutter build apk --release
```

The local path dependency in `pubspec.yaml` ensures the modified version is always used:

```yaml
qr_code_scanner:
  path: ../local_plugins/qr_code_scanner
```

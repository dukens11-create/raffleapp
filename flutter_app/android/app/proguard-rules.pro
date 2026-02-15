# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# Keep all Stripe Android SDK classes
-keep class com.stripe.android.** { *; }
-dontwarn com.stripe.android.**

# Stripe push provisioning classes
-keep class com.stripe.android.pushProvisioning.** { *; }

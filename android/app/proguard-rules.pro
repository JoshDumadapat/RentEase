# Add project specific ProGuard rules here.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase Auth rules
-keep class com.google.firebase.auth.** { *; }
-keep class com.google.android.gms.** { *; }

# Suppress resource warnings (harmless Firebase Auth resource access warnings)
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}


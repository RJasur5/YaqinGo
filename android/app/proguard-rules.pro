# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Background Service
-keep class id.flutter.flutter_background_service.** { *; }

# Geolocator
-keep class com.baseflow.geolocator.** { *; }

# Flutter local notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Keep all model classes (to avoid R8 removing needed classes)
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions

# WebSocket / OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

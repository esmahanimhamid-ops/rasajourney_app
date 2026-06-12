# Unity AR Foundation Android Integration for RasaJourney

This guide prepares a Unity AR Foundation Android scene that launches from the Flutter `AR` tab and shows a floating restaurant info card when the camera opens.

## 1. Unity Project Setup

Recommended starting point:
- Unity project type: `3D (Built-In Render Pipeline)`
- Target platform: `Android`
- Scene name: `RasaJourneyAR`

Install these Unity packages:
- `AR Foundation`
- `ARCore XR Plugin`
- `TextMeshPro`

Files already scaffolded in this repo:
- [unity/rasa_journey_ar/README.md](../unity/rasa_journey_ar/README.md)
- [unity/rasa_journey_ar/Assets/Scenes/SceneSetup.md](../unity/rasa_journey_ar/Assets/Scenes/SceneSetup.md)
- [unity/rasa_journey_ar/Assets/Scripts/ARFloatingCardSpawner.cs](../unity/rasa_journey_ar/Assets/Scripts/ARFloatingCardSpawner.cs)
- [unity/rasa_journey_ar/Assets/Scripts/RestaurantInfoCardController.cs](../unity/rasa_journey_ar/Assets/Scripts/RestaurantInfoCardController.cs)
- [unity/rasa_journey_ar/Assets/Scripts/RestaurantCardPayload.cs](../unity/rasa_journey_ar/Assets/Scripts/RestaurantCardPayload.cs)
- [unity/rasa_journey_ar/Assets/Scripts/FaceCameraBillboard.cs](../unity/rasa_journey_ar/Assets/Scripts/FaceCameraBillboard.cs)
- [unity/rasa_journey_ar/Assets/Scripts/FlutterUnityBridge.cs](../unity/rasa_journey_ar/Assets/Scripts/FlutterUnityBridge.cs)

## 2. Scene Behavior

What the scene does:
- waits for AR tracking
- spawns a floating restaurant info card about 1.2 meters in front of the camera
- reads restaurant text passed from Flutter through Android intent extras
- keeps the card facing the user

Suggested card UI fields:
- restaurant name
- cuisine label
- status
- operating hours
- rating
- short subtitle

## 3. Unity Android Player Settings

Set these in Unity before export:
- `File > Build Settings > Android > Switch Platform`
- `Player Settings > Other Settings > Auto Graphics API`: off
- Remove `Vulkan` from Graphics APIs for ARCore compatibility
- `Minimum API Level`: `Android 7.0 (API 24)` or higher for AR Required
- `Scripting Backend`: `IL2CPP`
- `Target Architectures`: enable `ARM64`
- Add camera usage description where needed

## 4. Export Unity as an Android Gradle Project

In Unity:
1. Open `Build Settings`
2. Choose `Android`
3. Enable `Export Project`
4. Build to a folder outside the Flutter app first, for example:
   - `C:\unity_exports\rasajourney_ar_android`

Unity will generate:
- `launcher`
- `unityLibrary`

Only `unityLibrary` needs to be embedded into the Flutter Android host.

## 5. Copy Unity Export into Flutter

After export:
1. Copy Unity's `unityLibrary` into:
   - `android/unityLibrary`
2. Do not overwrite the Flutter `app` module.

## 6. Update Flutter Android Gradle

Edit [android/settings.gradle.kts](../android/settings.gradle.kts) and add:

```kotlin
include(":unityLibrary")
project(":unityLibrary").projectDir = file("unityLibrary")
```

Edit [android/app/build.gradle.kts](../android/app/build.gradle.kts) and add inside `dependencies`:

```kotlin
dependencies {
    implementation(project(":unityLibrary"))
}
```

If your `build.gradle.kts` has no `dependencies` block yet, create one near the bottom of the file.

## 7. Add Unity Host Activity

Copy this template into the compiled Android source tree after `unityLibrary` exists:
- [unity/rasa_journey_ar/AndroidTemplates/UnityARActivity.kt](../unity/rasa_journey_ar/AndroidTemplates/UnityARActivity.kt)

Suggested destination:
- `android/app/src/main/kotlin/com/esmahanim/rasajourney_app/unity/UnityARActivity.kt`

Then add the manifest activity entry from:
- [unity/rasa_journey_ar/AndroidTemplates/AndroidManifest.unity-snippet.xml](../unity/rasa_journey_ar/AndroidTemplates/AndroidManifest.unity-snippet.xml)

into:
- [android/app/src/main/AndroidManifest.xml](../android/app/src/main/AndroidManifest.xml)

## 8. Flutter Integration Already Added

The Flutter app now includes:
- [lib/services/unity_ar_service.dart](../lib/services/unity_ar_service.dart)
- [lib/screens/ar_screen.dart](../lib/screens/ar_screen.dart)
- [android/app/src/main/kotlin/com/esmahanim/rasajourney_app/MainActivity.kt](../android/app/src/main/kotlin/com/esmahanim/rasajourney_app/MainActivity.kt)

What this gives you:
- the `AR` tab shows a Unity AR preview launcher
- Flutter sends text payload values like restaurant name and hours
- Android tries to start `com.esmahanim.rasajourney_app.unity.UnityARActivity`
- Unity reads those values through `FlutterUnityBridge`

## 9. Passing Real Restaurant Data Later

Right now the Flutter AR screen launches with demo payload text.

To pass real restaurant data:
1. Navigate to `ARScreen` with a selected restaurant
2. Build a `UnityARPayload` from Firestore data
3. Call `UnityARService().launch(payload)`

Suggested payload mapping:
- `restaurantName` -> Firestore `name`
- `status` -> Firestore `status`
- `hours` -> one joined line from `operatingHours`
- `rating` -> formatted string from `rating`
- `subtitle` -> short review or cuisine description

## 10. Important Runtime Notes

Unity as a Library limitations that matter here:
- full-screen only
- only one Unity runtime instance
- plugin compatibility may require extra work after export

That means your Flutter `AR` tab should launch Unity full-screen rather than trying to embed it into only part of the page.

## 11. Suggested Next Steps

After the first Unity export is connected:
1. replace the demo payload with a selected Firestore restaurant
2. add a close button inside the Unity card that calls `FlutterUnityBridge.UnloadToHost()`
3. optionally add a 3D food icon or dish model next to the card
4. add tap-to-respawn behavior so the card can be repositioned in front of the user

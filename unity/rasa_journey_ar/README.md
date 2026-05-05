# RasaJourney Unity AR Scaffold

This folder contains a Unity AR Foundation scaffold for the RasaJourney Android app.

Recommended Unity setup:
- Create a new Unity Android project using the Built-In Render Pipeline.
- Install Android Build Support from Unity Hub.
- In Package Manager, install:
  - `AR Foundation`
  - `ARCore XR Plugin`
  - `TextMeshPro`

Recommended scene name:
- `Assets/Scenes/RasaJourneyAR.unity`

Recommended scene hierarchy:
- `AR Session`
- `XR Origin (AR)`
  - `Camera Offset`
    - `Main Camera`
- `AR Scene Root`
  - `ARFloatingCardSpawner`
- `UI`
  - `Canvas` for optional close button

Recommended prefab:
- `Assets/Prefabs/RestaurantInfoCard.prefab`
  - World-space canvas
  - Rounded background panel
  - TextMeshPro labels for:
    - Restaurant title
    - Cuisine label
    - Status
    - Hours
    - Rating
    - Subtitle
  - `RestaurantInfoCardController`
  - `FaceCameraBillboard`

Scripts in this folder:
- `ARFloatingCardSpawner.cs`
- `RestaurantCardPayload.cs`
- `RestaurantInfoCardController.cs`
- `FaceCameraBillboard.cs`
- `FlutterUnityBridge.cs`

Android integration templates:
- `AndroidTemplates/UnityARActivity.kt`
- `AndroidTemplates/AndroidManifest.unity-snippet.xml`

Full integration steps:
- See [docs/unity_ar_foundation_android.md](../../docs/unity_ar_foundation_android.md)

# Scene Setup

Create a Unity scene named `RasaJourneyAR`.

1. Delete the default camera.
2. Add `XR > AR Session`.
3. Add `XR > XR Origin (AR)`.
4. On the `Main Camera` inside `XR Origin`, add:
   - `AR Camera Manager`
   - `AR Camera Background`
   - `Audio Listener`
5. Create an empty object named `AR Scene Root`.
6. Add `ARFloatingCardSpawner` to `AR Scene Root`.
7. Assign the `Main Camera` and the `RestaurantInfoCard` prefab to the spawner.
8. Build a world-space card prefab with TextMeshPro labels and assign them to `RestaurantInfoCardController`.

Behavior:
- When the AR scene opens and tracking starts, the card spawns about 1.2 meters in front of the camera.
- The card reads payload values passed from Flutter through Android intent extras.
- The card faces the user with a simple billboard script.

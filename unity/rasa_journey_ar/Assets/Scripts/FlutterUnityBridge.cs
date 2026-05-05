using UnityEngine;

public static class FlutterUnityBridge
{
    public static RestaurantCardPayload ReadPayload()
    {
        var payload = RestaurantCardPayload.Demo();

#if UNITY_ANDROID && !UNITY_EDITOR
        try
        {
            using var unityPlayer = new AndroidJavaClass("com.unity3d.player.UnityPlayer");
            using var currentActivity = unityPlayer.GetStatic<AndroidJavaObject>("currentActivity");
            using var intent = currentActivity.Call<AndroidJavaObject>("getIntent");

            payload.restaurantName = ReadStringExtra(intent, "restaurantName", payload.restaurantName);
            payload.cuisineLabel = ReadStringExtra(intent, "cuisineLabel", payload.cuisineLabel);
            payload.status = ReadStringExtra(intent, "status", payload.status);
            payload.hours = ReadStringExtra(intent, "hours", payload.hours);
            payload.rating = ReadStringExtra(intent, "rating", payload.rating);
            payload.subtitle = ReadStringExtra(intent, "subtitle", payload.subtitle);
        }
        catch (System.Exception error)
        {
            Debug.LogWarning($"FlutterUnityBridge payload read failed: {error.Message}");
        }
#endif

        return payload;
    }

    public static void UnloadToHost()
    {
        Application.Unload();
    }

    private static string ReadStringExtra(
        AndroidJavaObject intent,
        string key,
        string fallback
    )
    {
        if (intent == null)
        {
            return fallback;
        }

        var value = intent.Call<string>("getStringExtra", key);
        return string.IsNullOrWhiteSpace(value) ? fallback : value;
    }
}

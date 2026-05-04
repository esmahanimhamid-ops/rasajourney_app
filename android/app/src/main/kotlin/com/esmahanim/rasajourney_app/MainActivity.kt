package com.esmahanim.rasajourney_app

import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val configChannel = "rasajourney/config"
    private val unityArChannel = "rasajourney/unity_ar"
    private val unityArActivityName = "com.esmahanim.rasajourney_app.unity.UnityARActivity"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, configChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getMapsApiKey" -> result.success(getMapsApiKey())
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, unityArChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isUnityArAvailable" -> result.success(isUnityArAvailable())
                    "launchUnityAr" -> {
                        val arguments = call.arguments as? Map<*, *>
                        try {
                            launchUnityAr(arguments)
                            result.success(null)
                        } catch (error: Exception) {
                            result.error(
                                "UNITY_AR_LAUNCH_FAILED",
                                error.message,
                                null
                            )
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun getMapsApiKey(): String? {
        return try {
            val appInfo = packageManager.getApplicationInfo(
                packageName,
                PackageManager.GET_META_DATA
            )
            appInfo.metaData?.getString("com.google.android.geo.API_KEY")
        } catch (_: Exception) {
            null
        }
    }

    private fun isUnityArAvailable(): Boolean {
        val intent = Intent().setClassName(packageName, unityArActivityName)
        return intent.resolveActivity(packageManager) != null
    }

    private fun launchUnityAr(arguments: Map<*, *>?) {
        if (!isUnityArAvailable()) {
            throw IllegalStateException(
                "Unity AR activity is not registered yet. Export unityLibrary from Unity and add the UnityARActivity template from the repo guide."
            )
        }

        val intent = Intent().setClassName(packageName, unityArActivityName)
        addStringExtra(intent, "restaurantName", arguments?.get("restaurantName"))
        addStringExtra(intent, "cuisineLabel", arguments?.get("cuisineLabel"))
        addStringExtra(intent, "status", arguments?.get("status"))
        addStringExtra(intent, "hours", arguments?.get("hours"))
        addStringExtra(intent, "rating", arguments?.get("rating"))
        addStringExtra(intent, "subtitle", arguments?.get("subtitle"))
        intent.putExtra("launchSource", "flutter")

        try {
            startActivity(intent)
        } catch (error: ActivityNotFoundException) {
            throw IllegalStateException(
                "Unity AR activity could not be opened. Check the Android manifest and unityLibrary integration.",
                error
            )
        }
    }

    private fun addStringExtra(intent: Intent, key: String, value: Any?) {
        val text = value?.toString()?.trim()
        if (!text.isNullOrEmpty()) {
            intent.putExtra(key, text)
        }
    }
}

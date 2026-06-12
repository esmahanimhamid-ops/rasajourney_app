package io.carius.lars.ar_flutter_plugin

import android.app.Activity
import androidx.annotation.NonNull
import com.google.ar.core.ArCoreApk
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** ArFlutterPlugin */
class ArFlutterPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel: MethodChannel
  private lateinit var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding
  private var activity: Activity? = null

  override fun onAttachedToEngine(
      @NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding
  ) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "ar_flutter_plugin")
    channel.setMethodCallHandler(this)

    this.flutterPluginBinding = flutterPluginBinding
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "getPlatformVersion" -> result.success("Android ${android.os.Build.VERSION.RELEASE}")
      "isArCoreSupported" -> {
        try {
          val currentActivity = activity
          if (currentActivity == null) {
            result.success(false)
            return
          }

          val availability = ArCoreApk.getInstance().checkAvailability(currentActivity)
          result.success(availability == ArCoreApk.Availability.SUPPORTED_INSTALLED)
        } catch (error: Throwable) {
          result.success(false)
        }
      }
      "getArCoreAvailability" -> {
        try {
          val currentActivity = activity
          if (currentActivity == null) {
            result.success("UNKNOWN")
            return
          }

          val availability = ArCoreApk.getInstance().checkAvailability(currentActivity)
          result.success(availability.name)
        } catch (error: Throwable) {
          result.success("UNKNOWN")
        }
      }
      else -> result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onDetachedFromActivity() {
    channel.setMethodCallHandler(null)
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    onAttachedToActivity(binding)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    this.flutterPluginBinding.platformViewRegistry.registerViewFactory(
        "ar_flutter_plugin", AndroidARViewFactory(binding.activity, flutterPluginBinding.binaryMessenger))
  }

  override fun onDetachedFromActivityForConfigChanges() {
    onDetachedFromActivity()
  }
}

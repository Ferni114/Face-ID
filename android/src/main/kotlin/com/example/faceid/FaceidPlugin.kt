package com.example.faceid

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import android.graphics.BitmapFactory
import FaceIDLibrary
import androidx.annotation.NonNull


/* class FaceidPlugin: FlutterPlugin {
  private val CHANNEL = "com.lionintel.faceid/faceid"
  
  private lateinit var faceIdLib: FaceIDLibrary

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    faceIdLib = FaceIDLibrary(flutterEngine.applicationContext)
    
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
      call, result ->
      when (call.method) {
        "getVectors" -> {
            val byteArray = call.argument<ByteArray>("image")!!
            val bitmap = BitmapFactory.decodeByteArray(byteArray, 0, byteArray.size)
            var response=faceIdLib.getVectors(bitmap)
            result.success(response)
        }
      }
    }
  }
} */

class FaceidPlugin : FlutterPlugin, MethodCallHandler {

    private val CHANNEL = "com.lionintel.faceid/faceid"
    private lateinit var channel: MethodChannel
    private lateinit var faceIdLib: FaceIDLibrary

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)

        // Inicializas tu librería con el contexto
        faceIdLib = FaceIDLibrary(binding.applicationContext)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "getVectors" -> {
                val byteArray = call.argument<ByteArray>("image")
                if (byteArray == null) {
                    result.error("INVALID_ARGUMENT", "Image data is null", null)
                    return
                }
                val bitmap = BitmapFactory.decodeByteArray(byteArray, 0, byteArray.size)
                val response = faceIdLib.getVectors(bitmap)
                result.success(response)
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}

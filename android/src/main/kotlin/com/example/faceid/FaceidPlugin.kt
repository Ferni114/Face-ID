package com.example.faceid

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import com.lionintel.faceidlibrary.FaceIDLibrary


class FaceidPlugin: FlutterPlugin {
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
}

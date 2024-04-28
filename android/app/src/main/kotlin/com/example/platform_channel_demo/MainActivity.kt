package com.example.platform_channel_demo

import android.Manifest
import android.content.pm.PackageManager
import android.widget.Toast
import androidx.annotation.NonNull
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageCapture
import androidx.camera.core.ImageCaptureException
import androidx.camera.core.ImageProxy
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Base64
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    // Channel name
    private val CHANNEL_NAME = "live.videosdk.flutter.example/image_capture"
    private val REQUEST_CODE_PERMISSIONS = 10
    private val REQUIRED_PERMISSIONS =
            arrayOf(Manifest.permission.CAMERA, Manifest.permission.WRITE_EXTERNAL_STORAGE)
    private lateinit var cameraExecutor: ExecutorService
    private lateinit var imageCapture: ImageCapture
    private lateinit var channel: MethodChannel

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        cameraExecutor = Executors.newSingleThreadExecutor()
        if (allPermissionsGranted()) {
            startCamera()
        }

        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)

        // Handle method channel callbacks
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "captureImage" -> takePhoto(result)
                "requestPermission" -> {
                    if (allPermissionsGranted()) {
                        startCamera()
                    } else {
                        ActivityCompat.requestPermissions(
                                this,
                                REQUIRED_PERMISSIONS,
                                REQUEST_CODE_PERMISSIONS
                        )
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        cameraExecutor.shutdown()
    }

    private fun allPermissionsGranted(): Boolean {
        for (permission in REQUIRED_PERMISSIONS) {
            if (ContextCompat.checkSelfPermission(this, permission) !=
                            PackageManager.PERMISSION_GRANTED
            ) {
                return false
            }
        }
        channel.invokeMethod("permissonGranted", true)
        return true
    }

    // This function is called when the user accepts or decline the permission.
    // Request Code is used to check which permission called this function.
    // This request code is provided when the user is prompt for permission.
    override fun onRequestPermissionsResult(
            requestCode: Int,
            permissions: Array<String>,
            grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_CODE_PERMISSIONS) {
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                Toast.makeText(this@MainActivity, "Camera Permission Granted", Toast.LENGTH_SHORT)
                        .show()
                startCamera()
                channel.invokeMethod("permissonGranted", true)
            } else {
                Toast.makeText(this@MainActivity, "Camera Permission Denied", Toast.LENGTH_SHORT)
                        .show()
            }
        }
    }

    private fun startCamera() {
        val cameraProviderFuture = ProcessCameraProvider.getInstance(this)
        cameraProviderFuture.addListener(
                {
                    val cameraProvider = cameraProviderFuture.get()
                    val cameraSelector =
                            CameraSelector.Builder()
                                    .requireLensFacing(CameraSelector.LENS_FACING_BACK)
                                    .build()
                    val builder = ImageCapture.Builder()
                    imageCapture = builder.build()

                    try {
                        cameraProvider.unbindAll()
                        val camera =
                                cameraProvider.bindToLifecycle(this, cameraSelector, imageCapture)
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                },
                ContextCompat.getMainExecutor(this)
        )
    }

    private fun takePhoto(result: MethodChannel.Result) {
        imageCapture.takePicture(
                ContextCompat.getMainExecutor(this),
                object : ImageCapture.OnImageCapturedCallback() {
                    override fun onCaptureSuccess(image: ImageProxy) {
                        val buffer = image.planes[0].buffer
                        val bytes = ByteArray(buffer.capacity())
                        buffer.get(bytes)
                        val base64Image = Base64.getEncoder().encodeToString(bytes)
                        result.success(base64Image)
                        image.close()
                    }

                    override fun onError(exception: ImageCaptureException) {
                        result.error("IMAGE_CAPTURE_FAILED", "Failed to capture image", null)
                    }
                }
        )
    }
}

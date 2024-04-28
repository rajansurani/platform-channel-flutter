import UIKit
import Flutter
import AVFoundation

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    private let CHANNEL = "live.videosdk.flutter.example/image_capture"
    private var result: FlutterResult?
    private var captureSession: AVCaptureSession?
    private var stillImageOutput: AVCapturePhotoOutput?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(name: CHANNEL, binaryMessenger: controller.binaryMessenger)
        channel.setMethodCallHandler({
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            if call.method == "captureImage" {
                self.result = result
                self.captureImage()
            } else if call.method == "requestPermission" {
                self.requestCameraPermission { granted in
                    if granted {
                        print("Camera permission granted")
                        channel.invokeMethod("permissonGranted", arguments: true)
                    } else {
                        print("Camera permission denied")
                        channel.invokeMethod("permissonGranted", arguments: false)
                    }
                }
            } else {
                result(FlutterMethodNotImplemented)
            }
        })

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            completion(granted)
        }
    }

    private func captureImage() {
        captureSession = AVCaptureSession()

        guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Unable to access front camera.")
            result?(nil)
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: frontCamera)
            stillImageOutput = AVCapturePhotoOutput()

            if captureSession?.canAddInput(input) == true && captureSession?.canAddOutput(stillImageOutput!) == true {
                captureSession?.addInput(input)
                captureSession?.addOutput(stillImageOutput!)

                videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
                videoPreviewLayer?.videoGravity = .resizeAspectFill
                videoPreviewLayer?.connection?.videoOrientation = .portrait

                let captureQueue = DispatchQueue(label: "captureQueue")
                stillImageOutput?.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])], completionHandler: nil)
                captureSession?.startRunning()

                stillImageOutput?.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
            }
        } catch {
            print("Error setting up capture session: \(error.localizedDescription)")
            result?(nil)
        }
    }
}

extension AppDelegate: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imageData = photo.fileDataRepresentation() {
            let base64Image = imageData.base64EncodedString()
            result?(base64Image)
        } else {
            print("Error capturing image: \(error?.localizedDescription ?? "Unknown error")")
            result?(nil)
        }
    }
}

//
//  CameraController.swift
//  bii_multi_pheno_cam
//
//  Created by Developer on 6/15/22.
//

import AVFoundation
import UIKit
import Photos

public class CameraController: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate  {
    private enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
        case multiCamNotSupported
    }
    
    public let session = AVCaptureMultiCamSession()
    
    public var dataService: DataService?
    
    private var startTime: Date?
    
    private var frameRate: Double = 3.0
    
    private var isSessionRunning = false
    
    private var isCaptureEnabled = false
    
    private let sessionQueue = DispatchQueue(label: "session queue") // Communicate with the session and other session objects on this queue.
    
    private let dataOutputQueue = DispatchQueue(label: "data output queue")
    
    private let processingQueue = DispatchQueue(label: "photo processing queue")
    
    private var setupResult: SessionSetupResult = .success
    
    private var camera1DeviceInput: AVCaptureDeviceInput?
    
    private let camera1VideoDataOutput = AVCaptureVideoDataOutput()
    
    private var camera1VideoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    private var camera2DeviceInput: AVCaptureDeviceInput?
    
    private let camera2VideoDataOutput = AVCaptureVideoDataOutput()
    
    private var camera3DeviceInput: AVCaptureDeviceInput?
    
    private let camera3VideoDataOutput = AVCaptureVideoDataOutput()
    

    //MARK: Checks for user's permisions for camera
    public func checkForPermissions() {
      
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // The user has previously granted access to the camera.
            break
        case .notDetermined:
            /*
             The user has not yet been presented with the option to grant
             video access. Suspend the session queue to delay session
             setup until the access request has completed.
             */
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                if !granted {
                    self.setupResult = .notAuthorized
                }
                self.sessionQueue.resume()
            })
            
        default:
            // The user has previously denied access.
            setupResult = .notAuthorized
            print("User has previously denied camera access. Update privacy settings")
//            DispatchQueue.main.async {
//                self.alertError = AlertError(title: "Camera Access", message: "SwiftCamera doesn't have access to use your camera, please update your privacy settings.", primaryButtonTitle: "Settings", secondaryButtonTitle: nil, primaryAction: {
//                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!,
//                                                  options: [:], completionHandler: nil)
//
//                }, secondaryAction: nil)
//                self.shouldShowAlertView = true
//                self.isCameraUnavailable = true
//              //  self.isCameraButtonDisabled = true
//            }
        }
        
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                if status == .authorized {
                    print("app is authorized")
                } else {
                    print("Library Auth Failed")
                    self.setupResult = .notAuthorized
                }
            }
        }
    }
    
    public func configure(fr: Double) {
        //TODO: Pull framerate from config and not as an argument here
        self.frameRate = fr
        sessionQueue.async {
            self.configureSession()
            self.configureDataService()
            self.startSession()
        }
    }
    
    // Must be called on the session queue
    private func configureSession() {
        guard setupResult == .success else { return }
        
        guard AVCaptureMultiCamSession.isMultiCamSupported else {
            print("MultiCam not supported on this device")
            setupResult = .multiCamNotSupported
            return
        }
        
        // When using AVCaptureMultiCamSession, it is best to manually add connections from AVCaptureInputs to AVCaptureOutputs
        session.beginConfiguration()
        defer {
            session.commitConfiguration()
            if setupResult == .success {
                //checkSystemCost()
            }
        }

        guard configureCamera1() else {
            setupResult = .configurationFailed
            return
        }
        
        guard configureCamera2() else {
            setupResult = .configurationFailed
            return
        }
        
        guard configureCamera3() else {
            setupResult = .configurationFailed
            return
        }
        
    }
    
//    private func getPhotosLibraryAuth() {
//        PHPhotoLibrary.requestAuthorization { status in
//            DispatchQueue.main.async {
//                if status == .authorized {
//                    print("app is authorized")
//                } else {
//                    print("Library Auth Failed")
//                    self.setupResult = .configurationFailed
//                }
//            }
//        }
//    }
    
    //TODO: This could use some failure modes throughout this controller
    private func configureDataService() {
        self.dataService = DataService()
    }
    
    private func configureCamera1() -> Bool {
        session.beginConfiguration()
        defer {
            session.commitConfiguration()
        }
        
        // Find the back camera
        guard let camera1 = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Could not find wide angle for camera 1")
            return false
        }
        
        // Add the back camera input to the session
        do {
            camera1DeviceInput = try AVCaptureDeviceInput(device: camera1)
            
            guard let camera1DeviceInput = camera1DeviceInput,
                session.canAddInput(camera1DeviceInput) else {
                    print("Could not add camera 1 device input")
                    return false
            }
            session.addInputWithNoConnections(camera1DeviceInput)
        } catch {
            print("Could not create camera 1 device input: \(error)")
            return false
        }
        
        self.camera1DeviceInput?.device.setFR(frameRate: self.frameRate)
        
//        do {
//            try self.camera1DeviceInput?.device.lockForConfiguration()
//
//            print(self.camera1DeviceInput?.device.ac.videoSupportedFrameRateRanges)
////            self.camera1DeviceInput?.device.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: 20 )
////            self.camera1DeviceInput?.device.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: 15 )
//
//            self.camera1DeviceInput?.device.unlockForConfiguration()
//        } catch {
//            print("Could not lock device for configuration: \(error)")
//            return false
//        }
        
        // Find the back camera device input's video port
        guard let camera1DeviceInput = camera1DeviceInput,
            let camera1VideoPort = camera1DeviceInput.ports(for: .video,
                                                              sourceDeviceType: camera1.deviceType,
                                                              sourceDevicePosition: camera1.position).first else {
                                                                print("Could not find the back camera device input's video port")
                                                                return false
        }
        
        // Add the back camera video data output
        guard session.canAddOutput(camera1VideoDataOutput) else {
            print("Could not add the camera 1 video data output")
            return false
        }
        session.addOutputWithNoConnections(camera1VideoDataOutput)
        // Check if CVPixelFormat Lossy or Lossless Compression is supported
        
        if camera1VideoDataOutput.availableVideoPixelFormatTypes.contains(kCVPixelFormatType_Lossy_32BGRA) {
            // Set the Lossy format
            print("Selecting lossy pixel format")
            camera1VideoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_Lossy_32BGRA)]
        } else if camera1VideoDataOutput.availableVideoPixelFormatTypes.contains(kCVPixelFormatType_Lossless_32BGRA) {
            // Set the Lossless format
            print("Selecting a lossless pixel format")
            camera1VideoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_Lossless_32BGRA)]
        } else {
            // Set to the fallback format
            print("Selecting a 32BGRA pixel format")
            camera1VideoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        }
        
        camera1VideoDataOutput.setSampleBufferDelegate(self, queue: dataOutputQueue)
        
        // Connect the back camera device input to the back camera video data output
        let camera1VideoDataOutputConnection = AVCaptureConnection(inputPorts: [camera1VideoPort], output: camera1VideoDataOutput)
        guard session.canAddConnection(camera1VideoDataOutputConnection) else {
            print("Could not add a connection to the back camera video data output")
            return false
        }
        session.addConnection(camera1VideoDataOutputConnection)
        camera1VideoDataOutputConnection.videoOrientation = .portrait

        // Connect the back camera device input to the back camera video preview layer
//        guard let camera1VideoPreviewLayer = camera1VideoPreviewLayer else {
//            print("Missing video preview layer")
//            return false
//        }
//        let camera1VideoPreviewLayerConnection = AVCaptureConnection(inputPort: camera1VideoPort, videoPreviewLayer: camera1VideoPreviewLayer)
//        guard session.canAddConnection(camera1VideoPreviewLayerConnection) else {
//            print("Could not add a connection to the camera 1 video preview layer")
//            return false
//        }
//        session.addConnection(camera1VideoPreviewLayerConnection)

        return true
    }
    
    private func configureCamera2() -> Bool {
        session.beginConfiguration()
        defer {
            session.commitConfiguration()
        }
        
        // Find the back camera
        guard let camera2 = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back) else {
            print("Could not find wide angle for camera 2")
            return false
        }
        
        // Add the back camera input to the session
        do {
            camera2DeviceInput = try AVCaptureDeviceInput(device: camera2)
            
            guard let camera2DeviceInput = camera2DeviceInput,
                session.canAddInput(camera2DeviceInput) else {
                    print("Could not add camera 2 device input")
                    return false
            }
            session.addInputWithNoConnections(camera2DeviceInput)
        } catch {
            print("Could not create camera 2 device input: \(error)")
            return false
        }
        
        print(self.frameRate)
        self.camera2DeviceInput?.device.setFR(frameRate: self.frameRate)
        
        // Find the camera device input's video port
        guard let camera2DeviceInput = camera2DeviceInput,
            let camera2VideoPort = camera2DeviceInput.ports(for: .video,
                                                              sourceDeviceType: camera2.deviceType,
                                                              sourceDevicePosition: camera2.position).first else {
                                                                print("Could not find the camera 2 device input's video port")
                                                                return false
        }
        
        // Add the back camera video data output
        guard session.canAddOutput(camera2VideoDataOutput) else {
            print("Could not add the camera 2 video data output")
            return false
        }
        session.addOutputWithNoConnections(camera2VideoDataOutput)
        // Check if CVPixelFormat Lossy or Lossless Compression is supported
        
        if camera2VideoDataOutput.availableVideoPixelFormatTypes.contains(kCVPixelFormatType_Lossy_32BGRA) {
            // Set the Lossy format
            print("Selecting lossy pixel format")
            camera2VideoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_Lossy_32BGRA)]
        } else if camera2VideoDataOutput.availableVideoPixelFormatTypes.contains(kCVPixelFormatType_Lossless_32BGRA) {
            // Set the Lossless format
            print("Selecting a lossless pixel format")
            camera2VideoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_Lossless_32BGRA)]
        } else {
            // Set to the fallback format
            print("Selecting a 32BGRA pixel format")
            camera2VideoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        }
        
        camera2VideoDataOutput.setSampleBufferDelegate(self, queue: dataOutputQueue)
        
        // Connect the back camera device input to the back camera video data output
        let camera2VideoDataOutputConnection = AVCaptureConnection(inputPorts: [camera2VideoPort], output: camera2VideoDataOutput)
        guard session.canAddConnection(camera2VideoDataOutputConnection) else {
            print("Could not add a connection to the camera 2 video data output")
            return false
        }
        session.addConnection(camera2VideoDataOutputConnection)
        camera2VideoDataOutputConnection.videoOrientation = .portrait

        return true
    }
    
    private func configureCamera3() -> Bool {
        session.beginConfiguration()
        defer {
            session.commitConfiguration()
        }
        
        // Find the back camera
        guard let camera3 = AVCaptureDevice.default(.builtInTelephotoCamera, for: .video, position: .back) else {
            print("Could not find wide angle for camera 3")
            return false
        }
        
        // Add the back camera input to the session
        do {
            camera3DeviceInput = try AVCaptureDeviceInput(device: camera3)
            
            guard let camera3DeviceInput = camera3DeviceInput,
                session.canAddInput(camera3DeviceInput) else {
                    print("Could not add camera 3 device input")
                    return false
            }
            session.addInputWithNoConnections(camera3DeviceInput)
        } catch {
            print("Could not create camera 3 device input: \(error)")
            return false
        }
        
        self.camera3DeviceInput?.device.setFR(frameRate: self.frameRate)
        
        // Find the camera device input's video port
        guard let camera3DeviceInput = camera3DeviceInput,
            let camera3VideoPort = camera3DeviceInput.ports(for: .video,
                                                              sourceDeviceType: camera3.deviceType,
                                                              sourceDevicePosition: camera3.position).first else {
                                                                print("Could not find the camera 3 device input's video port")
                                                                return false
        }
        
        // Add the back camera video data output
        guard session.canAddOutput(camera3VideoDataOutput) else {
            print("Could not add the camera 3 video data output")
            return false
        }
        session.addOutputWithNoConnections(camera3VideoDataOutput)
        // Check if CVPixelFormat Lossy or Lossless Compression is supported
        
        if camera3VideoDataOutput.availableVideoPixelFormatTypes.contains(kCVPixelFormatType_Lossy_32BGRA) {
            // Set the Lossy format
            print("Selecting lossy pixel format")
            camera3VideoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_Lossy_32BGRA)]
        } else if camera3VideoDataOutput.availableVideoPixelFormatTypes.contains(kCVPixelFormatType_Lossless_32BGRA) {
            // Set the Lossless format
            print("Selecting a lossless pixel format")
            camera3VideoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_Lossless_32BGRA)]
        } else {
            // Set to the fallback format
            print("Selecting a 32BGRA pixel format")
            camera3VideoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        }
        
        camera3VideoDataOutput.setSampleBufferDelegate(self, queue: dataOutputQueue)
        
        // Connect the back camera device input to the back camera video data output
        let camera3VideoDataOutputConnection = AVCaptureConnection(inputPorts: [camera3VideoPort], output: camera3VideoDataOutput)
        guard session.canAddConnection(camera3VideoDataOutputConnection) else {
            print("Could not add a connection to the camera 3 video data output")
            return false
        }
        session.addConnection(camera3VideoDataOutputConnection)
        camera3VideoDataOutputConnection.videoOrientation = .portrait

        return true
    }
    
    public func startSession() {
        sessionQueue.async {
            switch self.setupResult {
            case .success:
                print("starting session")
                self.session.startRunning()
                self.isSessionRunning = self.session.isRunning
                self.dataService?.start()
            case .configurationFailed, .notAuthorized:
                print("Configuration Failed or Not authorized")
            case .multiCamNotSupported:
                print("MultiCam not supported")
            }
        }
    }
    
    public func startCapture() {
        self.isCaptureEnabled = true
        self.startTime = Date()
    }
    
    public func stop(site: String, block: String) {
        sessionQueue.async {
            print("stopping session")
            self.isCaptureEnabled = false
            self.session.stopRunning()
        
            //TODO: fix optional start time and this crappy fallback
            let start = self.startTime ?? Date()
            self.dataService?.save(siteId: site, blockId: block, sessionStart: start, sessionStop: Date())
            self.isSessionRunning = self.session.isRunning
        }
    }
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return  }
//        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        
//        switch output {
//        case camera1VideoDataOutput:
//            print("camera 1")
//        case camera2VideoDataOutput:
//            print("camera 2")
//        case camera3VideoDataOutput:
//            print("camera 3")
//        default:
//            print("camera unrecognized")
//        }

//        let context = CIContext()
//        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return  }
//
//        let image = UIImage(cgImage: cgImage)
        if self.isCaptureEnabled {
            processingQueue.async {
                self.processImage(buffer: sampleBuffer)
            }
        }
    }
    
    private func processImage(buffer: CMSampleBuffer) {
        print("recieved image")
        guard let imageBuffer = CMSampleBufferGetImageBuffer(buffer) else {
            print("failed to process image")
            return
        }
        
        let metadata = CMCopyDictionaryOfAttachments(allocator: nil, target: buffer, attachmentMode: kCMAttachmentMode_ShouldPropagate)!
        

        let ciImage = CIImage(cvImageBuffer: imageBuffer,
                              options:[CIImageOption.properties: metadata])

        let context = CIContext()

        let data = context.jpegRepresentation(of: ciImage,
                                              colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
                                              options: [:])!
        
        self.saveImageToLibrary(img: data)
    }
    
    private func saveImageToLibrary(img: Data) {
        print("image save block")
        PHPhotoLibrary.shared().performChanges({
            let options = PHAssetResourceCreationOptions()
            let creationRequest = PHAssetCreationRequest.forAsset()
            self.dataService?.photoCollection?.localIdentifiers.append(creationRequest.placeholderForCreatedAsset!.localIdentifier)
//            options.uniformTypeIdentifier = self.requestedPhotoSettings.processedFileType.map { $0.rawValue }
            creationRequest.addResource(with: .photo, data: img, options: options)
            
            
            
        }, completionHandler: { _, error in
            if let error = error {
                print("Error occurred while saving photo to photo library: \(error)")
            }
            
//            DispatchQueue.main.async {
//                self.completionHandler(self)
//            }
        }
        )

    }
    

}

//extension CameraController:  {
//
//    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//    guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return  }
//    let ciImage = CIImage(cvPixelBuffer: imageBuffer)
//
//    let context = CIContext()
//    guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return  }
//
//    let image = UIImage(cgImage: cgImage)
//
//    self.didOutputNewImage(img: image)
//  }

//}

extension AVCaptureDevice {
    func setFR(frameRate: Double) {
    guard let range = activeFormat.videoSupportedFrameRateRanges.first,
        range.minFrameRate...range.maxFrameRate ~= frameRate
        else {
            print("Requested FPS is not supported by the device's activeFormat !")
            return
    }

    do { try lockForConfiguration()
        print("setting device framerate")
        activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: Int32(frameRate))
        activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: Int32(frameRate))
        unlockForConfiguration()
    } catch {
        print("LockForConfiguration failed with error: \(error.localizedDescription)")
    }
  }
}

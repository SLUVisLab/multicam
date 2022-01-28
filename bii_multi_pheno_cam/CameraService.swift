//
//  CameraService.swift
//  bii_multi_pheno_cam
//
//  Created by Developer on 11/16/21.
//

import Foundation
import Combine
import AVFoundation
import Photos
import UIKit

public struct Photo: Identifiable, Equatable {
//    The ID of the captured photo
    public var id: String
//    Data representation of the captured photo
    public var originalData: Data
    
    public init(id: String = UUID().uuidString, originalData: Data) {
        self.id = id
        self.originalData = originalData
    }
}

public struct AlertError {
    public var title: String = ""
    public var message: String = ""
    public var primaryButtonTitle = "Accept"
    public var secondaryButtonTitle: String?
    public var primaryAction: (() -> ())?
    public var secondaryAction: (() -> ())?
    
    public init(title: String = "", message: String = "", primaryButtonTitle: String = "Accept", secondaryButtonTitle: String? = nil, primaryAction: (() -> ())? = nil, secondaryAction: (() -> ())? = nil) {
        self.title = title
        self.message = message
        self.primaryAction = primaryAction
        self.primaryButtonTitle = primaryButtonTitle
        self.secondaryAction = secondaryAction
    }
}

public class CameraService {
    
    typealias PhotoCaptureSessionID = String
    
    //  MARK: observed properties UI must react to
    
    @Published public var flashMode: AVCaptureDevice.FlashMode = .off
    
    @Published public var shouldShowAlertView = false
    
    @Published public var shouldShowSpinner = false
    
    @Published public var willCapturePhoto = false
    
    @Published public var isCameraButtonDisabled = true
    
    @Published public var isCameraUnavailable = true
    
    @Published public var photo: Photo?
    
    // MARK: Alert properties
    public var alertError: AlertError = AlertError()
    
    // MARK: Session Management Properties
    
    public let session = AVCaptureMultiCamSession()

    var isSessionRunning = false

    var isConfigured = false

    var setupResult: SessionSetupResult = .success

    // Communicate with the session and other session objects on this queue.
    private let sessionQueue = DispatchQueue(label: "session queue")
    
    @objc dynamic var videoDeviceInput: AVCaptureDeviceInput!
    
    // MARK: Device Configuration Properties
    private let videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera, .builtInTelephotoCamera], mediaType: .video, position: .unspecified)
    
    // MARK: Capturing Photos
    
    private let photoOutput1 = AVCapturePhotoOutput()
    private let photoOutput2 = AVCapturePhotoOutput()
    private let photoOutput3 = AVCapturePhotoOutput()
    
    private var inProgressPhotoCaptureDelegates = [Int64: PhotoCaptureProcessor]()
    
    public func configure() {
        /*
         Setup the capture session.
         In general, it's not safe to mutate an AVCaptureSession or any of its
         inputs, outputs, or connections from multiple threads at the same time.
         
         Don't perform these tasks on the main queue because
         AVCaptureSession.startRunning() is a blocking call, which can
         take a long time. Dispatch session setup to the sessionQueue, so
         that the main queue isn't blocked, which keeps the UI responsive.
         */
        sessionQueue.async {
            self.configureSession()
        }
    }
    
    //        MARK: Checks for user's permisions
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
            
            DispatchQueue.main.async {
                self.alertError = AlertError(title: "Camera Access", message: "SwiftCamera doesn't have access to use your camera, please update your privacy settings.", primaryButtonTitle: "Settings", secondaryButtonTitle: nil, primaryAction: {
                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!,
                                                  options: [:], completionHandler: nil)
                    
                }, secondaryAction: nil)
                self.shouldShowAlertView = true
                self.isCameraUnavailable = true
                self.isCameraButtonDisabled = true
            }
        }
    }
    
    //  MARK: Session Management
        
    // Call this on the session queue.
    /// - Tag: ConfigureSession
    private func configureSession() {
        if setupResult != .success {
            return
        }
        
        session.beginConfiguration()
        
//        session.sessionPreset = .photo
        
        // Add video input.
        do {
            if let captureDevice1 = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back) {

                let input1 = try AVCaptureDeviceInput(device: captureDevice1)
                if session.canAddInput(input1) {
                    session.addInput(input1)
                }
            }
            
            if let captureDevice2 = AVCaptureDevice.default(.builtInUltraWideCamera, for: AVMediaType.video, position: .back) {
                let input2 = try AVCaptureDeviceInput(device: captureDevice2)
                if session.canAddInput(input2) {
                    session.addInput(input2)
                    }
            }
            
            if let captureDevice3 = AVCaptureDevice.default(.builtInTelephotoCamera, for: AVMediaType.video, position: .back) {
                let input3 = try AVCaptureDeviceInput(device: captureDevice3)
                if session.canAddInput(input3) {
                    session.addInput(input3)
                }
            }

        } catch {
            print("Couldn't create video device input: \(error)")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        
        // Add the photo output.
        if session.canAddOutput(photoOutput1) &&
            session.canAddOutput(photoOutput2) &&
            session.canAddOutput(photoOutput3){
            
            session.addOutput(photoOutput1)
            photoOutput1.isHighResolutionCaptureEnabled = true
            photoOutput1.maxPhotoQualityPrioritization = .quality
            
            session.addOutput(photoOutput2)
            photoOutput2.isHighResolutionCaptureEnabled = true
            photoOutput2.maxPhotoQualityPrioritization = .quality
            
            session.addOutput(photoOutput3)
            photoOutput3.isHighResolutionCaptureEnabled = true
            photoOutput3.maxPhotoQualityPrioritization = .quality
            
        } else {
            print("Could not add photo outputs to the session")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        
        session.commitConfiguration()
        
        self.isConfigured = true
        
        self.start()
    }
    
    /// - Tag: Stop capture session
    
    public func stop(completion: (() -> ())? = nil) {
        sessionQueue.async {
            if self.isSessionRunning {
                if self.setupResult == .success {
                    self.session.stopRunning()
                    self.isSessionRunning = self.session.isRunning
                    
                    if !self.session.isRunning {
                        DispatchQueue.main.async {
                            self.isCameraButtonDisabled = true
                            self.isCameraUnavailable = true
                            completion?()
                        }
                    }
                }
            }
        }
    }
    
    /// - Tag: Start capture session
    
    public func start() {
//        We use our capture session queue to ensure our UI runs smoothly on the main thread.
        sessionQueue.async {
            if !self.isSessionRunning && self.isConfigured {
                switch self.setupResult {
                case .success:
                    self.session.startRunning()
                    self.isSessionRunning = self.session.isRunning
                    
                    if self.session.isRunning {
                        DispatchQueue.main.async {
                            self.isCameraButtonDisabled = false
                            self.isCameraUnavailable = false
                        }
                    }
                    
                case .configurationFailed, .notAuthorized:
                    print("Application not authorized to use camera")

                    DispatchQueue.main.async {
                        self.alertError = AlertError(title: "Camera Error", message: "Camera configuration failed. Either your device camera is not available or its missing permissions", primaryButtonTitle: "Accept", secondaryButtonTitle: nil, primaryAction: nil, secondaryAction: nil)
                        self.shouldShowAlertView = true
                        self.isCameraButtonDisabled = true
                        self.isCameraUnavailable = true
                    }
                }
            }
        }
    }
    
    //    MARK: Capture Photo
        
    /// - Tag: CapturePhoto
    public func capturePhoto(dataService: DataService) {
        if self.setupResult != .configurationFailed {
            self.isCameraButtonDisabled = true
            
            sessionQueue.async {
//                if let photoOutputConnection = self.photoOutput.connection(with: .video) {
//                    photoOutputConnection.videoOrientation = .portrait
//                }
                var photoSettings = AVCapturePhotoSettings()
                
                // Capture HEIF photos when supported. Enable according to user settings and high-resolution photos.
//                if  self.photoOutput.availablePhotoCodecTypes.contains(.hevc) {
//                    photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
//                }
                
                // Sets the flash option for this capture.
//                if self.videoDeviceInput.device.isFlashAvailable {
//                    photoSettings.flashMode = self.flashMode
//                }
                
                photoSettings.isHighResolutionPhotoEnabled = true
                
                // Sets the preview thumbnail pixel format
//                if !photoSettings.__availablePreviewPhotoPixelFormatTypes.isEmpty {
//                    photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: photoSettings.__availablePreviewPhotoPixelFormatTypes.first!]
//                }
                
                photoSettings.photoQualityPrioritization = .quality
                
                let photoCaptureProcessor = PhotoCaptureProcessor(with: dataService, requestedPhotoSettings: photoSettings,
                                                                  
//                    willCapturePhotoAnimation: { [weak self] in
//                    // Tells the UI to flash the screen to signal that SwiftCamera took a photo.
//                    DispatchQueue.main.async {
//                        self?.willCapturePhoto = true
//                    }
//
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
//                        self?.willCapturePhoto = false
//                    }
//
//                    }
                    completionHandler: { [weak self] (photoCaptureProcessor) in
                    // When the capture is complete, remove a reference to the photo capture delegate so it can be deallocated.
                    if let data = photoCaptureProcessor.photoData {
                        self?.photo = Photo(originalData: data)
                        print("passing photo")
                    } else {
                        print("No photo data")
                    }
                    
                    self?.isCameraButtonDisabled = false
                    
                    self?.sessionQueue.async {
                        self?.inProgressPhotoCaptureDelegates[photoCaptureProcessor.requestedPhotoSettings.uniqueID] = nil
                    }
                }, photoProcessingHandler: { [weak self] animate in
                    // Animates a spinner while photo is processing
                    if animate {
                        self?.shouldShowSpinner = true
                    } else {
                        self?.shouldShowSpinner = false
                    }
                })
                
                // The photo output holds a weak reference to the photo capture delegate and stores it in an array to maintain a strong reference.
                self.inProgressPhotoCaptureDelegates[photoCaptureProcessor.requestedPhotoSettings.uniqueID] = photoCaptureProcessor
                self.photoOutput3.capturePhoto(with: photoSettings, delegate: photoCaptureProcessor)
                self.photoOutput2.capturePhoto(with: photoSettings, delegate: photoCaptureProcessor)
                self.photoOutput1.capturePhoto(with: photoSettings, delegate: photoCaptureProcessor)
                
                
            }
        }
    }
}

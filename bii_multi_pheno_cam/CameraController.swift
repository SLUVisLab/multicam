//
//  CameraController.swift
//  bii_multi_pheno_cam
//
//  Created by Developer on 11/2/21.
// THIS FILE SHOULD BE DELETED.... I THINK....

import UIKit
import AVFoundation

class CameraController: UIViewController {
    
    //Vars
    var captureSession : AVCaptureSession!
    
    //Camera Setup
    func setupAndStartCaptureSession(){
        DispatchQueue.global(qos: .userInitiated).async{
            //init session
            self.captureSession = AVCaptureSession()
            //start configuration
            self.captureSession.beginConfiguration()
            
            //session specific configuration
            if self.captureSession.canSetSessionPreset(.photo) {
                self.captureSession.sessionPreset = .photo
            }
            self.captureSession.automaticallyConfiguresCaptureDeviceForWideColor = true
            
            //setup inputs
            //self.setupInputs()
            
            DispatchQueue.main.async {
                //setup preview layer
                //self.setupPreviewLayer()
            }
            
            //setup output
            //self.setupOutput()
            
            //commit configuration
            self.captureSession.commitConfiguration()
            //start running it
            self.captureSession.startRunning()
        }
    }
    
}

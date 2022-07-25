//
//  CameraView.swift
//  bii_multi_pheno_cam
//
//  Created by Developer on 11/1/21.
//

import SwiftUI
import Combine
import AVFoundation
import ActivityIndicatorView
import AVKit
//import PromisesTestHelpers

final class CameraViewModel: ObservableObject {
    
    //public var service: CameraService
    public var camera: CameraController
    
    let defaults = UserDefaults.standard
    
    var config: ConfigService?
    
    @Published var isActive = false
    
    @Published var isConfigured = false
    
    // the site and block are pulled from arrays stored in the app config file (updated on app startup from remote DB)
    // the array index of the last site chosen by the user is stored locally in userDefaults so it "remembers"
    // userDefaults is updated in the didSet method on the vars below when changed.
    
    @Published var selectedBlock: String = ""
    
    @Published var selectedSite: String = ""
    
    @Published var id: UUID = UUID()
    
    @Published var selectedSiteIndex: Int {
        //TODO: fix lots of unsafe forced unwrapping here
        didSet {
            print("site changed")
            self.id = UUID()
            selectedBlockIndex = 0
            self.selectedSite = config!.config.sites![selectedSiteIndex].id!
            self.selectedBlock = config!.config.sites![selectedSiteIndex].blocks[selectedBlockIndex]
            self.defaults.set(self.selectedSiteIndex, forKey: "selectedSiteIndex")
            
        }
    }
    
    @Published var selectedBlockIndex: Int = 0 {
        didSet {
            self.selectedSite = config!.config.sites![selectedSiteIndex].id!
            self.selectedBlock = config!.config.sites![selectedSiteIndex].blocks[selectedBlockIndex]
        }
    }
    
    init() {
        print("Initializing....")
        self.camera = CameraController()

        self.selectedSiteIndex = self.defaults.object(forKey: "selectedSiteIndex") as? Int ?? 0

    }
    
    func configure() {
        print("called camera.configure...")
        camera.checkForPermissions()
        
        //TODO: write better fallbacks. maybe refactor this out of the view model
        // pulling framerate from the config file and passing to camera controller configuration
        let frameRate: Double
        if config?.config.frame_rate_seconds != nil {
            print("found config setting for framerate")
            frameRate = Double(config?.config.frame_rate_seconds ?? "3")!
        } else {
            print("config file not available yet")
            frameRate = 3.0
        }

        camera.configure(fr: frameRate)

        //TODO: Not Neccessarily true dude...
        self.isConfigured = true
    }
    
    func resetCamera() {
        self.camera = CameraController()
        configure()
    }
    
    func startCapture() {
        isActive = true
        camera.startCapture()
    }
    
    func stopCapture() {
        camera.stop(site: String(self.selectedSite) ?? "", block: String(self.selectedBlock) ?? "")
        isActive = false
        resetCamera()
    }
    
    // best way I can find to pass env obj from view to view model
    func setup(config: ConfigService) {
        self.config = config
        
        // TODO: this is a quick patch for starting the camera if site/block info hasnt been pulled from the cloud. Crashes without the guard
        guard let sites = config.config.sites else {
            print("No sites provided in configuration")
            self.selectedSite = ""
            self.selectedBlock = ""
            return
        }
        self.selectedSite = sites[selectedSiteIndex].id!
        self.selectedBlock = sites[selectedSiteIndex].blocks[selectedBlockIndex]
        
        if !self.isConfigured {
            configure()
        }
    }
}

struct CameraView: View {
    
    @EnvironmentObject var configService: ConfigService

    @StateObject var cameraViewModel = CameraViewModel()
    @State private var backButtonHidden = false
    @State var audioService = AudioService()
    
    var body: some View {
        ZStack{
            Color.black
                .ignoresSafeArea(.all)
            
            if cameraViewModel.isActive{
                VStack{
                    Text("Capture in progress...")
                        .foregroundColor(Color.white)
                    ActivityIndicatorView(isVisible: $cameraViewModel.isActive, type: .growingCircle)
                        .foregroundColor(.white)
                        .frame(width: 280, height: 280, alignment: .center)
                    
                    Spacer()
                    
                    Button(){
                        self.backButtonHidden.toggle()
                        if(UserDefaults.standard.object(forKey: "soundOnForCapture") as? Bool ?? true) {
                            audioService.stop()
                        }
                        cameraViewModel.stopCapture()
                    } label: {
                        ZStack{
                            Circle()
                                .fill(Color.red)
                                .frame(width: 65, height: 65)
                            
                            Circle()
                                .stroke(Color.red, lineWidth: 2)
                                .frame(width: 75, height: 75)
                        }
                    }
                }
            } else {
                
                ZStack {
                    if cameraViewModel.isConfigured {
                        CameraPreview(session: cameraViewModel.camera.session)
                            .animation(.easeInOut)
                    }
//                        .onAppear {
//                            if !cameraViewModel.isConfigured {
//                                cameraViewModel.configure()
//                            }
//                        }
                        
                    
                    VStack{
                        
                        // Might want to implement some version of the text input field where this is default values for the picker
                        // fail to load from the remote confif file
                        
//                        HStack(alignment: .center) {
//                            Text("Site ID:")
//                                .font(.callout)
//                                .bold()
//
//                            TextField("Enter site ID...", text: $camera.selectedSite)
//                                .textFieldStyle(RoundedBorderTextFieldStyle())
//                                .keyboardType(.decimalPad)
//                        }
//                        .padding()
//
//                        HStack(alignment: .center) {
//                            Text("Block ID:")
//                                .font(.callout)
//                                .bold()
//                            TextField("Enter block ID...", text: $camera.selectedBlock)
//                                .textFieldStyle(RoundedBorderTextFieldStyle())
//                                .keyboardType(.decimalPad)
//                        }
//                        .padding()
                        if let sites = configService.config.sites {
                            Form {
                                Picker("Site ID:", selection: $cameraViewModel.selectedSiteIndex) {
                                    ForEach(0 ..< sites.count) { index in
                                        Text(sites[index].id!)
                                    }
                                }
                                Picker("Block ID:", selection: $cameraViewModel.selectedBlockIndex) {
                                    ForEach(0 ..< sites[cameraViewModel.selectedSiteIndex].blocks.count) { index in
                                        Text(sites[cameraViewModel.selectedSiteIndex].blocks[index])
                                    }
                                }
                                .id(cameraViewModel.id)
                            }
                                .background(Color.clear)
                                .padding(.top, 1)
                                .onAppear {
                                  UITableView.appearance().backgroundColor = .clear
                                }
                                .onDisappear {
                                  UITableView.appearance().backgroundColor = .clear
                                }
                        } else {
                            Text("Error: Unable to load field site information. Try connecting to a network and reloading the app to download missing configuration")
                                .foregroundColor(Color.red)
                                .background(Color.white)
                        }
                            
                        Spacer()
                            
                        Button(){
                            if cameraViewModel.isConfigured {
                                self.backButtonHidden.toggle()
                                if(UserDefaults.standard.object(forKey: "soundOnForCapture") as? Bool ?? true) {
                                    audioService.start(track: "sounds/super_mario_1")
                                }
                                cameraViewModel.startCapture()
                            } else {
                                //TODO: Write alert for when configuration failed
                                print("Camera configuration failed...")
                            }
                            
                        } label: {
                            ZStack{
                                Circle()
                                    .fill(buttonColor)
                                    .frame(width: 65, height: 65)
                                
                                Circle()
                                    .stroke(buttonColor, lineWidth: 2)
                                    .frame(width: 75, height: 75)
                            }
                        }
                            .padding(.bottom, 20)
                            .disabled(cameraViewModel.selectedSite.isEmpty || cameraViewModel.selectedBlock.isEmpty)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(backButtonHidden)
        // best way I've found to pass env obj from view to view model
        .onAppear{
            print("passing config from view")
            self.cameraViewModel.setup(config: self.configService)
        }
    }
    
    // Make the button gray when it's disabled
    var buttonColor: Color {
        return cameraViewModel.selectedSite.isEmpty || cameraViewModel.selectedBlock.isEmpty ? .gray : .white
    }
}

struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView()
    }
}


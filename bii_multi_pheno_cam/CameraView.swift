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

final class CameraModel: ObservableObject {
    public var service: CameraService
    
    var config: ConfigService?
    
    @Published var photo: Photo!
    
    @Published var showAlertError = false
    
    @Published var isFlashOn = false
    
    @Published var willCapturePhoto = true
    
    @Published var isActive = false
    
    @Published var isConfigured = false
    
    @Published var selectedBlock: String = ""
    
    @Published var selectedSite: String = ""
    
    @Published var selectedSiteIndex: Int {
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
    
    @Published var id: UUID = UUID()
    
    var alertError: AlertError!
    
    var session: AVCaptureSession
    
    var dataService: DataService
    
    var timer = Timer()
    
    private var subscriptions = Set<AnyCancellable>()
    
    let defaults = UserDefaults.standard
    
    init() {
        print("Initializing....")
        self.service = CameraService()
        self.session = service.session
        self.dataService = DataService()
        self.selectedSiteIndex = self.defaults.object(forKey: "selectedSiteIndex") as? Int ?? 0
        
        service.$photo.sink { [weak self] (photo) in
            guard let pic = photo else { return }
            self?.photo = pic
        }
        .store(in: &self.subscriptions)
        
        service.$shouldShowAlertView.sink { [weak self] (val) in
            self?.alertError = self?.service.alertError
            self?.showAlertError = val
        }
        .store(in: &self.subscriptions)
        
        service.$flashMode.sink { [weak self] (mode) in
            self?.isFlashOn = mode == .on
        }
        .store(in: &self.subscriptions)
        
        service.$willCapturePhoto.sink { [weak self] (val) in
            self?.willCapturePhoto = val
        }
        .store(in: &self.subscriptions)
        
    }
    
    func configure() {
        print("called camera.configure...")
        service.checkForPermissions()
        service.configure()
        self.isConfigured = true
    }
    
    func capturePhoto() {
        service.capturePhoto(dataService: self.dataService)
    }
    
    func startTimedCapture(interval: Double, tolerance: Double) {
        print(interval)
        isActive = true
        self.dataService.start()
        timer = Timer(timeInterval: interval, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
        RunLoop.current.add(timer, forMode: RunLoop.Mode.common)
        timer.tolerance = tolerance
    }
    
    // the function called by the timer needs an objc wrapper
    @objc func timerAction() {
        capturePhoto()
    }
    
    func stopTimedCapture() {
        isActive = false
        timer.invalidate()

        // TODO: Error handling for type coercion
        self.dataService.save(siteId: String(self.selectedSite) ?? "", blockId: String(self.selectedBlock) ?? "")
        self.defaults.set(self.selectedSiteIndex, forKey: "selectedSite")
        self.selectedBlock = ""
        self.service = CameraService()
        self.session = self.service.session
        self.isConfigured = false
    }
    
    func switchFlash() {
        service.flashMode = service.flashMode == .on ? .off : .on
    }
    
    // best way I can find to pass env obj from view to view model
    func setup(config: ConfigService) {
        self.config = config
        self.selectedSite = config.config.sites![selectedSiteIndex].id!
        self.selectedBlock = config.config.sites![selectedSiteIndex].blocks[selectedBlockIndex]
    }
    
}

struct CameraView: View {
    
    @EnvironmentObject var configService: ConfigService

    @StateObject var camera = CameraModel()
    @State var currentZoomFactor: CGFloat = 1.0
    
    
    var body: some View {
        ZStack{
            Color.black
                .ignoresSafeArea(.all)
            
            if camera.isActive{
                VStack{
                    Text("Capture in progress...")
                        .foregroundColor(Color.white)
                    ActivityIndicatorView(isVisible: $camera.isActive, type: .growingCircle)
                        .foregroundColor(.white)
                        .frame(width: 280, height: 280, alignment: .center)
                    
                    Spacer()
                    
                    Button(action: {camera.stopTimedCapture()}, label: {
                        ZStack{
                            Circle()
                                .fill(Color.red)
                                .frame(width: 65, height: 65)
                            
                            Circle()
                                .stroke(Color.red, lineWidth: 2)
                                .frame(width: 75, height: 75)
                        }
                    })
                }
            } else {
                
                ZStack {
                    
                    CameraPreview(session: camera.session)
                        .onAppear {
                            if !camera.isConfigured {
                                camera.configure()
                            }
                        }
                        .alert(isPresented: $camera.showAlertError, content: {
                            Alert(title: Text(camera.alertError.title), message: Text(camera.alertError.message), dismissButton: .default(Text(camera.alertError.primaryButtonTitle), action: {
                                camera.alertError.primaryAction?()
                            }))
                        })
                        .animation(.easeInOut)
                       // .frame(height: 1000)
    //                    .ignoresSafeArea(.all)
                    
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
                                Picker("Site ID:", selection: $camera.selectedSiteIndex) {
                                    ForEach(0 ..< sites.count) { index in
                                        Text(sites[index].id!)
                                    }
                                }
                                Picker("Block ID:", selection: $camera.selectedBlockIndex) {
                                    ForEach(0 ..< sites[camera.selectedSiteIndex].blocks.count) { index in
                                        Text(sites[camera.selectedSiteIndex].blocks[index])
                                    }
                                }
                                .id(camera.id)
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
//                        Form {
//                            Picker("Site ID:", selection: $camera.selectedSiteIndex) {
//                                ForEach(0 ..< configService.config.sites!.count) { index in
//                                    Text(configService.config.sites![index].id!)
//                                }
//                            }
//                            Picker("Block ID:", selection: $camera.selectedBlockIndex) {
//                                ForEach(0 ..< configService.config.sites![camera.selectedSiteIndex].blocks.count) { index in
//                                    Text(configService.config.sites![camera.selectedSiteIndex].blocks[index])
//                                }
//                            }
//                            .id(camera.id)
//                        }
//                            .background(Color.clear)
//                            .padding(.top, 1)
//                            .onAppear {
//                              UITableView.appearance().backgroundColor = .clear
//                            }
//                            .onDisappear {
//                              UITableView.appearance().backgroundColor = .clear
//                            }
                            
                        Spacer()
                            
                        Button(action: {camera.startTimedCapture(
                                            interval: Double(configService.config.frame_rate_seconds)!,
                                            tolerance: Double(configService.config.frame_rate_tolerance_seconds)!)},
                            label: {
                            ZStack{
                                Circle()
                                    .fill(buttonColor)
                                    .frame(width: 65, height: 65)
                                
                                Circle()
                                    .stroke(buttonColor, lineWidth: 2)
                                    .frame(width: 75, height: 75)
                            }
                        })
                            .padding(.bottom, 20)
                            .disabled(camera.selectedSite.isEmpty || camera.selectedBlock.isEmpty)
                            

                        
                    }
                }
            }
            
        }
        // best way I've found to pass env obj from view to view model
        .onAppear{
            self.camera.setup(config: self.configService)
        }
        // Makes number pad dissappear when you tap somewhere else
//        .onTapGesture {
//                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to:nil, from:nil, for:nil)
//                }
    }
    
    // Make the button gray when it's disabled
    var buttonColor: Color {
        return camera.selectedSite.isEmpty || camera.selectedBlock.isEmpty ? .gray : .white
    }
}

struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView()
    }
}


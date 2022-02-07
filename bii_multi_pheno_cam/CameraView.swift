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
    
    @Published var photo: Photo!
    
    @Published var showAlertError = false
    
    @Published var isFlashOn = false
    
    @Published var willCapturePhoto = true
    
    @Published var isActive = false
    
    @Published var selectedBlock = ""
    
    @Published var selectedSite: String
    
    var alertError: AlertError!
    
    var session: AVCaptureSession
    
    var dataService: DataService
    
    var timer = Timer()
    
    private var subscriptions = Set<AnyCancellable>()
    
    let defaults = UserDefaults.standard
    
    init() {
        self.service = CameraService()
        self.session = service.session
        self.dataService = DataService()
        self.selectedSite = self.defaults.object(forKey: "selectedSite") as? String ?? String()
        
        
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
        service.checkForPermissions()
        service.configure()
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
    
    @objc func timerAction() {
        capturePhoto()
    }
    
    func stopTimedCapture() {
        isActive = false
        timer.invalidate()

        // TODO: Error handling for type coercion
        self.dataService.save(siteId: Int(self.selectedSite) ?? 0, blockId: Int(self.selectedBlock) ?? 0)
        self.defaults.set(self.selectedSite, forKey: "selectedSite")
        self.selectedBlock = ""
        self.service = CameraService()
        self.session = self.service.session
    }
    
    func switchFlash() {
        service.flashMode = service.flashMode == .on ? .off : .on
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
                            camera.configure()
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
                        
                        // the picker view is nicer than these basic text inputs, but more complex to implement
                        // starting with this and can improve later
                        
                        HStack(alignment: .center) {
                            Text("Site ID:")
                                .font(.callout)
                                .bold()
                            
                            TextField("Enter site ID...", text: $camera.selectedSite)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.decimalPad)
                        }
                        .padding()
                        
                        HStack(alignment: .center) {
                            Text("Block ID:")
                                .font(.callout)
                                .bold()
                            TextField("Enter block ID...", text: $camera.selectedBlock)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.decimalPad)
                        }
                        .padding()
                        
    //                    Form {
    //                        Picker("Site ID", selection: $selectedSite) {
    //                            ForEach(siteIds, id: \.self) {
    //                                Text($0)
    //                            }
    //                        }
    //                        Picker("Block ID", selection: $selectedBlock) {
    //                            ForEach(blockIds, id: \.self) {
    //                                Text($0)
    //                            }
    //                        }
    //                    }
    //                        .background(Color.clear)
    //                        .padding(.top, 1)
    //                        .onAppear {
    //                          UITableView.appearance().backgroundColor = .clear
    //                        }
    //                        .onDisappear {
    //                          UITableView.appearance().backgroundColor = .clear
    //                        }
                            
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
        // Makes number pad dissappear when you tap somewhere else
        .onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to:nil, from:nil, for:nil)
                }
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


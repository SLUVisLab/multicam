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
    private let service = CameraService()
    
    @Published var photo: Photo!
    
    @Published var showAlertError = false
    
    @Published var isFlashOn = false
    
    @Published var willCapturePhoto = true
    
    @Published var isActive = false
    
    var alertError: AlertError!
    
    var session: AVCaptureSession
    
    var dataService: DataService
    
    var timer = Timer()
    
    private var subscriptions = Set<AnyCancellable>()
    
    init() {
        self.session = service.session
        self.dataService = DataService()
        
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
    
    func startTimedCapture() {
        isActive = true
        self.dataService.start()
        timer = Timer(timeInterval: 1.0, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
        RunLoop.current.add(timer, forMode: RunLoop.Mode.common)
        timer.tolerance = 0.2
    }
    
    @objc func timerAction() {
        capturePhoto()
    }
    
    func stopTimedCapture() {
        isActive = false
        timer.invalidate()
        for ident in self.dataService.photoCollection!.localIdentifiers {
            print(ident)
        }
        
        self.dataService.save(siteId: 23, blockId: 9)
    }
    
    func switchFlash() {
        service.flashMode = service.flashMode == .on ? .off : .on
    }
}

struct CameraView: View {

    @StateObject var camera = CameraModel()
    @State var currentZoomFactor: CGFloat = 1.0
    @State private var selectedSite = "1501"
    let siteIds = ["1342", "3220", "1501"]
    @State private var selectedBlock = "4"
    let blockIds = ["1", "2", "3", "4", "5", "6", "7"]
    
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
                
                VStack{
                    
                    Form {
                        Picker("Site ID", selection: $selectedSite) {
                            ForEach(siteIds, id: \.self) {
                                Text($0)
                            }
                        }
                        Picker("Block ID", selection: $selectedBlock) {
                            ForEach(blockIds, id: \.self) {
                                Text($0)
                            }
                        }
                    }
                        .background(Color.clear)
                        .padding(.top, 1)
                        .onAppear {
                          UITableView.appearance().backgroundColor = .clear
                        }
                        .onDisappear {
                          UITableView.appearance().backgroundColor = .clear
                        }
                        
                    Spacer()
                        
                    Button(action: {camera.startTimedCapture()}, label: {
                        ZStack{
                            Circle()
                                .fill(Color.white)
                                .frame(width: 65, height: 65)
                            
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                                .frame(width: 75, height: 75)
                        }
                    })
                        .padding(.bottom, 20)
                    
                }
            }
        }
    }
}

struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView()
    }
}


//
//  SettingsView.swift
//  bii_multi_pheno_cam
//
//  Created by Developer on 1/18/22.
//

import Foundation
import SwiftUI
import RealmSwift
import Combine

final class SettingsModel: ObservableObject {
    @Published var cameraDelayEnabled = false
    var delayIntervals = [3, 5, 10, 15]
    @Published var cameraDelay = 0
    let defaults = UserDefaults.standard
    @Published var lastConfigUpdate: Date?
    let dateFormatter: DateFormatter
    
    @ObservedObject var settingsStore = SettingsStore()
    
    init() {
        self.lastConfigUpdate = self.defaults.object(forKey: "lastConfigUpdate") as? Date ?? nil
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateStyle = .medium
        self.dateFormatter.timeStyle = .short
    }
}

struct SettingsView: View {
    @EnvironmentObject var configService: ConfigService
    @StateObject var settings = SettingsModel()
    let dataService = DataService() // Instantiating a new data service here could cause issues when trying to delete photos
    @State private var showingDbWarning = false
    
    var body: some View {
        Form() {
            
            Section(header: Text("Configuration")) {
                Text("**Version:** \(configService.config.version)")
                Text("**Frame Rate:** \(configService.config.frame_rate_seconds) s")
                Text("**Max Resolution:** \(configService.config.max_resolution)")
                Text("**JPEG Compression:** \(configService.config.jpeg_compression_quality)")
                if settings.lastConfigUpdate != nil {
                    Text("Updated \(settings.lastConfigUpdate!, formatter: settings.dateFormatter)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                } else {
                    Text("Unable to determine last configuration update")
                }
                Button("Update Configuration") {
                    print("updating config")
                    configService.updateConfig()
                    settings.lastConfigUpdate = settings.defaults.object(forKey: "lastConfigUpdate") as? Date ?? nil
                }
            }
            
            Section(header: Text("Camera")) {
//                Toggle(isOn: $settings.cameraDelayEnabled) {
//                    Text("Camera Delay")
//                }
//
//                if settings.cameraDelayEnabled {
//                    Picker(selection: $settings.cameraDelay, label: Text( "Seconds")) {
//                        ForEach(0 ..< settings.delayIntervals.count){
//                            Text(String(settings.delayIntervals[$0])).tag($0)
//                        }
//                    }
//                }
                Toggle(isOn: $settings.settingsStore.soundOnForCapture) {
                    Text("**Play Music When Active**")
                }
            }
            	
            Section(header: Text("Gallery")) {
                Toggle(isOn: $settings.settingsStore.deleteImagesAfterUpload) {
                    Text("**Delete Images After Upload**")
                }
            }
            
            Section(header: Text("Database")) {
                if #available(iOS 15.0, *) {
                    Button("Clear Database Cache") {
                        showingDbWarning = true
                    }
                    .alert("Warning: this will erase all locally stored image data", isPresented: $showingDbWarning) {
                        Button("Continue"){
                            dataService.deleteAll()
                        }
                        Button("Cancel", role: .cancel){
                            
                        }
                    }
                } else {
                    // Fallback on earlier versions
                }
            }
        }
        .navigationTitle("Settings")
        
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

//The Following is a workaround to make settings stored in user.default toggle-able
private var cancellables = [String: AnyCancellable]()

extension Published {
    init(defaultValue: Value, key: String) {
        let value = UserDefaults.standard.object(forKey: key) as? Value ?? defaultValue
        self.init(initialValue: value)
        cancellables[key] = projectedValue.sink { val in
            UserDefaults.standard.set(val, forKey: key)
        }
    }
}

class SettingsStore: ObservableObject {
    @Published(defaultValue: false, key: "deleteImagesAfterUpload")
    var deleteImagesAfterUpload: Bool
    
    @Published(defaultValue: true, key: "soundOnForCapture")
    var soundOnForCapture: Bool
}

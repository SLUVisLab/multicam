//
//  SettingsView.swift
//  bii_multi_pheno_cam
//
//  Created by Developer on 1/18/22.
//

import Foundation
import SwiftUI

final class SettingsModel: ObservableObject {
    @Published var cameraDelayEnabled = false
    var delayIntervals = [3, 5, 10, 15]
    @Published var cameraDelay = 0
    let defaults = UserDefaults.standard
    let lastConfigUpdate: Date?
    let dateFormatter: DateFormatter
    
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
    @State private var showingDbWarning = false
    
    var body: some View {
        Form() {
            
            Section(header: Text("Configuration")) {
                Text("**Version:** \(configService.config.version)")
                Text("**Frame Rate:** \(configService.config.frame_rate_milliseconds) ms")
                Text("**Max Resolution:** \(configService.config.max_resolution)")
                if settings.lastConfigUpdate != nil {
                    Text("Updated \(settings.lastConfigUpdate!, formatter: settings.dateFormatter)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                } else {
                    Text("Unable to determine last configuration update")
                }
                Button(action: {}) {
                    Text("Update Configuration")
                }
            }
            
            Section(header: Text("Camera")) {
                Toggle(isOn: $settings.cameraDelayEnabled) {
                    Text("Camera Delay")
                }
                
                if settings.cameraDelayEnabled {
                    Picker(selection: $settings.cameraDelay, label: Text( "Seconds")) {
                        ForEach(0 ..< settings.delayIntervals.count){
                            Text(String(settings.delayIntervals[$0])).tag($0)
                        }
                    }
                }
            }
            Section(header: Text("Database")) {
                if #available(iOS 15.0, *) {
                    Button("Clear Database Cache") {
                        showingDbWarning = true
                    }
                    .alert("Warning: this will erase all locally stored image data", isPresented: $showingDbWarning) {
                        Button("Continue"){
                            
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

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
    
    init() {
        
    }
}

struct SettingsView: View {
    @StateObject var settings = SettingsModel()
    
    var body: some View {
        Form() {
            
            Section() {
                Button(action: {}) {
                    Text("Update Settings")
                }
                Text("Last updated: 10/15/21 5:12pm")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Section() {
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
        }
        .navigationTitle("Settings")
        
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

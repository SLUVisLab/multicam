//
//  bii_multi_pheno_camApp.swift
//  bii_multi_pheno_cam
//
//  Created by Developer on 11/1/21.
//

import SwiftUI
import Firebase

@main
struct bii_multi_pheno_camApp: App {
    let configService = ConfigService(localConfigLoader:LocalConfigLoader())
    let defaults = UserDefaults.standard
    
    init() {
        FirebaseApp.configure()
        
        if(defaults.object(forKey: "deleteImagesAfterUpload") != nil) {
            print("found stored setting...")
        } else {
            defaults.set(true, forKey: "deleteImagesAfterUpload")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(configService)
                .onAppear {
                    self.configService.updateConfig()
                }
        }
    }
}

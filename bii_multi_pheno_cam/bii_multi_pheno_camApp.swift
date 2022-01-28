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
    let configService = ConfigService(localConfigLoader:LocalConfigLoader(),
                                      remoteConfigLoader: RemoteConfigLoader())
    
    init() {
        FirebaseApp.configure()
//        let storage = Storage.storage()
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

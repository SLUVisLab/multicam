//
//  UploadService.swift
//  bii_multi_pheno_cam
//
//  Created by Developer on 12/7/21.
//

import Foundation
import RealmSwift

public class UploadService {
    
    init() {
        
    }
    
    func processCaptureSessions(sessions: Set<ObjectId>) {
        
        for session in sessions {
            print("\(session)")
        }
        
    }
    
}

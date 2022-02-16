//
//  PhotoCaptureSession.swift
//  bii_multi_pheno_cam
//
//  Created by Developer on 12/6/21.
//

import Foundation
import RealmSwift

class PhotoCaptureSession: Object {
    @Persisted(primaryKey: true) var sessionId: ObjectId
    @Persisted var siteId: String
    @Persisted var blockId: String
    @Persisted var sessionStart: Date
    @Persisted var sessionStop: Date
    @Persisted var photoReferences: List<String>
    
    func duration() -> DateComponents {
        return Calendar.current.dateComponents([.minute, .second], from: self.sessionStart, to: self.sessionStop)
    }
}

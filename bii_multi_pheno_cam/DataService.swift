//
//  DataService.swift
//  bii_multi_pheno_cam
//
//  Created by Developer on 12/6/21.
//

import Foundation
import RealmSwift

public struct PhotoCollection {
    public var sessionStart: Date
    public var localIdentifiers: [String]
}

public class DataService {
    @Published public var photoCollection: PhotoCollection?
    
    init() {
//        self.photoCollection = PhotoCollection(sessionStart: Date(), localIdentifiers: [])
    }
    
    func start() {
        self.photoCollection = PhotoCollection(sessionStart: Date(), localIdentifiers: [])
    }
    
    func save(siteId: Int, blockId: Int){
        let realm = try! Realm()
        let photoCaptureSession = PhotoCaptureSession(value: [
            "siteId": siteId,
            "blockId": blockId,
            "sessionStart": self.photoCollection?.sessionStart,
            "sessionStop": Date(),
            "photoReferences": self.photoCollection?.localIdentifiers
        ])
        
        try! realm.write {
            // Add the instance to the realm.
            realm.add(photoCaptureSession)
        }
    }
    
    func deleteAll() {
        let realm = try! Realm()
        
        try! realm.write{
            let sessions = realm.objects(PhotoCaptureSession.self)
            
            realm.delete(sessions)
        }
    }
    
}

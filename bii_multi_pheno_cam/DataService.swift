//
//  DataService.swift
//  bii_multi_pheno_cam
//
//  Created by Developer on 12/6/21.
//

import Foundation
import RealmSwift
import Photos

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
    
    func save(siteId: String, blockId: String){
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
    
    // TODO: func stop dataservice
    
    func deleteAll() {
        let realm = try! Realm()
        
        try! realm.write{
            let sessions = realm.objects(PhotoCaptureSession.self)
            
            realm.delete(sessions)
        }
    }
    
    func delete(sessions: Set<ObjectId>, complettionHandler: @escaping () -> Void) {
        
        let realm = try! Realm()
        let collection = realm.objects(PhotoCaptureSession.self).filter("sessionId IN %@", sessions)
        print("Retrieved Realm Objects...")
        
        var references = [String]()
        
        for session in collection {
            references += Array(session.photoReferences)
        }
        
        let fetchResults = PHAsset.fetchAssets(withLocalIdentifiers: references, options: nil)
        print("Deleting PHAssets...")
        if fetchResults.count > 0 {
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.deleteAssets(fetchResults)
            })
        } else {
            print("Could not locate image assets to delete")
        }
        
        do {
            print("Deleting realm objects...")
            try realm.write {
                
                realm.delete(collection)
            }
        } catch let error {
            print("error deleting realm objects: " + error.localizedDescription)
        }

    }
    
}

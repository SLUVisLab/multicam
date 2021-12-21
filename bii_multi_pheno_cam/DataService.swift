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
    
    // TODO: func stop dataservice
    
    func deleteAll() {
        let realm = try! Realm()
        
        try! realm.write{
            let sessions = realm.objects(PhotoCaptureSession.self)
            
            realm.delete(sessions)
        }
    }
    
    // TODO: Clean up parameters for delete requests. Several options should be available here
    func delete(sessions: Set<ObjectId>, assets: PHFetchResult<PHAsset>? = nil) {
        
        // delete image assets in photo library
//        if assets != nil {
//            PHPhotoLibrary.shared().performChanges({
//                PHAssetChangeRequest.deleteAssets(assets!)
//            })
//        } else {
//
//        }
        
        let realm = try! Realm()
        let sessionz = realm.objects(PhotoCaptureSession.self).filter("sessionId IN %@", sessions)
        for session in sessionz {
            var fetchResults = PHAsset.fetchAssets(withLocalIdentifiers: Array(session.photoReferences), options: nil)
            if fetchResults.count > 0 {
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.deleteAssets(fetchResults)
            })
            } else {
                print("Could not locate assets to delete")
            }
            
        }
        try! realm.write {
                            realm.delete(Array(sessionz))
                        }
//        for session in sessions {
//
//
//            let photoCaptureSession = realm.object(ofType: PhotoCaptureSession.self, forPrimaryKey: session)
//            if let photoCaptureSession = photoCaptureSession {
//                try! realm.write {
//                    realm.delete(photoCaptureSession)
//                }
//            } else {
//                // TODO: Error could not locate photoCaptureSession with id
//                print("Error could not locate photoCaptureSession with id")
//            }
//        }
    }
    
}

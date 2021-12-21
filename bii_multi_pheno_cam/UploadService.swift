//
//  UploadService.swift
//  bii_multi_pheno_cam
//
//  Created by Developer on 12/7/21.
//

import Foundation
import RealmSwift
import Firebase
import FirebaseFirestore
import Photos
import SwiftUI

public class UploadService {
    
    let dataService: DataService
    var sessionId: UUID?
    var siteId: Int?
    var blockId: Int?
    var sessionStart: Date?
    var sessionStop: Date?
    var creationDate: Date?
    var url: URL?
    
    
    init() {
        dataService = DataService()
        sessionId = nil
        siteId = nil
        blockId = nil
        sessionStart = nil
        sessionStop = nil
        creationDate = nil
        url = nil
    }
    
    func upload(sessionIds: Set<ObjectId>) {
        
        let realm = try! Realm()
        let storage = Storage.storage() // this is a reference to firebase cloud storage service
        let db = Firestore.firestore() // this is our reference to the firestore database
        let reference = storage.reference()
        let imagesRef = reference.child("images")
        
        let sessions = realm.objects(PhotoCaptureSession.self).filter("sessionId IN %@", sessionIds)
        
        for session in sessions {
            self.sessionId = UUID()
            print(self.sessionId)
            self.siteId = session.siteId
            self.blockId = session.blockId
            self.sessionStart = session.sessionStart
            self.sessionStop = session.sessionStop
            
            var fetchResults = PHAsset.fetchAssets(withLocalIdentifiers: Array(session.photoReferences), options: nil)

            if fetchResults.count > 0 {

                let requestOptions = PHImageRequestOptions()
                
                for i in 0..<fetchResults.count {
                    
                    // pull metadata from the PHAssets
                    self.creationDate = fetchResults.object(at: i).creationDate
                    
                    // Use local identifier as filename for jpeg. Trim repeating sequences after "/"
                    let idString = fetchResults.object(at: i).localIdentifier.split(separator: "/")
                    let filename = String(idString.first ?? "") + ".jpeg"
                    let fileRef = imagesRef.child(filename)
                    print(filename)
                    
                    PHImageManager.default().requestImageDataAndOrientation(for: fetchResults.object(at: i), options: requestOptions, resultHandler: { (imageData, dataUTI, orientation, info) in
                            if let image = imageData {
                                //successfully retrieved image data from photos
                                let uploadTask = fileRef.putData(image, metadata: nil) { (metadata, error) in
                                    guard let metadata = metadata else {
                                        // TODO: Error uploading jpeg to Firebase Storage
                                        print("Error uploading jpeg to Firebase Storage")
                                        return
                                    }
                                    //successful upload!
                                    fileRef.downloadURL { (url, error) in
                                        guard let url = url else {
                                          // TODO: Error retrieving jpeg url
                                            print("Error retrieving jpeg url")
                                          return
                                        }
                                        //successfully got resource url
                                        self.url = url
                                        var ref: DocumentReference? = nil
                                        ref = db.collection("images").addDocument(data: [
                                            "siteId" : self.siteId,
                                            "blockId" : self.blockId,
                                            "sessionId" : self.sessionId!.uuidString,
                                            "sessionStart" : Timestamp(date: self.sessionStart!),
                                            "sessionStop" : Timestamp(date: self.sessionStop!),
                                            "creationDate" : Timestamp(date: self.creationDate!),
                                            "url" : self.url!.absoluteString
                                        ]) { err in
                                            if let err = err {
                                                //TODO: Error retrieving jpeg url
                                                print("Error retrieving jpeg url")
                                                print(err)
                                            } else {
                                                // Successfully wrote document to firestore
                                                print("Successfully wrote document to firestore!")
                                                
                                            }
                                        }
                                    }
                                }

                            } else {
                                // TODO: Error retrieving image from photos
                                print("Error: Unable to retrieve PHAsset for upload")
                            }
                        }
                    )
                }
            } else {
                // TODO: Error fetching PHAsset with local identifier
                print("Error: Unable to find PHAsset with matching local identifier")
            }
            // TODO: Delete Code Goes Here-ish
            // self.dataService.delete(sessions: sessionIds, assets: fetchResults)
            
        }
    }
}


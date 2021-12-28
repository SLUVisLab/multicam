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
//    var sessionId: UUID?
//    var siteId: Int?
//    var blockId: Int?
//    var sessionStart: Date?
//    var sessionStop: Date?
//    var creationDate: Date?
//    var url: URL?
    @Published var isUploading: Bool
    @Published var statusMessage: String
    
    
    init() {
        dataService = DataService()
//        sessionId = nil
//        siteId = nil
//        blockId = nil
//        sessionStart = nil
//        sessionStop = nil
//        creationDate = nil
//        url = nil
        isUploading = false
        statusMessage = ""
    }
    
    func upload(sessionIds: Set<ObjectId>) {
        self.isUploading = true
        self.statusMessage = "Uploading..."
        let realm = try! Realm()
        let storage = Storage.storage() // this is a reference to firebase cloud storage service
        let db = Firestore.firestore() // this is our reference to the firestore NoSQL database
        let reference = storage.reference()
        let imagesRef = reference.child("images")
        
        var imageUrl: URL?
        var creationDate: Date?
        
        
        // This next chunk groups the photo references from multiple sessions into 1 array. It also flattens the session metadata using multiple dictionaries. It maps array indices matching future fetchAssets results to keys which are mapped to sessionData instances. Refactored from having to run all the remaining upload code for each individual session (multiple db and network calls in a nested for loop -- ick!). Still, I can't tell if this is clever or just wrong. Nixing the extra for loop also made it possible to use the group dispatch easily and have a clear way to tell when all the async calls where complete. If this is ruining your day right now, I'm sorry!
        
        // For Future refactor: Maybe redesigning the data models in the Realm db could make this uneccessary.
        
        var counter = 0 // This becomes dict keys that match the array indices of images in fetchResults
        var keyValue = 0 // Each keyvalue (0, 1, 2, ...n) corresponds to 1 set of session metadata
        var keyMap = [Int:Int]() // maps the above two values to each other. ie Which photos at what index are associated with what metadata
        var sessionDataDictionary = [Int:sessionData]() // Maps a numeric key to each session metadata
        var combinedPhotoReferences = [String]()
        
        let sessions = realm.objects(PhotoCaptureSession.self).filter("sessionId IN %@", sessionIds)
        
        for session in sessions {
            
            combinedPhotoReferences += Array(session.photoReferences)
            
            for index in counter..<counter + combinedPhotoReferences.count {
                keyMap[index] = keyValue
            }
            
            // Realm DB identifiers are type ObjecetId which is difficult to work with so we generate a new uuid
            let newSessionId = UUID()
            let data = sessionData(
                sessionId: newSessionId.uuidString,
                siteId: session.siteId,
                blockId: session.blockId,
                sessionStart: session.sessionStart,
                sessionStop: session.sessionStop
            )
            
            sessionDataDictionary[keyValue] = data
            
            counter += combinedPhotoReferences.count
            keyValue += 1

        }
        
//        for session in sessions {
//            self.sessionId = UUID()
//            print(self.sessionId)
//            self.siteId = session.siteId
//            self.blockId = session.blockId
//            self.sessionStart = session.sessionStart
//            self.sessionStop = session.sessionStop
            
            var fetchResults = PHAsset.fetchAssets(withLocalIdentifiers: combinedPhotoReferences, options: nil)

            if fetchResults.count > 0 {

                let requestOptions = PHImageRequestOptions()
                
                for i in 0..<fetchResults.count {
                    
                    // pull metadata from the PHAssets
                    creationDate = fetchResults.object(at: i).creationDate
                    
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
                                        imageUrl = url
                                        var ref: DocumentReference? = nil
                                        ref = db.collection("images").addDocument(data: [
                                            "siteId" : sessionDataDictionary[keyMap[i]!]!.siteId,
                                            "blockId" : sessionDataDictionary[keyMap[i]!]!.blockId,
                                            "sessionId" : sessionDataDictionary[keyMap[i]!]!.sessionId,
                                            "sessionStart" : Timestamp(date: sessionDataDictionary[keyMap[i]!]!.sessionStart),
                                            "sessionStop" : Timestamp(date: sessionDataDictionary[keyMap[i]!]!.sessionStop),
                                            "creationDate" : Timestamp(date: creationDate!),
                                            "url" : imageUrl!.absoluteString
                                        ]) { err in
                                            if let err = err {
                                                //TODO: Error writing to firestore
                                                print("Error writing to firestore")
                                                print(err)
                                                self.isUploading = false
                                                self.statusMessage = "Error writing to firestore"
                                                
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
                                self.isUploading = false
                                self.statusMessage = "Error: Unable to retrieve PHAsset for upload"
                            }
                        }
                    )
                }
            } else {
                // TODO: Error fetching PHAsset with local identifier
                print("Error: Unable to find PHAsset with matching local identifier")
                self.isUploading = false
                self.statusMessage = "Error: Unable to find PHAsset with matching local identifier"
            }
//        }
    }
}

struct sessionData {
    var sessionId: String
    var siteId: Int
    var blockId: Int
    var sessionStart: Date
    var sessionStop: Date
}


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

public class UploadService: ObservableObject {
    
    let dataService: DataService
    @Published var isUploading: Bool
    @Published var statusMessage: String
    
    
    init() {
        dataService = DataService()
        isUploading = false
        statusMessage = ""
    }
    
    func upload(sessionIds: Set<ObjectId>, max_resolution: Int, jpeg_compression: Double) {
        self.isUploading = true
        self.statusMessage = "Uploading..."
        let realm = try! Realm()
        let storage = Storage.storage() // this is a reference to firebase cloud storage service
        let db = Firestore.firestore() // this is our reference to the firestore NoSQL database
        let reference = storage.reference()
        let imagesRef = reference.child("images")
        let dispatchGroup = DispatchGroup()
        
        let jpegConversionContext = CIContext(options: nil)
        let jpegConversionColorSpace = CGColorSpaceCreateDeviceRGB();
        
        var imageUrl: URL?
        //var creationDate: Date?
        
        
        // This next chunk groups the photo references from multiple sessions into 1 array. It also flattens the session metadata using multiple dictionaries. It maps array indices matching future fetchAssets results to keys which are mapped to sessionData instances. Refactored from having to run all the remaining upload code for each individual session (multiple db and network calls in a nested for loop -- ick!). Still, I can't tell if this is clever or just wrong. Nixing the extra for loop also made it possible to use the group dispatch easily and have a clear way to tell when all the async calls where complete. If this is ruining your day right now, I'm sorry!
        
        // For Future refactor: Maybe redesigning the data models in the Realm db could make this uneccessary. Also -- Could probably wrap this in a class
        
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
            
            // Realm DB identifiers are type ObjecetId which is difficult to work with so we generate a new uuid for each session
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
            
            // upload individual session data to firestore
            var sessionRef: DocumentReference? = nil
            sessionRef = db.collection("sessions").addDocument(data: [
                "siteId" : data.siteId,
                "blockId" : data.blockId,
                "sessionId" : data.sessionId,
                "sessionStart" : Timestamp(date: data.sessionStart),
                "sessionStop" : Timestamp(date: data.sessionStop),
                "imageCount": session.photoReferences.count

            ]) { err in
                if let err = err {
                    //TODO: Error writing to firestore
                    print("Error writing session to firestore")
                    print(err)
                    self.isUploading = false
                    self.statusMessage = "Error writing session to firestore"
                    
                } else {
                    // Successfully wrote document to firestore
                    print("Successfully wrote session document to firestore!")
                    
                }
            }
        }
                 
            var fetchResults = PHAsset.fetchAssets(withLocalIdentifiers: combinedPhotoReferences, options: nil)

            if fetchResults.count > 0 {

                let requestOptions = PHImageRequestOptions()
                requestOptions.deliveryMode = .highQualityFormat
                
                for i in 0..<fetchResults.count {
                    
                    //REPLACED: Now using date from EXIF data
                    // pull metadata from the PHAssets
//                    let creationDate = fetchResults.object(at: i).creationDate
//                    print(creationDate)
                    
                    // Use local identifier as filename for jpeg. Trim repeating sequences after "/"
//                    let idString = fetchResults.object(at: i).localIdentifier.split(separator: "/")
//                    let filename = String(idString.first ?? "") + ".jpeg"
//                    let fileRef = imagesRef.child(filename)
                    //print(filename)
                    
                    dispatchGroup.enter()
//                    PHImageManager.default().requestImage(for: fetchResults.object(at: i),
//                           targetSize: CGSize(width: max_resolution, height: max_resolution),
//                           contentMode: .aspectFit,
//                           options: requestOptions,
//                           resultHandler: {(img, info) in
//                        if let image = img {
//                            if let ciImage = image.ciImage {
//                                print(ciImage.properties)
//                                for (key, value) in ciImage.properties {
//                                    print("key: \(key) - value: \(value)")
//                                }
//                            } else {
//                                print("NO CIIMAGE AVAILABLE")
//                            }
//                            if let imageData = image.jpegData(compressionQuality: jpeg_compression) {
                    
                    // This current approach takes raw image data, converts it to both UI image(for resizing and exporting as jpeg) and CI Image (for exif data)
                    // I think using a couple different techniques this could be simplified to ONLY need the CI Image. It makes sense.
                    // https://stackoverflow.com/questions/61589783/resize-ciimage-to-an-exact-size
                    // https://developer.apple.com/documentation/coreimage/cicontext/1642214-jpegrepresentation
                    
                    PHImageManager.default().requestImageDataAndOrientation(for: fetchResults.object(at: i),
                                                                               options: requestOptions,
                                                                               resultHandler: {(data, filename, orientation, info) in
                        if let data = data {
                            var lensModel: String?
                            var filename = ""
                            var creationDate: Date?
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy:MM:dd' 'HH:mm:ss"
                            dateFormatter.timeZone = TimeZone.current
                            dateFormatter.locale = Locale.current
                            
                            if let wrappedImage = CIImage(data: data) {
                                if let exif = wrappedImage.properties["{Exif}"] as? [String:Any] {
                                    if let timeStamp = exif["DateTimeOriginal"] as? String {
                                        creationDate = dateFormatter.date(from: timeStamp)
                                        let timeStampNoSpace = timeStamp.replacingOccurrences(of: " ", with: "T")
                                        filename += timeStampNoSpace + "_"
                                        print(timeStamp)
                                    }
                                    if let lens = exif["LensModel"] as? String {
                                        lensModel = lens
                                        let lensModelShort = lens.replacingOccurrences(of: "iPhone 12 Pro back camera ", with: "")
                                        let lensModelNoSpace = lensModelShort.replacingOccurrences(of: " ", with: "_")
                                        let lensModelNoSlash = lensModelNoSpace.replacingOccurrences(of: "/", with: ":")
                                        filename += lensModelNoSlash + "_"
                                        print(lens)
                                    }
                                } else {
                                    //TODO: Could not find EXIF Data
                                    print("Error: No EXIF Data found")
                                }
                                
                                let rand = String(Int.random(in: 100..<1000))
                                filename += String(sessionDataDictionary[keyMap[i]!]!.siteId) + "_" + String(sessionDataDictionary[keyMap[i]!]!.blockId) + "_" + rand + ".jpeg"
                                print(filename)
                                
                                let fileRef = imagesRef.child(filename)
                                
                                if let jpegImage = jpegConversionContext.jpegRepresentation(of: wrappedImage, colorSpace: jpegConversionColorSpace, options: [:]) {
                                
                                    let uploadTask = fileRef.putData(jpegImage, metadata: nil) { (metadata, error) in
                                        guard let metadata = metadata else {
                                            // TODO: Error uploading jpeg to Firebase Storage
                                            print("Error uploading jpeg to Firebase Storage")
                                            dispatchGroup.leave()
                                            return
                                        }
                                        //successful upload!
                                        fileRef.downloadURL { (url, error) in
                                            guard let url = url else {
                                              // TODO: Error retrieving jpeg url
                                                print("Error retrieving jpeg url")
                                                dispatchGroup.leave()
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
                                                "lensModel" : lensModel,
                                                "url" : imageUrl!.absoluteString
                                            ]) { err in
                                                if let err = err {
                                                    //TODO: Error writing to firestore
                                                    print("Error writing to firestore")
                                                    print(err)
                                                    self.isUploading = false
                                                    self.statusMessage = "Error writing to firestore"
                                                    dispatchGroup.leave()
                                                    
                                                } else {
                                                    // Successfully wrote document to firestore
                                                    dispatchGroup.leave()
                                                    print("Successfully wrote document to firestore!")
                                                }
                                            }
                                        }
                                    }
                                
                                } else {
                                    print("Error: Failed to convert to jpeg")
                                    dispatchGroup.leave()
                                    return
                                }
                                
                            } else {
                                //TODO: CI Image conversion failed
                                print("Error: Failed to convert data object to CIImage")
                            }
                            
                        } else {
                            // TODO: Error retrieving image from photos
                            print("Error: Unable to retrieve image from Photos")
                            self.isUploading = false
                            self.statusMessage = "Error: Unable to retrieve image from Photos"
                            dispatchGroup.leave()
                        }
                    })
                    
                    
// ****** Below is the original upload code which used the largest available image size that PHImageManager could provide. It's been replaced by the above code which allows for variable size and quality. Leaving here for reference for now *************
                    
//                    PHImageManager.default().requestImageDataAndOrientation(for: fetchResults.object(at: i), options: requestOptions, resultHandler: { (imageData, dataUTI, orientation, info) in
//                            if let image = imageData {
//                                //successfully retrieved image data from photos
//                                let uploadTask = fileRef.putData(image, metadata: nil) { (metadata, error) in
//                                    guard let metadata = metadata else {
//                                        // TODO: Error uploading jpeg to Firebase Storage
//                                        print("Error uploading jpeg to Firebase Storage")
//                                        dispatchGroup.leave()
//                                        return
//                                    }
//                                    //successful upload!
//                                    fileRef.downloadURL { (url, error) in
//                                        guard let url = url else {
//                                          // TODO: Error retrieving jpeg url
//                                            print("Error retrieving jpeg url")
//                                            dispatchGroup.leave()
//                                          return
//                                        }
//                                        //successfully got resource url
//                                        imageUrl = url
//                                        var ref: DocumentReference? = nil
//                                        ref = db.collection("images").addDocument(data: [
//                                            "siteId" : sessionDataDictionary[keyMap[i]!]!.siteId,
//                                            "blockId" : sessionDataDictionary[keyMap[i]!]!.blockId,
//                                            "sessionId" : sessionDataDictionary[keyMap[i]!]!.sessionId,
//                                            "sessionStart" : Timestamp(date: sessionDataDictionary[keyMap[i]!]!.sessionStart),
//                                            "sessionStop" : Timestamp(date: sessionDataDictionary[keyMap[i]!]!.sessionStop),
//                                            "creationDate" : Timestamp(date: creationDate!),
//                                            "url" : imageUrl!.absoluteString
//                                        ]) { err in
//                                            if let err = err {
//                                                //TODO: Error writing to firestore
//                                                print("Error writing to firestore")
//                                                print(err)
//                                                self.isUploading = false
//                                                self.statusMessage = "Error writing to firestore"
//                                                dispatchGroup.leave()
//
//                                            } else {
//                                                // Successfully wrote document to firestore
//                                                dispatchGroup.leave()
//                                                print("Successfully wrote document to firestore!")
//
//                                            }
//                                        }
//                                    }
//                                }
//
//                            } else {
//                                // TODO: Error retrieving image from photos
//                                print("Error: Unable to retrieve PHAsset for upload")
//                                self.isUploading = false
//                                self.statusMessage = "Error: Unable to retrieve PHAsset for upload"
//                                dispatchGroup.leave()
//                            }
//                        }
//                    )
                }
                
                dispatchGroup.notify(queue: .main){
                    
                    print("Finished Uploading!")
                    self.isUploading = false
                    
                    if(UserDefaults.standard.object(forKey: "deleteImagesAfterUpload") as? Bool ?? true) {
                        self.dataService.delete(sessions: sessionIds) {
                            print("Finished Deleting!")
                        }
                    }
                    
                    

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
    var siteId: String
    var blockId: String
    var sessionStart: Date
    var sessionStop: Date
}

extension UIImage {
    func scalePreservingAspectRatio(targetSize: CGSize) -> UIImage {
        //convert pixel value to point value based on device scale
        let pointWidth = targetSize.width / UIScreen.main.scale
        let pointHeight = targetSize.height / UIScreen.main.scale
        
        // Determine the scale factor that preserves aspect ratio
        let widthRatio = pointWidth / size.width
        let heightRatio = pointHeight / size.height
        let scaleFactor = min(widthRatio, heightRatio)
        print(UIScreen.main.scale)
        
        
        // Compute the new image size that preserves aspect ratio
        let scaledImageSize = CGSize(
            width: size.width * scaleFactor,
            height: size.height * scaleFactor
        )

        // Draw and return the resized UIImage
        let renderer = UIGraphicsImageRenderer(
            size: scaledImageSize
        )

        let scaledImage = renderer.image { _ in
            self.draw(in: CGRect(
                origin: .zero,
                size: scaledImageSize
            ))
        }
        
        return scaledImage
    }
}

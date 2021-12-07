//
//  GalleryView.swift
//  bii_multi_pheno_cam
//
//  Created by Developer on 11/1/21.
//

import SwiftUI
import Photos
import RealmSwift

final class GalleryModel: ObservableObject {
    var fetchResults: PHFetchResult<PHAsset>!
    var testImageIdentifier: String
    @Published var testImage: UIImage
    
    let realm = try! Realm()
    var results: Results<PhotoCaptureSession>
    var sortedResults: Results<PhotoCaptureSession>
    
    init() {
        self.testImageIdentifier = "ECABE30F-64CA-4B94-A319-8FC6442C6077/L0/001"
        self.fetchResults = PHAsset.fetchAssets(withLocalIdentifiers: [self.testImageIdentifier], options: nil)
        self.testImage = UIImage()
        self.results = realm.objects(PhotoCaptureSession.self)
        self.sortedResults = results.sorted(byKeyPath: "sessionStart", ascending: false)
        // Note that if the request is not set to synchronous
        // the requestImageForAsset will return both the image
        // and thumbnail; by setting synchronous to true it
        // will return just the thumbnail
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        
        // Perform the image request
        PHImageManager.default().requestImage(for: fetchResults.object(at: 0) as PHAsset, targetSize: CGSize(width: 100.0, height: 100.0), contentMode: PHImageContentMode.aspectFill, options: requestOptions, resultHandler: { (image, _) in
                if let image = image {
                    // Add the returned image to your array
                    self.testImage = image
                } else {
                    print("Error Fetching Image for Gallery")
                }
            }
        )
    }
    
    // FIX ME: Error Handling and thumbnail size
    func getThumbnail(localIdentfier: String) -> UIImage {
        var thumbnail = UIImage()
        var fetchResults = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentfier], options: nil)
        
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        
        PHImageManager.default().requestImage(for: fetchResults.object(at: 0) as PHAsset, targetSize: CGSize(width: 100.0, height: 100.0), contentMode: PHImageContentMode.aspectFill, options: requestOptions, resultHandler: { (image, _) in
                if let image = image {
                    // Add the returned image to your array
                    thumbnail = image
                    
                } else {
                    print("error")
                }
            }
        )
        
        if thumbnail != nil {
            return thumbnail
        }
        
        print("Error Fetching Image")
        return thumbnail
        
    }
    
}

struct GalleryView: View {
    //var dates: [DateGrouping] = CaptureList.recent
    @StateObject var gallery = GalleryModel()
    let dateFormatter: DateFormatter
    
    init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short
    }
    
    var body: some View {
//        HStack(){
//            Image(uiImage: gallery.testImage)
//        }
        
        List(gallery.sortedResults, id: \.sessionId) {result in
            HStack() {
                // TODO: Fix optional data type issue. Should not have to pass "empty". Temporary hack
                Image(uiImage: gallery.getThumbnail(localIdentfier: result.photoReferences.first ?? "empty"))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 70)
                    .cornerRadius(4)
                    .padding(.vertical, 4)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(verbatim: "Block " + String(result.blockId))
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .minimumScaleFactor(0.5)
                    
                    Text(result.sessionStart, formatter: dateFormatter)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text(String(result.photoReferences.count) + " images")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                }
                
            }
        }
        .navigationTitle("Gallery")

    }
}

struct GalleryView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            GalleryView()
        }
    }
}

//
//  GalleryView.swift
//  bii_multi_pheno_cam
//
//  Created by Developer on 11/1/21.
//

import SwiftUI
import Photos

final class GalleryModel: ObservableObject {
    var fetchResults: PHFetchResult<PHAsset>!
    var testImageIdentifier: String
    @Published var testImage: UIImage
    
    init() {
        self.testImageIdentifier = "ECABE30F-64CA-4B94-A319-8FC6442C6077/L0/001"
        self.fetchResults = PHAsset.fetchAssets(withLocalIdentifiers: [self.testImageIdentifier], options: nil)
        self.testImage = UIImage()
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
}

struct GalleryView: View {
    var dates: [DateGrouping] = CaptureList.recent
    @StateObject var gallery = GalleryModel()
    
    var body: some View {
        HStack(){
            Image(uiImage: gallery.testImage)
        }

//        List(dates, id: \.id) {date in
//
//            Spacer()
//
//            Text(date.date)
//                .fontWeight(.semibold)
//
//            ForEach(date.captures, id: \.id) {capture in
//                HStack() {
//                    Image(capture.imageName)
//                        .resizable()
//                        .scaledToFit()
//                        .frame(width: 120, height: 70)
//                        .cornerRadius(4)
//                        .padding(.vertical, 4)
//
//                    VStack(alignment: .leading, spacing: 5) {
//                        Text(verbatim: "Plot " + String(capture.plotID))
//                            .fontWeight(.semibold)
//                            .lineLimit(2)
//                            .minimumScaleFactor(0.5)
//
//                        Text(String(capture.imageCount) + " images")
//                            .font(.subheadline)
//                            .foregroundColor(.secondary)
//
//                        Text(String(capture.captureTime))
//                            .font(.subheadline)
//                            .foregroundColor(.secondary)
//
//                    }
//                }
//            }
//
//        }
//        .navigationTitle("Gallery")
    }
}

struct GalleryView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            GalleryView()
        }
    }
}

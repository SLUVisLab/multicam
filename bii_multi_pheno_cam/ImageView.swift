//
//  ImageView.swift
//  bii_multi_pheno_cam
//
//  Created by Developer on 5/17/22.
//

import Foundation
import SwiftUI
import Photos
import RealmSwift


struct ImageView: View {
    
    
    var session: PhotoCaptureSession
    var fetchResults: PHFetchResult<PHAsset>
    var indexes: [Int]
    
    @State private var currentIndex: Int
    
    init(session: PhotoCaptureSession, index: Int) {
        self.currentIndex = index
        self.session = session
        self.fetchResults = PHAsset.fetchAssets(withLocalIdentifiers: Array(session.photoReferences), options: nil)
        self.indexes = (0..<fetchResults.count).map{$0}
    }
    
    func getImage(index: Int) -> UIImage {
        
        var imageItem = UIImage(named: "missing-image")
        
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        
        PHImageManager.default().requestImage(for: self.fetchResults.object(at: index) as PHAsset, targetSize: CGSize(width: 360.0, height: 360.0), contentMode: PHImageContentMode.aspectFill, options: requestOptions, resultHandler: { (image, _) in
                if let image = image {
                    // Successfully retrieved thumbnail
                    imageItem = image
                    
                } else {
                    print("Error: Unable to retrieve image for PHAsset")
                }
            }
        )
        
        return imageItem!
    }
   
    var body: some View {
        
        TabView(selection: $currentIndex) {
            ForEach(indexes, id: \.self) { index in
                Image(uiImage: getImage(index: index))
                    .resizable()
                    //.scaledToFit()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 360)
//                    .cornerRadius(3)
            }
        }.tabViewStyle(PageTabViewStyle())

    }
}

//
//  SessionView.swift
//  bii_multi_pheno_cam
//
//  Created by Developer on 12/30/21.
//

import Foundation
import SwiftUI
import Photos
import RealmSwift


struct SessionView: View {
    
    var session: PhotoCaptureSession
    var fetchResults: PHFetchResult<PHAsset>
    let columns =  [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    var indexes: [Int]
    
    init(session: PhotoCaptureSession) {
        self.session = session
        self.fetchResults = PHAsset.fetchAssets(withLocalIdentifiers: Array(session.photoReferences), options: nil)
        self.indexes = (0..<fetchResults.count).map{$0}
    }
    
    func getThumbnail(index: Int) -> UIImage {
        
        var thumbnail = UIImage(named: "missing-image")
        
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        
        PHImageManager.default().requestImage(for: self.fetchResults.object(at: index) as PHAsset, targetSize: CGSize(width: 120.0, height: 120.0), contentMode: PHImageContentMode.aspectFill, options: requestOptions, resultHandler: { (image, _) in
                if let image = image {
                    // Successfully retrieved thumbnail
                    thumbnail = image
                    
                } else {
                    print("Error: Unable to retrieve thumbnail for PHAsset")
                }
            }
        )
        
        return thumbnail!
    }
    
    var body: some View {
        
        ScrollView {
            
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(indexes, id: \.self) { index in
                    Image(uiImage: getThumbnail(index: index))
                        .resizable()
                        //.scaledToFit()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120)
                            .cornerRadius(3)
                    
                }
                
            }
            .padding(.horizontal)
        }
    }
}

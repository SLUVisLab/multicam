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
    @Published var selection = Set<ObjectId>()
//    @State var selection = Set<ObjectId>()
//    @Published var isEditing: Bool = false
    @Published var editMode: EditMode = .inactive
    
    
    let realm = try! Realm()
    var results: Results<PhotoCaptureSession>
    var sortedResults: Results<PhotoCaptureSession>
    @Published var uploadService : UploadService
    let dataService: DataService
//    var dateReference: Date
    let isUploading: Bool
    
    init() {

        self.results = realm.objects(PhotoCaptureSession.self)
        self.sortedResults = results.sorted(byKeyPath: "sessionStart", ascending: false)
        self.uploadService = UploadService()
        self.dataService = DataService()
//        self.dateReference = Date()
        self.isUploading = true

    }
    
    // TODO: Add empty image placeholder to assets. Match size and aspect ratio of normal captures.
    // TODO: Update thumbail sizes to maintain original aspect ratio
    func getThumbnail(localIdentfier: String) -> UIImage {
        // Initialize to empty image placeholder
        var thumbnail = UIImage(named: "missing-image")
        
        // TODO: This is janky way to handle instances where no photo identifier can be found. Consider refactor
        // TODO: Consider throwing actual errors or setting up a logger instead of print
        if localIdentfier != "empty" {
            var fetchResults = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentfier], options: nil)
            
            if fetchResults.count > 0 {
                // Note that if the requestOptions is not set to synchronous
                // the requestImageForAsset will return both the image
                // and thumbnail; by setting synchronous to true it
                // will return just the thumbnail
                let requestOptions = PHImageRequestOptions()
                requestOptions.isSynchronous = true
                
                PHImageManager.default().requestImage(for: fetchResults.object(at: 0) as PHAsset, targetSize: CGSize(width: 120.0, height: 120.0), contentMode: PHImageContentMode.aspectFill, options: requestOptions, resultHandler: { (image, _) in
                        if let image = image {
                            // Successfully retrieved thumbnail
                            thumbnail = image
                            
                        } else {
                            print("Error: Unable to retrieve thumbnail for PHAsset")
                        }
                    }
                )
            } else {
                print("Error: Unable to find PHAsset with matching local identifier")
            }
        } else {
            print("Error: Empty local identifier for PHAsset. Using placeholder instead")
        }
        return thumbnail!
    }
}

struct GalleryView: View {

    @StateObject var gallery = GalleryModel()
    let timeFormatter: DateFormatter
//    let shortDateFormatter: DateFormatter
//    @State var isEditing: Bool = false
    
    
        
    init() {
        timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short
        
//        shortDateFormatter = DateFormatter()
//        shortDateFormatter.dateFormat = "E, MMM d"
        
//        dateReference = Date()
    }
    
    var body: some View {
        ZStack {
            List(gallery.sortedResults, id: \.sessionId, selection: $gallery.selection) {result in

                HStack() {
    //
    //                if Calendar.current.dateComponents([.day], from: gallery.dateReference, to: result.sessionStart).day! > 1 {
    //                    Spacer()
    //                    Text(result.sessionStart, formatter: shortDateFormatter)
    //                    gallery.dateReference = result.sessionStart
    //                }
                    
                    // TODO: This is janky way to handle instances where no photo identifier can be found. Consider refactor
                    Image(uiImage: gallery.getThumbnail(localIdentfier: result.photoReferences.first ?? "empty"))
                        .resizable()
                        //.scaledToFit()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120)
                        .cornerRadius(4)
                        .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(verbatim: "Block " + String(result.blockId))
                            .fontWeight(.semibold)
                            .lineLimit(2)
                            .minimumScaleFactor(0.5)

                        Text(result.sessionStart, formatter: timeFormatter)
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text(String(result.photoReferences.count) + " images")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                    }

                }
            }
            
            if gallery.uploadService.isUploading {
                UploadingView()
//                ZStack {
//
//                    Color(.white)
//                        .ignoresSafeArea()
//                        .opacity(0.8)
//
//                    VStack{
//
//                        ProgressView()
//                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
//                            .scaleEffect(5)
//
//                        Text("Uploading...")
//
//                    }
//                }
            }
        }
            .navigationTitle("Gallery")
            .toolbar{
                ToolbarItem(placement: .navigationBarTrailing) {
                    // EditButton() is the default way to toggle List views in and out of edit mode. The custom implementation of the button allows us to change it's default text to "select" instead of "edit" - not sure if it's worth the hassle. Disable all gallery.editMode related code to restore the simpler version.
//                    EditButton()
                    Button(action: {
                        if gallery.editMode == .active {
                            gallery.editMode = .inactive
                            gallery.selection = Set<ObjectId>()
                        } else {
                            gallery.editMode = .active
                        }
                    }) {
                        if gallery.editMode == .active {
                            Text("Done")
                        } else {
                            Text("Select")
                        }
                    }
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    if gallery.editMode == .active {
                        Button("Upload") {
                            print("Upload")
                            gallery.uploadService.upload(sessionIds: gallery.selection)
                            gallery.editMode = .inactive
                            gallery.selection = Set<ObjectId>()

                        }

                        Button("Delete") {
                            print("Delete")
                            gallery.dataService.delete(sessions: gallery.selection)
                            gallery.editMode = .inactive
                            gallery.selection = Set<ObjectId>()
                        }
                    }
                }
            }
            .environment(\.editMode, $gallery.editMode)
            
    }
}

struct GalleryView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            GalleryView()
        }
    }
}

struct UploadingView: View {
    var body: some View {
        ZStack {
            
            Color(.white)
                .ignoresSafeArea()
                .opacity(0.8)
            
            VStack{
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .scaleEffect(3)
                    .padding()
                Text("Uploading...")
                
            }
        }
        
    }
}

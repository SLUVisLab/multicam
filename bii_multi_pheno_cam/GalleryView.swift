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
    
    // TODO: refactor data service out of gallerymodel and instantiate it in the view?
    let dataService: DataService
//    var dateReference: Date
    @Published var isUpdating: Bool
    
    init() {

        self.results = self.realm.objects(PhotoCaptureSession.self)
        self.sortedResults = results.sorted(byKeyPath: "sessionStart", ascending: false)
//        self.uploadService = UploadService()
        self.dataService = DataService()
//        self.dateReference = Date()
        self.isUpdating = false

    }
    
    // if you don't retreive a fresh set of objects from the realm database after deleting some it crashes
    func updateResults() {
        self.results = self.realm.objects(PhotoCaptureSession.self)
        self.sortedResults = results.sorted(byKeyPath: "sessionStart", ascending: false)
    }
    
    func getThumbnail(localIdentfier: String) -> UIImage {
        // Initialize to empty image placeholder
        var thumbnail = UIImage(named: "missing-image")
        
        if localIdentfier != "empty" {
            var fetchResults = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentfier], options: nil)
            
            if fetchResults.count > 0 {
                // Note that if the requestOptions is not set to synchronous
                // the requestImageForAsset will return both the image
                // and thumbnail; by setting synchronous to true it
                // will return just the thumbnail
                let requestOptions = PHImageRequestOptions()
                
                // could probably set this to false and use the degraded thumbnail image...
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
    @EnvironmentObject var configService: ConfigService
    @StateObject var gallery = GalleryModel()
    @StateObject var uploadService = UploadService()
    
    let timeFormatter: DateFormatter
    let durationFormatter: DateComponentsFormatter
//    let shortDateFormatter: DateFormatter
//    @State var isEditing: Bool = false
    
    
        
    init() {
        
        timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short
        
        durationFormatter = DateComponentsFormatter()
        durationFormatter.unitsStyle = .abbreviated
        durationFormatter.allowedUnits = [.minute, .second]
        durationFormatter.zeroFormattingBehavior = .dropAll
        
//        shortDateFormatter = DateFormatter()
//        shortDateFormatter.dateFormat = "E, MMM d"
        
//        dateReference = Date()
    }
    
    var body: some View {
        ZStack {
            List(gallery.sortedResults, id: \.sessionId, selection: $gallery.selection) {result in
                
                if !gallery.isUpdating {
                    NavigationLink(destination: SessionView(session: result)) {
                        HStack() {
            //
            //                if Calendar.current.dateComponents([.day], from: gallery.dateReference, to: result.sessionStart).day! > 1 {
            //                    Spacer()
            //                    Text(result.sessionStart, formatter: shortDateFormatter)
            //                    gallery.dateReference = result.sessionStart
            //                }
                            
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
                                
                                Text("Site: " + String(result.siteId))
                                
                                Spacer()

                                Text(result.sessionStart, formatter: timeFormatter)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                Text(String(result.photoReferences.count) + " images")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text(durationFormatter.string(from: result.duration())!)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                            }
                            .padding()

                        }
                    }
                }
            }
            
            if uploadService.isUploading {
                
                UploadingView()

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
                            gallery.isUpdating = true
                            //TODO: clean up variable initialization? Log an error when casting fails and uses fallback value
                            uploadService.upload(sessionIds: gallery.selection,
                                                 max_resolution: Int(configService.config.max_resolution) ?? 1024,
                                                 jpeg_compression: Double(configService.config.jpeg_compression_quality) ?? 0.8)
                            gallery.updateResults()
                            gallery.editMode = .inactive
                            gallery.selection = Set<ObjectId>()
                            gallery.isUpdating = false

                        }

                        Button("Delete") {
                            print("Delete")
                            gallery.isUpdating = true
                            gallery.dataService.delete(sessions: gallery.selection){
                                print("finished deleting...")
                            }
                            gallery.updateResults()
                            gallery.editMode = .inactive
                            gallery.selection = Set<ObjectId>()
                            gallery.isUpdating = false
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

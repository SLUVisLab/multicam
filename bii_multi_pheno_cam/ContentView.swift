//
//  ContentView.swift
//  bii_multi_pheno_cam
//
//  Created by Developer on 11/1/21.
//

import SwiftUI

final class ContentModel: ObservableObject {
    
    var dataService: DataService
 
    init() {
        self.dataService = DataService()
    }
}

struct ContentView: View {
    @StateObject var content = ContentModel()
    
    var body: some View {
        NavigationView{
            VStack{
                NavigationLink(destination: CameraView()){
                    Text("Capture")
                        .bold()
                        .frame(width: 280, height: 50)
                        .background(Color.green)
                        .foregroundColor(Color.white)
                        .cornerRadius(10)
                        .padding()
                }
                
                NavigationLink(destination: GalleryView()){
                    Text("Gallery")
                        .bold()
                        .frame(width: 280, height: 50)
                        .background(Color.green)
                        .foregroundColor(Color.white)
                        .cornerRadius(10)
                }
                
                Button(action: {content.dataService.deleteAll()}) {
                    Text(verbatim: "Clear Database")
                        .foregroundColor(.black)
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

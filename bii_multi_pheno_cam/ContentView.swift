//
//  ContentView.swift
//  bii_multi_pheno_cam
//
//  Created by Developer on 11/1/21.
//

import SwiftUI

final class ContentModel: ObservableObject {
    
//    var dataService: DataService
 
    init() {
//        self.dataService = DataService()
    }
}

struct ContentView: View {
    @EnvironmentObject var configService: ConfigService
    @StateObject var content = ContentModel()
    
    var body: some View {
        NavigationView{
            VStack{
                NavigationLink(destination: CameraView().environmentObject(configService)){
                    Text("Capture")
                        .bold()
                        .frame(width: 280, height: 50)
                        .background(Color("button-color"))
                        .foregroundColor(Color.white)
                        .cornerRadius(10)
                        .padding()
                }
                
                NavigationLink(destination: GalleryView().environmentObject(configService)){
                    Text("Gallery")
                        .bold()
                        .frame(width: 280, height: 50)
                        .background(Color("button-color"))
                        .foregroundColor(Color.white)
                        .cornerRadius(10)
                }
//                Button(action: {content.dataService.deleteAll()}) {
//                    Text(verbatim: "Clear Database")
//                        .foregroundColor(.black)
//                }
            }
                .toolbar{
                    ToolbarItem(placement: .navigationBarTrailing){
                        NavigationLink(destination: SettingsView().environmentObject(configService)){
                            Image(systemName: "gearshape.fill")
                                .resizable()
                                .scaledToFit()
//                                .font(.system(size: 32.0))
//                                .padding()
                        }
                        .buttonStyle(PlainButtonStyle())
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

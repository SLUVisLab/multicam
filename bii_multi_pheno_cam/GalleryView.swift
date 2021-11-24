//
//  GalleryView.swift
//  bii_multi_pheno_cam
//
//  Created by Developer on 11/1/21.
//

import SwiftUI

struct GalleryView: View {
    var dates: [DateGrouping] = CaptureList.recent
    
    var body: some View {

        List(dates, id: \.id) {date in
            
            Spacer()
            
            Text(date.date)
                .fontWeight(.semibold)
            
            ForEach(date.captures, id: \.id) {capture in
                HStack() {
                    Image(capture.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 70)
                        .cornerRadius(4)
                        .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(verbatim: "Plot " + String(capture.plotID))
                            .fontWeight(.semibold)
                            .lineLimit(2)
                            .minimumScaleFactor(0.5)

                        Text(String(capture.imageCount) + " images")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text(String(capture.captureTime))
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                    }
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

//
//  Capture.swift
//  bii_multi_pheno_cam
//
//  Created by Developer on 11/9/21.
//

import SwiftUI

struct Capture:Identifiable {
    let id =  UUID()
    let imageName: String
    let captureDate: String
    let captureTime: String
    let plotID: Int
    let imageCount: Int
    let duration: Int
    let uploaded: Bool
}

struct DateGrouping: Identifiable {
    let id = UUID()
    let date: String
    let captures: [Capture]
}

struct CaptureList {
    static let resourceNames = [
       "ECABE30F-64CA-4B94-A319-8FC6442C6077/L0/001",
       "FA8CC18A-DBE3-40EB-A309-632B9B7461BE/L0/001",
       "40BD42E1-9CD0-4B7C-A1B8-A113366B14B5/L0/001"
    ]
    static let recent = [
        DateGrouping (
            date : "Friday Nov. 11, 2021",
            captures: [
                Capture(imageName: "plot1", captureDate: "11-21-21", captureTime: "12:15pm", plotID: 12, imageCount: 1023, duration: 24, uploaded: true),
                Capture(imageName: "plot2", captureDate: "11-21-21", captureTime: "1:32pm", plotID: 14, imageCount: 981, duration: 6, uploaded: false),
                Capture(imageName: "plot3", captureDate: "11-23-21", captureTime: "9:45am", plotID: 5, imageCount: 2345, duration: 12, uploaded: true),
            ]
        ),
        DateGrouping (
            date : "Sunday Nov. 18, 2021",
            captures: [
                Capture(imageName: "plot3", captureDate: "11-23-21", captureTime: "9:45am", plotID: 5, imageCount: 2345, duration: 12, uploaded: true),
                Capture(imageName: "plot1", captureDate: "11-24-21", captureTime: "2:15pm", plotID: 4, imageCount: 1503, duration: 24, uploaded: true),
                Capture(imageName: "plot2", captureDate: "11-27-21", captureTime: "4:32pm", plotID: 1, imageCount: 9801, duration: 6, uploaded: false),
                Capture(imageName: "plot3", captureDate: "11-27-21", captureTime: "11:45am", plotID: 5, imageCount: 235, duration: 12, uploaded: false),
                Capture(imageName: "plot1", captureDate: "11-21-21", captureTime: "12:15pm", plotID: 12, imageCount: 1023, duration: 24, uploaded: false),
                Capture(imageName: "plot2", captureDate: "11-21-21", captureTime: "1:32pm", plotID: 14, imageCount: 981, duration: 6, uploaded: false),
            ]
        ),
        DateGrouping (
            date : "Monday Nov. 17, 2021",
            captures: [
                Capture(imageName: "plot3", captureDate: "11-23-21", captureTime: "9:45am", plotID: 5, imageCount: 2345, duration: 12, uploaded: false),
                Capture(imageName: "plot1", captureDate: "11-24-21", captureTime: "2:15pm", plotID: 4, imageCount: 1503, duration: 24, uploaded: false),
                Capture(imageName: "plot2", captureDate: "11-27-21", captureTime: "4:32pm", plotID: 1, imageCount: 9801, duration: 6, uploaded: false),
                Capture(imageName: "plot3", captureDate: "11-27-21", captureTime: "11:45am", plotID: 5, imageCount: 235, duration: 12, uploaded: false)
            ]
        )
    ]
}

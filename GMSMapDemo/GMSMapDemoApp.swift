//
//  GMSMapDemoApp.swift
//  GMSMapDemo
//
//  Created by wxliu on 2024/5/7.
//

import SwiftUI

@main
struct GMSMapDemoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            GMSMapContentView()
        }
    }
}

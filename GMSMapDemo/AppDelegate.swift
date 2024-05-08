//
//  AppDelegate.swift
//  GMSMapDemo
//
//  Created by wxliu on 2024/5/7.
//

import SwiftUI
import GoogleMaps

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // 初始化 Google 地图服务
        GMSServices.provideAPIKey(GMSMapHelper.APIKey)

        return true
    }
}

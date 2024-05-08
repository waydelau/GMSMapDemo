//
//  GMSMapLocationManager.swift
//  GMSMapDemo
//
//  Created by wxliu on 2024/5/7.
//

import Foundation
import CoreLocation
import RxSwift

class GMSMapLocationManager: NSObject, ObservableObject {

    private let locationManager = CLLocationManager()
    private let disposeBag = DisposeBag()
    
    private(set) var lastKnownLocationSubject = PublishSubject<CLLocation>()
    private(set) var authorizationStatusSubject = BehaviorSubject<CLAuthorizationStatus>(value: .notDetermined)
    private(set) var locationErrorSubject = PublishSubject<Error>()

    private override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.allowsBackgroundLocationUpdates = true
        // 请求定位权限
        let status = locationManager.authorizationStatus
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            break
        case .restricted, .denied:
            break
        default:
            locationManager.startUpdatingLocation()
            break
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension GMSMapLocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // 处理位置更新事件
        if let location = locations.last {
            lastKnownLocationSubject.onNext(location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // 处理定位错误事件
        print("Location manager failed with error: \(error)")
        locationErrorSubject.onNext(error)
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // 定位权限发生变化时通知外部
        let status = locationManager.authorizationStatus
        switch status {
        case .notDetermined, .restricted, .denied:
            break
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
        default:
            break
        }
        
        authorizationStatusSubject.onNext(status)

    }
}

extension GMSMapLocationManager {
    static var singleton: GMSMapLocationManager? = {
        var singleton = GMSMapLocationManager()
        return singleton
    }()
    
    class func share() -> GMSMapLocationManager { singleton! }
    
    var authorizationStatus: CLAuthorizationStatus {
        get { locationManager.authorizationStatus }
    }
}

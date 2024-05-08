//
//  GMSMapViewModel.swift
//  GMSMapDemo
//
//  Created by wxliu on 2024/5/8.
//

import Foundation
import RxSwift
import GoogleMaps

enum GMSMapError: Error {
    case missingDestination
    case navigating
    case navigationNotStarted
    
    func description() -> String {
        switch self {
        case .missingDestination:
            return "Missing destination error"
        case .navigating:
            return "Navigating error: already navigating"
        case .navigationNotStarted:
            return "Navigation not started error: navigation not started yet"
        }
    }
}

class GMSMapViewModel: ObservableObject {
    @Published var origin: CLLocationCoordinate2D?
    @Published var destination: CLLocationCoordinate2D?
    @Published var navigateStatus: GMSMapUserNavigateState?
    @Published var polylines: [GMSPolyline] = [GMSPolyline].init()
    
    let destinationSubj = BehaviorSubject<CLLocationCoordinate2D?>(value: nil)
    let navigateStatusSubj = BehaviorSubject<GMSMapUserNavigateState?>(value: nil)

    private let disposeBag = DisposeBag()
    
    private var timer: Timer?
    private let interval: TimeInterval = 10 // 定时器时间间隔，单位秒
    private(set) var gestureing = false // 用来标记是否在手势中

    init() { }
    
    // 开始导航
    func startNavigation(withOrigin origin: CLLocationCoordinate2D?) {
        if navigateStatus == .navigating { return } // 如果正在导航中，忽略点击事件
        guard let _ = destination else { return } // 没有选择导航目的地
        self.navigateStatus = .navigating
        self.origin = origin
        
        self.navigateStatusSubj.onNext(self.navigateStatus)
    }
    
    // 手动停止导航
    func stopNavigation() {
        if navigateStatus != .navigating { return }

        self.navigateStatus = .noStart
        self.origin = nil
        self.destination = nil
        self.polylines = [GMSPolyline].init()
        self.destinationSubj.onNext(nil)

        self.navigateStatusSubj.onNext(self.navigateStatus)

    }
    
    // 导航正常结束时调用
    func finishedNavigation() {
        if navigateStatus != .navigating { return } // 如果正在导航中，忽略点击事件
        self.navigateStatus = .finished
        self.navigateStatusSubj.onNext(self.navigateStatus)
    }
    
    func resetNavigation() {
        self.navigateStatus = .noStart
        self.origin = nil
        self.polylines = [GMSPolyline].init()

        self.navigateStatusSubj.onNext(self.navigateStatus)
    }
    
    // 重新规划路线时合并轨迹
    func mergeAndGeneratePolyline(_ newPolyline: GMSPolyline, currentLocation: CLLocation) ->  GMSPolyline {
        if navigateStatus?.navigateing == true {
            if let polyline = polylines.last  {
                if let mergePolyline = GMSMapHelper.mergePolylines(currentLocation: currentLocation, polyline1: polyline, polyline2: newPolyline) {
                    self.polylines = [mergePolyline]
                    return mergePolyline
                }
            }
        }

        self.polylines = [newPolyline]
        return newPolyline
    }
    
    // 点击地图上的标签
    func handleMapTap(marker: GMSMarker) {
        if navigateStatus == .navigating { return } // 如果正在导航中，忽略点击事件
        if let destination = destination,
            marker.position.longitude == destination.longitude &&  marker.position.latitude == destination.latitude {
            self.destination = nil
            self.polylines.removeAll()
            self.origin = nil
            self.destinationSubj.onNext(nil)
            self.resetNavigation()
        }
    }
    
    // 点击地图，选择
    func handleMapTap(coordinate: CLLocationCoordinate2D) {
        if navigateStatus == .navigating { return } // 如果正在导航中，忽略点击事件
        self.destination = coordinate

        self.destinationSubj.onNext(coordinate)
        self.resetNavigation()
    }
    
    // 启动定时器
    func startTimer() {
        self.gestureing = true
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.gestureing = false
            self?.timer = nil
        }
    }
    
    // 重置定时器
    func resetTimer() {
        timer?.invalidate()
        startTimer()
    }
    
    // 停止定时器
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

extension GMSMapViewModel {
    var navigateing: Bool {
        get {
            return navigateStatus == .navigating
        }
    }
}


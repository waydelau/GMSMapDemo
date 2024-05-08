//
//  GMSMapContentViewModel.swift
//  GMSMapDemo
//
//  Created by wxliu on 2024/5/7.
//

import RxSwift
import RxCocoa
import CoreLocation

class GMSMapContentViewModel: ObservableObject {
    private let mapManager = GMSMapLocationManager.share()
    private var disposeBag = DisposeBag()
    var navigateInfoSubj = BehaviorSubject<GMSMapNavigateInfo?>(value: nil)
    var currentSubj = BehaviorRelay<CLLocationCoordinate2D?>(value: nil)

    @Published var navigateInfo: GMSMapNavigateInfo = GMSMapNavigateInfo()
    @Published var current: CLLocationCoordinate2D?

    var showAuthorizationToast: Bool = false
    var showDestinationToast: Bool = false
    
    private var timer: Timer?
    private let interval: TimeInterval = 10 // 定时器时间间隔，单位秒
}

extension GMSMapContentViewModel {
    func startTimer() {
        if timer == nil {
            timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timerFired), userInfo: nil, repeats: true)
            
            navigateInfo.reset()
            navigateInfo.startTime = Date().timeIntervalSince1970
        }
        self.navigateInfoSubj.onNext(navigateInfo)
    }
    
    func stopTimer() {
        // 先停止定时器
        timer?.invalidate()
        timer = nil
        
//        navigateInfo.reset()
//        self.navigateInfoSubj.onNext(navigateInfo)
   }
    
    @objc func timerFired() {
        navigateInfo.duration += 1
        self.navigateInfoSubj.onNext(navigateInfo)
    }
    
    func setTotalDistance(_ totalDistance: Double) {
        navigateInfo.totalDistance = totalDistance
        self.navigateInfoSubj.onNext(navigateInfo)
    }
    
    func setRemainingDistance(_ remainingDistance: Double) {
        navigateInfo.remainingDistance = remainingDistance
        self.navigateInfoSubj.onNext(navigateInfo)
    }
}

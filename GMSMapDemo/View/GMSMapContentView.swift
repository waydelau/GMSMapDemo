//
//  GMSMapContentView.swift
//  GMSMapDemo
//
//  Created by wxliu on 2024/5/7.
//

import SwiftUI
import GoogleMaps
import RxSwift
import AlertToast
import GooglePlaces

struct GMSMapContentView: View {
    private let mapManager = GMSMapLocationManager.share()
    @ObservedObject var viewModel = GMSMapContentViewModel()
    @ObservedObject var mapVM = GMSMapViewModel()

    @State var navigateInfo: GMSMapNavigateInfo?
    @State var navigateStatus: GMSMapUserNavigateState = .noStart
    @State var current: CLLocation?
    @State private var mapView = GMSMapView()

    private let disposeBag = DisposeBag()
    
    var body: some View {
        VStack {
            GMSMapNavigationInfoView(navigateInfo: $navigateInfo, navigateStatus: $navigateStatus).onAppear() {
                mapVM.navigateStatusSubj.subscribe{ newValue in
                    if let newValue = newValue {
                        navigateStatus = newValue
                    }
                }.disposed(by: disposeBag)
                
                viewModel.navigateInfoSubj.subscribe { newValue in
                    navigateInfo = newValue
                    if let duration = navigateInfo?.duration, duration == 10 {
                        finishedNavigation()
                    }
                }.disposed(by: disposeBag)
            }.frame(height: 40.0)
            GMSMapViewUI(viewModel: mapVM, mapView: $mapView)
                .onAppear {
                    // 订阅权限变化
                    subscribeAuthorization()
                    updateAuthorization()
                    
                    // 订阅定位变化
                    subscribeLocation()
                    
                    // 订阅目的地变化
                    subscribeDestination()
                }
                .edgesIgnoringSafeArea(.all)
            Button(action: {
                // Your action code
                didClickButton()
            }) {
                Text(mapVM.navigateing ? "结束导航" : "开始导航")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
        }
        .toast(isPresenting: $viewModel.showAuthorizationToast) {
            AlertToast(type: .regular, title: "没有定位权限")
        }
        .toast(isPresenting: $viewModel.showDestinationToast) {
            AlertToast(type: .regular, title: "请选择导航目的地")
        }
    }
    
    func didClickButton() {
        if let _ = mapVM.destination {
            switch navigateStatus {
            case .noStart, .finished:
                mapVM.startNavigation(withOrigin: current?.coordinate)
                viewModel.startTimer()
                getPolylines()
            case .navigating:
                mapVM.stopNavigation()
                viewModel.stopTimer()
            }
        }
    }
    
    func finishedNavigation() {
        if let _ = mapVM.destination {
            switch navigateStatus {
            case .navigating:
                mapVM.finishedNavigation()
                viewModel.stopTimer()
            default:
                break
            }
        }
    }
}

extension GMSMapContentView {
    private func subscribeAuthorization() {
        mapManager.authorizationStatusSubject.subscribe { _ in
            updateAuthorization()
        }.disposed(by: disposeBag)
    }

    private func updateAuthorization() {
        let authorizationStatus = mapManager.authorizationStatus
        switch authorizationStatus {
        case .notDetermined, .restricted, .denied:
            viewModel.showAuthorizationToast = true
            // 初始化地图
            mapView.isMyLocationEnabled = false
             mapView.settings.myLocationButton = false
            break
        default:
            viewModel.showAuthorizationToast = false
            // 初始化地图
            mapView.isMyLocationEnabled = true
            mapView.settings.myLocationButton = true
        }
    }

    private func subscribeLocation() {
        // 订阅位置更新事件
        mapManager.lastKnownLocationSubject
            .subscribe(onNext: { location in
                if current == nil || (!self.mapVM.gestureing && navigateStatus == .navigating) {
                    let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude,
                                                         longitude: location.coordinate.longitude,
                                                         zoom: 15.0)
                    mapView.animate(to: camera)
                }

                // 如果变化小于0.5m，认为没有变动
                if let last = current?.coordinate,
                   !GMSMapHelper.isLocationChangeSignificant(currentLocation: last, newLocation: location.coordinate, thresholdDistance: 0.5) { return }

                current = location

                if navigateStatus == .navigating {
                    // 导航中，到达目的地
                    if let current = current?.coordinate,
                       let destination = self.mapVM.destination {
                        if !GMSMapHelper.isLocationChangeSignificant(currentLocation: current, newLocation: destination, thresholdDistance: 5.0) {
                            finishedNavigation()
                            return
                        }
                    }

                    if let polyline = self.mapVM.polylines.last {
                        // 导航中，偏离大于100m，不在轨迹上，需要获取轨迹
                        if !GMSMapHelper.isLocationOnPolyline(location: location, polyline: polyline, threshold: 100.0) {
                            getPolylines()
                        }

                        let remaining =  GMSMapHelper.getRemainingDistanceToPolylineEndFromCurrentLocation(currentLocation: location, polyline: polyline)

                        self.viewModel.setRemainingDistance(remaining)
                    }
                }

            })
            .disposed(by: disposeBag)

        // 订阅定位错误
        mapManager.locationErrorSubject
            .subscribe(onNext: { error in
                // 处理定位错误
                print("Location error: \(error.localizedDescription)")
            })
            .disposed(by: disposeBag)
    }

    private func subscribeDestination (){
        mapVM.destinationSubj
            .subscribe(onNext: { newValue in
                if newValue == nil {
                    viewModel.stopTimer()
                }
                
                getPolylines()
            })
            .disposed(by: disposeBag)
    }
}

extension GMSMapContentView {
    private func getPolylines() {
        guard let current = current, let destination = self.mapVM.destination else { return }
        GMSMapHelper.getPolylines(from: current.coordinate, to: destination) { newValue in
            if let newValue = newValue {
                let newPolyline = self.mapVM.mergeAndGeneratePolyline(newValue, currentLocation: current)
                let total = GMSMapHelper.getTotalDistanceOfPolyline(polyline: newPolyline)
                self.viewModel.setTotalDistance(total)
                self.viewModel.setRemainingDistance(total)
            }
        }
    }
}

#Preview {
    GMSMapContentView()
}

//
//  GMSMapViewUI.swift
//  GMSMapDemo
//
//  Created by wxliu on 2024/5/7.
//

import SwiftUI
import GoogleMaps
import RxSwift

struct GMSMapViewUI: UIViewRepresentable {
    @ObservedObject var viewModel: GMSMapViewModel
    @Binding var mapView: GMSMapView
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(viewModel, self)
    }

    func makeUIView(context: Context) -> GMSMapView {
        mapView.delegate = context.coordinator
        return mapView
    }

    func updateUIView(_ mapView: GMSMapView, context: Context) {
        mapView.clear()
        
        // 更新起点和终点标记
        if let origin = viewModel.origin {
            let originMarker = GMSMarker(position: origin)
            originMarker.title = "Origin"
            originMarker.map = mapView
        }
        
        if let destination = viewModel.destination {
            let destinationMarker = GMSMarker(position: destination)
            destinationMarker.title = "Destination"
            destinationMarker.map = mapView
        }

        // 更新路线
        if !viewModel.polylines.isEmpty {
            for polyline in viewModel.polylines {
                polyline.map = mapView
            }
        }
    }

    class Coordinator: NSObject, GMSMapViewDelegate {
        var viewModel: GMSMapViewModel
        var parent: GMSMapViewUI

        init(_ viewModel: GMSMapViewModel, _ parent: GMSMapViewUI) {
            self.viewModel = viewModel
            self.parent = parent
        }
        
        func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
            viewModel.resetTimer() // 每次地图位置改变时重置定时器
        }
        
        func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
            viewModel.handleMapTap(marker: marker)
            return true
        }
        
        func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
            viewModel.handleMapTap(coordinate: coordinate)
        }
    }
}

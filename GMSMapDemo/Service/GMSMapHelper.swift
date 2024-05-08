//
//  GMSMapHelper.swift
//  GMSMapDemo
//
//  Created by wxliu on 2024/5/7.
//

import Foundation
import GoogleMaps

enum GMSMapHelper {
    static let APIKey = "AIzaSyCYEjZVnDQWY01I6XMdQq5pj8FXsvu2V28"
}

extension GMSMapHelper {
    static func getPolylines(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, completion: @escaping (GMSPolyline?) -> Void) {
        let apiKey = GMSMapHelper.APIKey
        let originString = "\(origin.latitude),\(origin.longitude)"
        let destinationString = "\(destination.latitude),\(destination.longitude)"
        let urlString = "https://maps.googleapis.com/maps/api/directions/json?origin=\(originString)&destination=\(destinationString)&key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            DispatchQueue.main.async {
                completion(nil)
            }
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(nil)
                }
                
                return
            }

            guard let data = data else {
                print("No data received")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            do {
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                    print("Invalid JSON format")
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }

                guard let routes = json["routes"] as? [[String: Any]], let route = routes.first, let overviewPolyline = route["overview_polyline"] as? [String: Any], let points = overviewPolyline["points"] as? String else {
                    print("Invalid JSON format - missing routes or overview_polyline")
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }

                guard let path = GMSPath(fromEncodedPath: points) else {
                    print("Invalid path data")
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }

                DispatchQueue.main.async {
                    let polyline = GMSPolyline(path: path)
                    polyline.strokeColor = .blue
                    polyline.strokeWidth = 3.0
                    completion(polyline)
                }
            } catch {
                print("Error parsing JSON: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }

        task.resume()
    }
    
    // 计算两个位置的距离
    static func isLocationChangeSignificant(currentLocation: CLLocationCoordinate2D, newLocation: CLLocationCoordinate2D, thresholdDistance: CLLocationDistance) -> Bool {
        let currentCLLocation = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
        let newCLLocation = CLLocation(latitude: newLocation.latitude, longitude: newLocation.longitude)
        let distance = currentCLLocation.distance(from: newCLLocation)
        return distance > thresholdDistance
    }
    
    // 计算当前定位是否偏离轨迹
    static func isLocationOnPolyline(location: CLLocation, polyline: GMSPolyline, threshold: CLLocationDistance) -> Bool {
        // 获取轨迹上的所有点
        guard let path = polyline.path else { return false }
        if path.count() < 1 { return false }
        
        // 遍历轨迹上的每个点
        for i in 0..<path.count() {
            // 获取轨迹点
            let polylinePoint = path.coordinate(at: i)
            // 创建CLLocation对象
            let polylineLocation = CLLocation(latitude: polylinePoint.latitude, longitude: polylinePoint.longitude)
            // 计算当前位置与轨迹点的距离
            let distance = location.distance(from: polylineLocation)
            // 如果距离小于阈值，说明当前位置在轨迹上
            if distance <= threshold { return true }
        }
        
        return false
    }
    
    // 计算GMSPolyline表示的轨迹的总距离
    static func getTotalDistanceOfPolyline(polyline: GMSPolyline) -> CLLocationDistance {
        var totalDistance: CLLocationDistance = 0
        
        // 获取轨迹上的所有点
        guard let path = polyline.path else {
            return 0
        }
        
        if path.count() < 1 { return 0 }
        
        // 遍历轨迹上的每个点
        for i in 1..<path.count() {
            // 获取相邻的两个点
            let startCoordinate = path.coordinate(at: i - 1)
            let endCoordinate = path.coordinate(at: i)
            
            // 创建CLLocation对象
            let startLocation = CLLocation(latitude: startCoordinate.latitude, longitude: startCoordinate.longitude)
            let endLocation = CLLocation(latitude: endCoordinate.latitude, longitude: endCoordinate.longitude)
            
            // 计算相邻点之间的距离，并加到总距离上
            let distance = startLocation.distance(from: endLocation)
            totalDistance += distance
        }
        
        return totalDistance
    }
    
    // 计算GMSPolyline表示的轨迹的剩余距离
    static func getRemainingDistanceToPolylineEndFromCurrentLocation(currentLocation: CLLocation, polyline: GMSPolyline) -> CLLocationDistance {
        // 获取轨迹上的所有点
        guard let path = polyline.path else {
            return 0
        }
        
        if path.count() < 1 { return 0 }
        var minDistance: CLLocationDistance?
        var nearestPointIndex = 0
        
        // 遍历轨迹上的每个点，找到最近的轨迹点
        for i in 0..<path.count() {
            // 获取轨迹点
            let polylinePoint = path.coordinate(at: i)
            // 创建CLLocation对象
            let polylineLocation = CLLocation(latitude: polylinePoint.latitude, longitude: polylinePoint.longitude)
            // 计算当前位置与轨迹点的距离
            let distance = currentLocation.distance(from: polylineLocation)
            // 如果是第一个点，或者距离更近，则更新最小距离和最近点的索引
            if minDistance == nil || distance < minDistance! {
                minDistance = distance
                nearestPointIndex = Int(i)
            }
        }
        
        // 计算最近点到轨迹终点的剩余距离
        var remainingDistance: CLLocationDistance = 0
        let start = nearestPointIndex+1
        let end = Int(path.count())
        
        if start < end {
            for i in start ..< end {
                let startCoordinate = path.coordinate(at: UInt(i - 1))
                let endCoordinate = path.coordinate(at: UInt(i))
                let startLocation = CLLocation(latitude: startCoordinate.latitude, longitude: startCoordinate.longitude)
                let endLocation = CLLocation(latitude: endCoordinate.latitude, longitude: endCoordinate.longitude)
                let distance = startLocation.distance(from: endLocation)
                remainingDistance += distance
            }
        }
        
        return remainingDistance
    }

    // 合并路径轨迹，用来偏离以后重新定位
    static func mergePolylines(currentLocation: CLLocation, polyline1: GMSPolyline, polyline2: GMSPolyline) -> GMSPolyline? {
        guard let path1 = polyline1.path, let path2 = polyline2.path else {
            return nil
        }
        
        var nearestIndex = 0
        var minDistance = CLLocationDistanceMax
        
        // 寻找路径1中与当前位置最近的点的索引
        for i in 0..<path1.count() {
            let coordinate = path1.coordinate(at: i)
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            let distance = currentLocation.distance(from: location)
            if distance < minDistance {
                minDistance = distance
                nearestIndex = Int(i)
            }
        }
        
        // 创建一个新的路径，将路径1中最近点之前的部分和路径2合并
        let mergedPath = GMSMutablePath()
        // 添加路径1最近点之前的部分
        for i in 0..<nearestIndex {
            let coordinate = path1.coordinate(at: UInt(i))
            mergedPath.add(coordinate)
        }
        
        // 添加路径2的所有点
        for i in 0..<path2.count() {
            let coordinate = path2.coordinate(at: i)
            mergedPath.add(coordinate)
        }
        
        // 创建一个新的 GMSPolyline，并设置路径
        let mergedPolyline = GMSPolyline(path: mergedPath)
        mergedPolyline.strokeColor = polyline1.strokeColor // 保持原有的颜色
        mergedPolyline.strokeWidth = polyline1.strokeWidth // 保持原有的宽度
        
        return mergedPolyline
    }
    
    static func formatDistance(_ meters: Double) -> String {
        if meters >= 1000 {
            // 超过1千米，转换为千米
            let kilometers = meters / 1000
            return String(format: "%.2f km", kilometers)
        } else {
            // 不足1千米，直接使用米
            return String(format: "%.0f m", meters)
        }
    }

}

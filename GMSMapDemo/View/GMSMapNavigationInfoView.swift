//
//  NavigationInfoView.swift
//  GMSMapDemo
//
//  Created by wxliu on 2024/5/8.
//

import SwiftUI

struct GMSMapNavigationInfoView: View {
    @Binding var navigateInfo: GMSMapNavigateInfo?
    @Binding var navigateStatus: GMSMapUserNavigateState
    
    var body: some View {
        if let navigateInfo = navigateInfo {
            switch navigateStatus {
            case .navigating:
                VStack {
                    HStack {
                        Text("导航中")
                            .frame(height: 10)
                    }
                    .frame(height: 10.0)
                    Spacer()
                    HStack {
                        Text("开始时间：\(navigateInfo.getStartFormatStr())")
                            .padding()
                            .font(Font.system(size: 10))
                        Spacer()
                        Text("已用时间: \(navigateInfo.getDurationFormatStr())")
                            .padding()
                            .font(Font.system(size: 10))
                    }
                    .frame(height: 15)
                    Spacer()
                    HStack {
                        Text("剩余距离: \(GMSMapHelper.formatDistance(navigateInfo.remainingDistance))")
                            .font(Font.system(size: 10))
                            .padding()
                        Spacer()
                        Text("总距离：\(GMSMapHelper.formatDistance(navigateInfo.totalDistance))")
                            .padding()
                            .font(Font.system(size: 10))
                    }
                    .frame(height: 15)
                }
            case .finished:
                VStack {
                    Text("导航结束")
                        .frame(height: 10)
                    Spacer()
                    Text("开始时间：\(navigateInfo.getStartFormatStr())")
                        .padding()
                        .font(Font.system(size: 15)).frame(height: 15)
                    Spacer()
                    HStack {
                        Text("总耗时：\(navigateInfo.getDurationFormatStr())")
                            .padding()
                            .font(Font.system(size: 10))
                        Spacer()
                        Text("总距离：\(GMSMapHelper.formatDistance(navigateInfo.totalDistance))")
                            .padding()
                            .font(Font.system(size: 10))
                    }
                    .frame(height: 15)
                }
            default:
                Text("未开始导航")
                    .frame(height: 40.0)
            }
        }
        else {
            Text("未开始导航")
                .frame(height: 40.0)
        }
    }
}


//
//  AUiMicSeatViewDelegate.swift
//  AUiKit
//
//  Created by wushengtao on 2023/4/6.
//

import Foundation

public protocol AUiMicSeatViewDelegate: NSObjectProtocol {
    func seatItems(view: AUiMicSeatView) -> [AUiMicSeatCellDataProtocol]
    
    func onItemDidClick(view: AUiMicSeatView, seatIndex: Int)
    
    func onMuteVideo(view: AUiMicSeatView, seatIndex: Int, canvas: UIView, isMuteVideo: Bool)
}


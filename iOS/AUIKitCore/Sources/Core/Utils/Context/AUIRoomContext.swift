//
//  AUIRoomContext.swift
//  AUIKit
//
//  Created by wushengtao on 2023/3/3.
//

import Foundation

open class AUIRoomContext: NSObject {
    public static let shared: AUIRoomContext = AUIRoomContext()
    
    public let currentUserInfo: AUIUserThumbnailInfo = AUIUserThumbnailInfo()
    public var commonConfig: AUICommonConfig? {
        didSet {
            guard let config = commonConfig else {return}
            currentUserInfo.userName = config.userName
            currentUserInfo.userId = config.userId
            currentUserInfo.userAvatar = config.userAvatar
        }
    }
    
    public var roomInfoMap: [String: AUIRoomInfo] = [:]
    public var roomConfigMap: [String: AUIRoomConfig] = [:]
    
    public var seatType: AUIMicSeatViewLayoutType = .eight {
        willSet {
            switch newValue {
            case .one: self.seatCount = 1
            case .six: self.seatCount = 6
            case .eight: self.seatCount = 8
            case .nine: self.seatCount = 9
            }
        }
    }
    
    public var seatCount: UInt = 8
    
    public func isRoomOwner(channelName: String) ->Bool {
        return roomInfoMap[channelName]?.owner?.userId == currentUserInfo.userId
    }
    
    public func clean(channelName: String) {
//        roomConfig = nil
        roomInfoMap[channelName] = nil
    }
    
    public private(set) var currentThemeName: String?
    
    public private(set) var themeIdx = 0

}

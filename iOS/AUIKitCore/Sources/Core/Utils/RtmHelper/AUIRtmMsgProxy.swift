//
//  AUIRtmMsgProxy.swift
//  AUIKit
//
//  Created by wushengtao on 2023/2/24.
//

import Foundation
import AgoraRtcKit
import AgoraRtmKit2

@objc public protocol AUIRtmErrorProxyDelegate: NSObjectProtocol {
    
    /// token过期
    /// - Parameter channelName: <#channelName description#>
    @objc optional func onTokenPrivilegeWillExpire(channelName: String?)
    
    /// 网络状态变化
    /// - Parameters:
    ///   - channelName: <#channelName description#>
    ///   - state: <#state description#>
    ///   - reason: <#reason description#>
    @objc optional func onConnectionStateChanged(channelName: String,
                                                 connectionStateChanged state: AgoraRtmClientConnectionState,
                                                 result reason: AgoraRtmClientConnectionChangeReason)
    
    /// 收到的KV为空
    /// - Parameter channelName: <#channelName description#>
    @objc optional func onMsgRecvEmpty(channelName: String)
}

@objc public protocol AUIRtmAttributesProxyDelegate: NSObjectProtocol {
    func onAttributesDidChanged(channelName: String, key: String, value: Any)
}

@objc public protocol AUIRtmMessageProxyDelegate: NSObjectProtocol {
    func onMessageReceive(channelName: String, message: String)
}

public protocol AUIRtmUserProxyDelegate: NSObjectProtocol {
    func onUserSnapshotRecv(channelName: String, userId:String, userList: [[String: Any]])
    func onUserDidJoined(channelName: String, userId:String, userInfo: [String: Any])
    func onUserDidLeaved(channelName: String, userId:String, userInfo: [String: Any])
    func onUserDidUpdated(channelName: String, userId:String, userInfo: [String: Any])
//    func onUserBeKicked(channelName: String, userId:String, userInfo: [String: Any])
}


/// RTM消息转发器
open class AUIRtmMsgProxy: NSObject {
    private var attributesDelegates:[String: NSHashTable<AnyObject>] = [:]
    private var attributesCacheAttr: [String: [String: String]] = [:]
    private var messageDelegates:NSHashTable<AnyObject> = NSHashTable<AnyObject>.weakObjects()
    private var userDelegates: NSHashTable<AnyObject> = NSHashTable<AnyObject>.weakObjects()
    private var errorDelegates: NSHashTable<AnyObject> = NSHashTable<AnyObject>.weakObjects()
    weak var origRtmDelegate: AgoraRtmClientDelegate?  //保存原有的delegate做转发
    
    func cleanCache(channelName: String) {
        attributesCacheAttr[channelName] = nil
    }
    
    func subscribeAttributes(channelName: String, itemKey: String, delegate: AUIRtmAttributesProxyDelegate) {
        let key = "\(channelName)__\(itemKey)"
        if let value = attributesDelegates[key] {
            if !value.contains(delegate) {
                value.add(delegate)
            }
            return
        }
        let weakObjects = NSHashTable<AnyObject>.weakObjects()
        weakObjects.add(delegate)
        attributesDelegates[key] = weakObjects
    }
    
    func unsubscribeAttributes(channelName: String, itemKey: String, delegate: AUIRtmAttributesProxyDelegate) {
        let key = "\(channelName)__\(itemKey)"
        guard let value = attributesDelegates[key] else {
            return
        }
        value.remove(delegate)
    }
    
    func subscribeMessage(channelName: String, delegate: AUIRtmMessageProxyDelegate) {
        if messageDelegates.contains(delegate) {
            return
        }
        messageDelegates.add(delegate)
    }
    
    func unsubscribeMessage(channelName: String, delegate: AUIRtmMessageProxyDelegate) {
        messageDelegates.remove(delegate)
    }
    
    func subscribeUser(channelName: String, delegate: AUIRtmUserProxyDelegate) {
        if userDelegates.contains(delegate) {
            return
        }
        userDelegates.add(delegate)
    }
    
    func unsubscribeUser(channelName: String, delegate: AUIRtmUserProxyDelegate) {
        userDelegates.remove(delegate)
    }
    
    func subscribeError(channelName: String, delegate: AUIRtmErrorProxyDelegate) {
        if errorDelegates.contains(delegate) {
            return
        }
        errorDelegates.add(delegate)
    }
    
    func unsubscribeError(channelName: String, delegate: AUIRtmErrorProxyDelegate) {
        errorDelegates.remove(delegate)
    }
}

//MARK: AgoraRtmClientDelegate
extension AUIRtmMsgProxy: AgoraRtmClientDelegate {
    public func rtmKit(_ rtmKit: AgoraRtmClientKit, onTokenPrivilegeWillExpire channel: String?) {
        aui_info("onTokenPrivilegeWillExpire: \(channel ?? "")", tag: "AUIRtmMsgProxy")
        //TODO: 暂时实现这个
        origRtmDelegate?.rtmKit?(rtmKit, onTokenPrivilegeWillExpire: channel)
        
        for element in errorDelegates.allObjects {
            (element as? AUIRtmErrorProxyDelegate)?.onTokenPrivilegeWillExpire?(channelName: channel)
        }
    }
    
    public func rtmKit(_ kit: AgoraRtmClientKit,
                       channel channelName: String,
                       connectionStateChanged state: AgoraRtmClientConnectionState,
                       result reason: AgoraRtmClientConnectionChangeReason) {
        aui_info("connectionStateChanged: \(state.rawValue) reason：\(reason)", tag: "AUIRtmMsgProxy")
        origRtmDelegate?.rtmKit?(kit, channel: channelName, connectionStateChanged: state, result: reason)
        if errorDelegates.count <= 0 { return }
        for element in errorDelegates.allObjects {
            (element as? AUIRtmErrorProxyDelegate)?.onConnectionStateChanged?(channelName: channelName,
                                                                              connectionStateChanged: state,
                                                                              result: reason)
        }
    }
    
    public func rtmKit(_ rtmKit: AgoraRtmClientKit, on event: AgoraRtmStorageEvent) {
        origRtmDelegate?.rtmKit?(rtmKit, on: event)
       
        guard event.channelType == .stream else {
            return
        }
        
        aui_info("storage event[\(event.target)] channelType: [\(event.channelType.rawValue)] storageType: [\(event.eventType.rawValue)] =======", tag: "AUIRtmMsgProxy")
        //key使用channelType__eventType，保证message channel/stream channel, user storage event/channel storage event共存
        let cacheKey = event.target//"\(event.channelType.rawValue)__\(event.eventType.rawValue)_\(event.target)"
        var cache = self.attributesCacheAttr[cacheKey] ?? [:]
        event.data.getItems().forEach { item in
//            aui_info("\(item.key): \(item.value)", tag: "AUIRtmMsgProxy")
            //判断value和缓存里是否一致，这里用string可能会不准，例如不同终端序列化的时候json obj不同kv的位置不一样会造成生成的json string不同
            if cache[item.key] == item.value {
                aui_info("there are no changes of [\(item.key)]", tag: "AUIRtmMsgProxy")
                return
            }
            cache[item.key] = item.value
            guard let itemData = item.value.data(using: .utf8), let itemValue = try? JSONSerialization.jsonObject(with: itemData) else {
                aui_info("parse itemData fail: \(item.key) \(item.value)", tag: "AUIRtmMsgProxy")
                return
            }
            let delegateKey = "\(event.target)__\(item.key)"
            print("itemValue: \(item.value)")
            if let value = self.attributesDelegates[delegateKey] {
                for element in value.allObjects {
                    if let delegate = element as? AUIRtmAttributesProxyDelegate {
                        delegate.onAttributesDidChanged(channelName: event.target, key: item.key, value: itemValue)
                    }
                }
            }
        }
        self.attributesCacheAttr[cacheKey] = cache
        if event.data.getItems().count > 0 {
            return
        }
        for element in errorDelegates.allObjects {
            (element as? AUIRtmErrorProxyDelegate)?.onMsgRecvEmpty?(channelName: event.target)
        }
        aui_info("storage event[\(event.target)] ========", tag: "AUIRtmMsgProxy")
    }
    
    public func rtmKit(_ rtmKit: AgoraRtmClientKit, on event: AgoraRtmPresenceEvent) {
        origRtmDelegate?.rtmKit?(rtmKit, on: event)
        
        aui_info("[\(event.channelName)] presence event type: [\(event.type.rawValue)] channel type: [\(event.channelType.rawValue)]] states: \(event.states.count) =======", tag: "AUIRtmMsgProxy")
        
        guard event.channelType == .stream else {
            return
        }
        
//        var map: [[]]
        var map: [String: String] = [:]
        event.states.forEach { item in
            map[item.key] = item.value
        }
        let userId = event.publisher ?? ""
        aui_info("presence userId: \(userId) event_type: \(event.type.rawValue) userInfo: \(map)", tag: "AUIRtmMsgProxy")
        if event.type == .remoteJoinChannel {
            if map.count == 0 {
                aui_warn("join user fail, empty: userId: \(userId) \(map)", tag: "AUIRtmMsgProxy")
                return
            }
            
            for element in userDelegates.allObjects {
                (element as? AUIRtmUserProxyDelegate)?.onUserDidJoined(channelName: event.channelName, userId: userId, userInfo: map)
            }
        } else if event.type == .remoteLeaveChannel || event.type == .remoteConnectionTimeout {
            for element in userDelegates.allObjects {
                (element as? AUIRtmUserProxyDelegate)?.onUserDidLeaved(channelName: event.channelName, userId: userId, userInfo: map)
            }
        } else if event.type == .remoteStateChanged {
            if map.count == 0 {
                aui_warn("update user fail, empty: userId: \(userId) \(map)", tag: "AUIRtmMsgProxy")
                return
            }
            for element in userDelegates.allObjects {
                (element as? AUIRtmUserProxyDelegate)?.onUserDidUpdated(channelName: event.channelName, userId: userId, userInfo: map)
            }
        } else if event.type == .snapshot {
            let userList = event.snapshotList()
            for element in userDelegates.allObjects {
                (element as? AUIRtmUserProxyDelegate)?.onUserSnapshotRecv(channelName: event.channelName, userId: userId, userList: userList)
            }
        }
    }
    
    public func rtmKit(_ rtmKit: AgoraRtmClientKit, on event: AgoraRtmMessageEvent) {
        origRtmDelegate?.rtmKit?(rtmKit, on: event)
        aui_info("[\(event.channelName)] message event type: [\(event.message.getType().rawValue)] message: [\(event.message.getData())]]  =======", tag: "AUIRtmMsgProxy")
        
        if let message = event.message.getData() as? NSString {
            for element in messageDelegates.allObjects {
                (element as? AUIRtmMessageProxyDelegate)?.onMessageReceive(channelName: event.channelName, message: message as String)
            }
        } else {
            aui_warn("recv unknown type message: \(event.message.getType().rawValue)", tag: "AUIRtmMsgProxy")
        }
    }
}

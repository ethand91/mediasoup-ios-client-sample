//
//  RoomClient.swift
//  mediasoup-ios-cient-sample
//
//  Created by Denvir Ethan on 2019/12/09.
//  Copyright © 2019 Denvir Ethan. All rights reserved.
//

import Foundation
import SwiftyJSON

public enum RoomError : Error {
    case DEVICE_NOT_LOADED
}

final internal class RoomClient : NSObject {
    private static let STATS_INTERVAL_MS: NSInteger = 3000
    
    private let socket: EchoSocket
    private let roomId: String
    private let mediaCapturer: MediaCapturer
    private let producers: [String : Producer]
    private let consumers: [String : Consumer]
    private let consumersInfo: [Any]
    private let device: Device
    
    private var joined: Bool
    private var sendTransport: SendTransport?
    private var recvTransport: RecvTransport?
    
    private weak var sendTransportDelegate: SendTransportListener?
    
    public init(socket: EchoSocket, device: Device, roomId: String) {
        self.socket = socket
        self.device = device
        self.roomId = roomId
        
        self.mediaCapturer = MediaCapturer.shared
        self.producers = [String : Producer]()
        self.consumers = [String : Consumer]()
        self.consumersInfo = [Any]()
        self.joined = false
        
        super.init()
    }
    
    func join() throws {
        // Check if the device is loaded
        if !self.device.isLoaded() {
            throw RoomError.DEVICE_NOT_LOADED
        }
        
        // if the user is already joined do nothing
        if self.joined {
            return
        }
        
        /*
        _ = Request.shared.sendLoginRoomRequest(socket: self.socket, roomId: self.roomId, deviceRtpCapabilities: self.device.getRtpCapabilities())
        self.joined = true
 */
        
        print("join() join success")
    }
    
    func createSendTransport() {
        // Do nothing if send transport is already created
        if (self.sendTransport != nil) {
            print("createSendTransport() send transport is already created...")
            return
        }
        
        self.createWebRtcTransport(direction: "send")
    }
    
    func createRecvTransport() {
        // Do nothing if recv transport is already created
        if (self.recvTransport != nil) {
            print("createRecvTransport() recv transport is already created...")
            return
        }
        
        
    }
    
    private func createWebRtcTransport(direction: String) {
        /*
        let response: JSON = Request.shared.sendCreateWebRtcTransportRequest(socket: self.socket, roomId: self.roomId, direction: direction)
        
        let webRtcTransportData: JSON = response["webRtcTransportData"].object as! JSON
        
        let id: String = webRtcTransportData["id"].stringValue
        let iceParametersString: String = webRtcTransportData["iceParameters"].stringValue
        let iceCandidatesArrayString: String = webRtcTransportData["iceCandidates"].stringValue
        let dtlsParametersString: String = webRtcTransportData["dtlsParameters"].stringValue
        
        switch direction {
        case "send":
            self.sendTransportDelegate = self
            self.device.createSendTransport(self.sendTransportDelegate as? Protocol & SendTransportListener, id: id, iceParameters: iceParametersString, iceCandidates: iceCandidatesArrayString, dtlsParameters: dtlsParametersString)
            break
        default:
            print("createWebRtcTransport() invalid direction " + direction)
        }
 */
    }
}

// Extension for SendTransportListener
extension RoomClient : SendTransportListener {
    func onConnect(_ transport: Transport!, dtlsParameters: String!) {
        print("SendTransport::onConnect dtlsParameters = " + dtlsParameters)
    }
    
    func onConnectionStateChange(_ transport: Transport!, connectionState: String!) {
        print("SendTransport::onConnectionStateChange connectionState = " + connectionState)
    }
    
    func onProduce(_ transport: Transport!, kind: String!, rtpParameters: String!, appData: String!) -> String! {
        print("SendTransport::onProduce kind = " + kind)
        
        return "id"
    }
}

// Extension for RecvTransportListener
extension RoomClient : RecvTransportListener {
    
}

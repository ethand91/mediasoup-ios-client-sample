//
//  ViewController.swift
//  mediasoup-ios-cient-sample
//
//  Created by Denvir Ethan on 2019/12/09.
//  Copyright © 2019 Denvir Ethan. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON

class ViewController : UIViewController {
    private var socket: EchoSocket?
    
    override func viewDidLoad() {
        print("viewDidLoad()")
        self.connectWebSocket()
    }
    
    private func connectWebSocket() {
        self.socket = EchoSocket.init();
        self.socket?.register(observer: self)
        
        do {
            try self.socket!.connect(wsUri: "wss://192.168.0.101:443")
        } catch {
            print("Failed to connect to server")
        }
    }
    
    private func handleWebSocketConnected() {
        // Initialize mediasoup client
        self.initializeMediasoup()
        
        // Get router rtp capabilities
        let getRoomRtpCapabilitiesResponse: JSON = Request.shared.sendGetRoomRtpCapabilitiesRequest(socket: self.socket!, roomId: "ios")
        print("response! " + getRoomRtpCapabilitiesResponse.description)
        let roomRtpCapabilities: JSON = getRoomRtpCapabilitiesResponse["roomRtpCapabilities"]
        print("roomRtpCapabilities " + roomRtpCapabilities.description)
        
        // Initialize mediasoup device
        //let device: Device = Device.init()
        //device.load(roomRtpCapabilities.description)
        
        print("handleWebSocketConnected() device loaded")
    }
    
    private func initializeMediasoup() {
        Mediasoupclient.initializePC()
        print("initializeMediasoup() client initialized")
        
        // Set mediasoup log
        Logger.setLogLevel(LogLevel(rawValue: 3)!) //TODO
        Logger.setDefaultHandler()
    }
}

extension ViewController : MessageObserver {
    func on(event: String, data: JSON?) {
        switch event {
        case ActionEvent.OPEN:
            print("socket connected")
            self.handleWebSocketConnected()
            break
        default:
            print("Unknown event " + event)
        }
    }
}

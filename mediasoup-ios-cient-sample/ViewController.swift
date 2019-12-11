//
//  ViewController.swift
//  mediasoup-ios-cient-sample
//
//  Created by Ethan.
//  Copyright © 2019 Ethan. All rights reserved.
//

import Foundation
import UIKit
import WebRTC
import SwiftyJSON

class ViewController : UIViewController {
    private var socket: EchoSocket?
    private var client: RoomClient?
    @IBOutlet var localVideoView: RTCEAGLVideoView!
    
    override func viewDidLoad() {
        print("viewDidLoad()")
        self.connectWebSocket()
    }
    
    private func connectWebSocket() {
        self.socket = EchoSocket.init();
        self.socket?.register(observer: self)
        
        do {
            try self.socket!.connect(wsUri: "wss://192.168.60.99:443")
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
        let device: Device = Device.init()
        device.load(roomRtpCapabilities.description)
        
        print("handleWebSocketConnected() device loaded")
        
        self.client = RoomClient.init(socket: self.socket!, device: device, roomId: "ios")
        
        // Join the room
        do {
            try self.client!.join()
        } catch {
            print("failed to join room")
            return
        }
        
        // Create send webrtcTransport
        self.client!.createSendTransport()
        
        // Start media capture/sending
        self.displayLocalVideo()
    }
    
    private func initializeMediasoup() {
        Mediasoupclient.initializePC()
        print("initializeMediasoup() client initialized")
        
        // Set mediasoup log
        Logger.setLogLevel(LogLevel(rawValue: 0)!) //TODO
        Logger.setDefaultHandler()
    }
    
    private func displayLocalVideo() {
        self.checkDevicePermissions()
    }
    
    private func checkDevicePermissions() {
        // Camera permission
        if AVCaptureDevice.authorizationStatus(for: .video) != .authorized {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { (isGranted: Bool) in
                self.startVideo()
            })
        } else {
            self.startVideo()
        }
        
        // Mic permission
        if AVCaptureDevice.authorizationStatus(for: .audio) != .authorized {
            AVCaptureDevice.requestAccess(for: .audio, completionHandler: { (isGranted: Bool) in
                self.startAudio()
            })
        } else {
            self.startAudio()
        }
    }
    
    private func startVideo() {
        do {
            _ = try self.client!.produceVideo(videoView: self.localVideoView)
        } catch {
            print("failed to start video!")
        }
    }
    
    private func startAudio() {
        do {
            try self.client!.produceAudio()
        } catch {
            print("failed to start audio")
        }
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

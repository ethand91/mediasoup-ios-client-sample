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
    @IBOutlet var remoteVideoView: RTCEAGLVideoView!
    @IBOutlet var resumeLocalButton: UIButton!
    @IBOutlet var pauseLocalButton: UIButton!
    
    private var delegate: RoomListener?
    
    override func viewDidLoad() {
        print("viewDidLoad()")
        // Prioritize the local video to the front
        self.view.sendSubviewToBack(self.remoteVideoView)
        
        // Handle buttons
        self.pauseLocalButton.addTarget(self, action: #selector(pauseLocalStream), for: .touchUpInside)
        self.resumeLocalButton.addTarget(self, action: #selector(resumeLocalStream), for: .touchUpInside)
        
        self.connectWebSocket()
    }
    
    // Get rid of the top status bar
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    @objc private func pauseLocalStream() {
        self.pauseLocalVideo()
        self.pauseLocalAudio()
    }
    
    @objc private func resumeLocalStream() {
        self.resumeLocalVideo()
        self.resumeLocalAudio()
    }
    
    private func pauseLocalVideo() {
        do {
            try self.client?.pauseLocalVideo()
        } catch {
            print("Failed to pause local video")
        }
    }
    
    private func resumeLocalVideo() {
        do {
            try self.client?.resumeLocalVideo()
        } catch {
            print("Failed to resume local video")
        }
    }
    
    private func pauseLocalAudio() {
        do {
            try self.client?.pauseLocalAudio()
        } catch {
            print("Failed to pause local audio")
        }
    }
    
    private func resumeLocalAudio() {
        do {
            try self.client?.resumeLocalAudio()
        } catch {
            print("Failed to resume local audio")
        }
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
        
        self.delegate = self
        self.client = RoomClient.init(socket: self.socket!, device: device, roomId: "ios", roomListener: self.delegate!)
        
        // Join the room
        do {
            try self.client!.join()
        } catch {
            print("failed to join room")
            return
        }
        
        // Create recv webrtcTransport
        self.client!.createRecvTransport()
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
        case ActionEvent.NEW_USER:
            print("NEW_USER id =" + data!["userId"]["userId"].stringValue)
            break
        case ActionEvent.NEW_CONSUMER:
            print("NEW_CONSUMER data=" + data!.description)
            self.handleNewConsumerEvent(consumerInfo: data!["consumerData"])
            break
        default:
            print("Unknown event " + event)
        }
    }
    
    private func handleNewConsumerEvent(consumerInfo: JSON) {
        print("handleNewConsumerEvent info = " + consumerInfo.description)
        // Start consuming

        // TODO, if calling consume on video and audio at the same time on different threads
        // video/audio consume must finish before calling it again else
        // peer connection throws a a=mid are the same values (a=mid 0) error
        // so only allow call to consume one at a time on the same thread, implement this in the SDK
        DispatchQueue.main.sync {
            self.client!.consumeTrack(consumerInfo: consumerInfo)
        }
    }
}

// Extension for RoomListener
extension ViewController : RoomListener {
    func onNewConsumer(consumer: Consumer) {
        print("RoomListener::onNewConsumer kind=" + consumer.getKind())
        
        if consumer.getKind() == "video" {
            let videoTrack: RTCVideoTrack = consumer.getTrack() as! RTCVideoTrack
            videoTrack.isEnabled = true
            videoTrack.add(self.remoteVideoView)
        }
        
        do {
            consumer.getKind() == "video"
                ? try self.client!.resumeRemoteVideo()
                : try self.client!.resumeRemoteAudio()
        } catch {
            print("onNewConsumer() failed to resume remote track")
        }
    }
}

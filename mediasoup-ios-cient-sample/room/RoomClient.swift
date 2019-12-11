//
//  RoomClient.swift
//  mediasoup-ios-cient-sample
//
//  Created by Ethan.
//  Copyright © 2019 Ethan. All rights reserved.
//

import Foundation
import SwiftyJSON

public enum RoomError : Error {
    case DEVICE_NOT_LOADED
    case SEND_TRANSPORT_NOT_CREATED
    case RECV_TRANSPORT_NOT_CREATED
    case DEVICE_CANNOT_PRODUCE_VIDEO
    case DEVICE_CANNOT_PRODUCE_AUDIO
}

final internal class RoomClient : NSObject {
    private static let STATS_INTERVAL_MS: NSInteger = 3000
    
    private let socket: EchoSocket
    private let roomId: String
    private let mediaCapturer: MediaCapturer
    private var producers: [String : Producer]
    private let consumers: [String : Consumer]
    private let consumersInfo: [Any]
    private let device: Device
    
    private var joined: Bool
    private var sendTransport: SendTransport?
    private var recvTransport: RecvTransport?
    
    private weak var sendTransportDelegate: SendTransportListener?
    private weak var producerDelegate: ProducerListener?
    
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
        
        _ = Request.shared.sendLoginRoomRequest(socket: self.socket, roomId: self.roomId, deviceRtpCapabilities: self.device.getRtpCapabilities())
        self.joined = true
        
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
        
        self.createWebRtcTransport(direction: "recv")
    }
    
    func produceVideo(videoView: RTCEAGLVideoView) throws -> RTCVideoTrack? {
        if self.sendTransport == nil {
            print("trasnport nil")
            throw RoomError.SEND_TRANSPORT_NOT_CREATED
        }
        
        if !self.device.canProduce("video") {
            print("cannot produce")
            throw RoomError.DEVICE_CANNOT_PRODUCE_VIDEO
        }
        
        do {
            let videoTrack: RTCVideoTrack = try self.mediaCapturer.createVideoTrack(videoView: videoView)
            
            self.createProducer(track: videoTrack, codecOptions: nil, encodings: nil)
            
            return videoTrack
        } catch {
            print("failed to create video track")
            return nil
        }
    }
    
    func produceAudio() throws {
        if self.sendTransport == nil {
            throw RoomError.SEND_TRANSPORT_NOT_CREATED
        }
        
        if !self.device.canProduce("audio") {
            throw RoomError.DEVICE_CANNOT_PRODUCE_AUDIO
        }
        
        let audioTrack: RTCAudioTrack = self.mediaCapturer.createAudioTrack()
        self.createProducer(track: audioTrack, codecOptions: nil, encodings: nil)
    }
    
    private func createWebRtcTransport(direction: String) {
        let response: JSON = Request.shared.sendCreateWebRtcTransportRequest(socket: self.socket, roomId: self.roomId, direction: direction)
        print("createWebRtcTransport() response = " + response.description)
        
        let webRtcTransportData: JSON = response["webRtcTransportData"]
        print("webRtcTransportData = " + webRtcTransportData.description)
        
        let id: String = webRtcTransportData["id"].stringValue
        let iceParameters: JSON = webRtcTransportData["iceParameters"]
        let iceCandidatesArray: JSON = webRtcTransportData["iceCandidates"]
        let dtlsParameters: JSON = webRtcTransportData["dtlsParameters"]
        
        print("id = " + id)
        print("iceParameters = " + iceParameters.description)
        print("iceCandidates = " + iceCandidatesArray.description)
        print("dtlsParameters = " + dtlsParameters.description)
        
        switch direction {
        case "send":
            self.sendTransportDelegate = self
            self.sendTransport = self.device.createSendTransport(self.sendTransportDelegate as? Protocol & SendTransportListener, id: id, iceParameters: iceParameters.description, iceCandidates: iceCandidatesArray.description, dtlsParameters: dtlsParameters.description)
            break
        default:
            print("createWebRtcTransport() invalid direction " + direction)
        }
    }
    
    private func createProducer(track: RTCMediaStreamTrack, codecOptions: String?, encodings: Array<RTCRtpParameters>?) {
        self.producerDelegate = self
        
        let kindProducer: Producer = self.sendTransport!.produce(self.producerDelegate! as? Protocol & ProducerListener, track: track, encodings: encodings, codecOptions: codecOptions)
        self.producers[kindProducer.getId()] = kindProducer
        
        print("createProducer() created id =" + kindProducer.getId() + " kind =" + kindProducer.getKind())
    }
    
    private func handleLocalTransportConnectEvent(transport: Transport, dtlsParameters: String) {
        print("handleLocalTransportConnectEvent() id =" + transport.getId())
        Request.shared.sendConnectWebRtcTransportRequest(socket: self.socket, roomId: self.roomId, transportId: transport.getId(), dtlsParameters: dtlsParameters)
    }
    
    private func handleLocalTransportProduceEvent(transport: Transport, kind: String, rtpParameters: String, appData: String) -> String {
        print("handleLocalTransportProduceEvent() id =" + transport.getId() + " kind = " + kind)
        
        let transportProduceResponse: JSON = Request.shared.sendProduceWebRtcTransportRequest(socket: self.socket, roomId: self.roomId, transportId: transport.getId(), kind: kind, rtpParameters: rtpParameters)
        
        return transportProduceResponse["producerId"].stringValue
    }
}

// Extension for SendTransportListener
extension RoomClient : SendTransportListener {
    func onConnect(_ transport: Transport!, dtlsParameters: String!) {
        print("SendTransport::onConnect dtlsParameters = " + dtlsParameters)
        self.handleLocalTransportConnectEvent(transport: transport, dtlsParameters: dtlsParameters)
    }
    
    func onConnectionStateChange(_ transport: Transport!, connectionState: String!) {
        print("SendTransport::onConnectionStateChange connectionState = " + connectionState)
    }
    
    func onProduce(_ transport: Transport!, kind: String!, rtpParameters: String!, appData: String!) -> String! {
        print("SendTransport::onProduce kind = " + kind)
        
        
        return self.handleLocalTransportProduceEvent(transport: transport, kind: kind, rtpParameters: rtpParameters, appData: appData)
    }
}

// Extension for RecvTransportListener
extension RoomClient : RecvTransportListener {
    
}

// Extension for producer
extension RoomClient : ProducerListener {
    func onTransportClose(_ producer: Producer!) {
        print("Producer::onTransportClose")
    }
}

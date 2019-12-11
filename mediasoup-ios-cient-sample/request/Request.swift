//
//  Request.swift
//  mediasoup-ios-cient-sample
//
//  Created by Ethan.
//  Copyright © 2019 Ethan. All rights reserved.
//

import Foundation
import SwiftyJSON

final internal class Request : NSObject {
    internal static let REQUEST_TIMEOUT_MS: NSInteger = 3000;
    
    internal static let shared = Request.init();
    
    private override init() {}
    
    // Send getRoomRtpCapabilitiesRequest
    func sendGetRoomRtpCapabilitiesRequest(socket: EchoSocket, roomId: String) -> JSON {
        let getRoomRtpCapabilitiesRequest: JSON = [
            "action": "getRoomRtpCapabilities",
            "roomId": roomId,
        ]
        
        return Request.shared.sendSocketAckRequest(socket: socket, data: getRoomRtpCapabilitiesRequest)
    }
    
    
    func sendLoginRoomRequest(socket: EchoSocket, roomId: String, deviceRtpCapabilities: String) -> JSON {
        let loginRoomRequest: JSON = [
            "action": ActionEvent.LOGIN_ROOM,
            "roomId": roomId,
            "rtpCapabilities": deviceRtpCapabilities
        ]
        
        return Request.shared.sendSocketAckRequest(socket: socket, data: loginRoomRequest)
    }
    
    func sendCreateWebRtcTransportRequest(socket: EchoSocket, roomId: String, direction: String) -> JSON {
        let createWebRtcTransportRequest: JSON = [
            "action": ActionEvent.CREATE_WEBRTC_TRANSPORT,
            "roomId": roomId,
            "direction": direction
        ]
        
        return Request.shared.sendSocketAckRequest(socket: socket, data: createWebRtcTransportRequest)
    }
    
    func sendConnectWebRtcTransportRequest(socket: EchoSocket, roomId: String, transportId: String, dtlsParameters: String) {
        let connectWebRtcTransportRequest: JSON = [
            "action": ActionEvent.CONNECT_WEBRTC_TRANSPORT,
            "roomId": roomId,
            "transportId": transportId,
            "dtlsParameters": JSON.init(parseJSON: dtlsParameters)
        ]
        
        socket.send(message: connectWebRtcTransportRequest)
    }
    
    func sendProduceWebRtcTransportRequest(socket: EchoSocket, roomId: String, transportId: String, kind: String, rtpParameters: String) -> JSON {
        let produceWebRtcTransportRequest: JSON = [
            "action": ActionEvent.PRODUCE,
            "roomId": roomId,
            "transportId": transportId,
            "kind": kind,
            "rtpParameters": JSON.init(parseJSON: rtpParameters)
        ]
        
        return Request.shared.sendSocketAckRequest(socket: socket, data: produceWebRtcTransportRequest)
    }
    
    func sendPauseProducerRequest(socket: EchoSocket, roomId: String, producerId: String) {
        let pauseProducerRequest: JSON = [
            "action": ActionEvent.PAUSE_PRODUCER,
            "roomId": roomId,
            "producerId": producerId
        ]
        
        socket.send(message: pauseProducerRequest)
    }
    
    func sendResumeProducerRequest(socket: EchoSocket, roomId: String, producerId: String) {
        let resumeProducerRequest: JSON = [
            "action": ActionEvent.RESUME_PRODUCER,
            "roomId": roomId,
            "producerId": producerId
        ]
        
        socket.send(message: resumeProducerRequest)
    }
    
    func sendPauseConsumerRequest(socket: EchoSocket, roomId: String, consumerId: String) {
        let pauseConsumerRequest: JSON = [
            "action": ActionEvent.PAUSE_CONSUMER,
            "roomId": roomId,
            "consumerId": consumerId
        ]
        
        socket.send(message: pauseConsumerRequest)
    }
    
    func sendResumseConsumerRequest(socket: EchoSocket, roomId: String, consumerId: String) {
        let resumeConsumerRequest: JSON = [
            "action": ActionEvent.RESUME_CONSUMER,
            "roomId": roomId,
            "consumerId": consumerId
        ]
        
        socket.send(message: resumeConsumerRequest)
    }
    
    func sendRtcStatsReport(socket: EchoSocket, roomId: String, rtcStatsReport: String) {
        let rtcStatsReportRequest: JSON = [
            "action": ActionEvent.RTC_STATS,
            "roomId": roomId,
            "rtcStatsReport": rtcStatsReport
        ]
        
        socket.send(message: rtcStatsReportRequest)
    }
    
    private func sendSocketAckRequest(socket: EchoSocket, data: JSON) -> JSON {
        let semaphore: DispatchSemaphore = DispatchSemaphore.init(value: 0)
        
        var response: JSON?
        
        let queue: DispatchQueue = DispatchQueue.global()
        queue.async {
            socket.sendWithAck(message: data, completionHandler: {(res: JSON) in
                response = res
                semaphore.signal()
            })
        }
        
        _ = semaphore.wait(timeout: .now() + 10.0)
        
        return response!
    }
}

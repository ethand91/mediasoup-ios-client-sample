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
        
        /*
        socket.sendWithAck(message: getRoomRtpCapabilitiesRequest, completionHandler: {(res: JSON) in
            print("RESPONSE" + res.description)
        })
 */
        return Request.shared.sendSocketAckRequest(socket: socket, data: getRoomRtpCapabilitiesRequest)
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
    
    /*
    func sendLoginRoomRequest(socket: EchoSocket, roomId: String, deviceRtpCapabilities: String) -> JSON {
        let loginRoomRequest: NSMutableDictionary = NSMutableDictionary.init()
        loginRoomRequest.setValue(ActionEvent.LOGIN_ROOM, forKey: "action")
        loginRoomRequest.setValue(roomId, forKey: "roomId")
        loginRoomRequest.setValue(deviceRtpCapabilities, forKey: "rtpCapabilities")
        
        return socket.sendWithAck(message: loginRoomRequest)
    }
    
    func sendCreateWebRtcTransportRequest(socket: EchoSocket, roomId: String, direction: String) -> JSON {
        let createWebRtcTransportRequest: NSMutableDictionary = NSMutableDictionary.init()
        createWebRtcTransportRequest.setValue(ActionEvent.CREATE_WEBRTC_TRANSPORT, forKey: "action")
        createWebRtcTransportRequest.setValue(roomId, forKey: "roomId")
        createWebRtcTransportRequest.setValue(direction, forKey: "direction")
        
        return socket.sendWithAck(message: createWebRtcTransportRequest)
    }
    
    func sendConnectWebRtcTransportRequest(socket: EchoSocket, roomId: String, transportId: String, dtlsParameters: String) {
        let connectWebRtcTransportRequest: NSMutableDictionary = NSMutableDictionary.init()
        connectWebRtcTransportRequest.setValue(ActionEvent.CONNECT_WEBRTC_TRANSPORT, forKey: "action")
        connectWebRtcTransportRequest.setValue(roomId, forKey: "roomId")
        connectWebRtcTransportRequest.setValue(transportId, forKey: "transportId")
        connectWebRtcTransportRequest.setValue(dtlsParameters, forKey: "dtlsParameters")
        
        socket.send(message: connectWebRtcTransportRequest)
    }
    
    func sendProduceWebRtcTransportRequest(socket: EchoSocket, roomId: String, transportId: String, kind: String, rtpParameters: String) -> JSON {
        let produceWebRtcTransportRequest: NSMutableDictionary = NSMutableDictionary.init()
        produceWebRtcTransportRequest.setValue(ActionEvent.PRODUCE, forKey: "action")
        produceWebRtcTransportRequest.setValue(roomId, forKey: "roomId")
        produceWebRtcTransportRequest.setValue(transportId, forKey: "transportId")
        produceWebRtcTransportRequest.setValue(kind, forKey: "kind")
        produceWebRtcTransportRequest.setValue(rtpParameters, forKey: "rtpParameters")
        
        return socket.sendWithAck(message: produceWebRtcTransportRequest)
    }
    
    func sendPauseProducerRequest(socket: EchoSocket, roomId: String, producerId: String) {
        let pauseProducerRequest: NSMutableDictionary = NSMutableDictionary.init()
        pauseProducerRequest.setValue(ActionEvent.PAUSE_PRODUCER, forKey: "action")
        pauseProducerRequest.setValue(roomId, forKey: "roomId")
        pauseProducerRequest.setValue(producerId, forKey: "producerId")
        
        socket.send(message: pauseProducerRequest)
    }
    
    func sendResumeProducerRequest(socket: EchoSocket, roomId: String, producerId: String) {
        let resumeProducerRequest: NSMutableDictionary = NSMutableDictionary.init()
        resumeProducerRequest.setValue(ActionEvent.RESUME_PRODUCER, forKey: "action")
        resumeProducerRequest.setValue(roomId, forKey: "roomId")
        resumeProducerRequest.setValue(producerId, forKeyPath: "producerId")
        
        socket.send(message: resumeProducerRequest)
    }
    
    func sendPauseConsumerRequest(socket: EchoSocket, roomId: String, consumerId: String) {
        let pauseConsumeRequest: NSMutableDictionary = NSMutableDictionary.init()
        pauseConsumeRequest.setValue(ActionEvent.PAUSE_CONSUMER, forKeyPath: "action")
        pauseConsumeRequest.setValue(roomId, forKeyPath: "roomId")
        pauseConsumeRequest.setValue(consumerId, forKeyPath: "consumerId")
        
        socket.send(message: pauseConsumeRequest)
    }
    
    func sendResumseConsumerRequest(socket: EchoSocket, roomId: String, consumerId: String) {
        let resumeConsumerRequest: NSMutableDictionary = NSMutableDictionary.init()
        resumeConsumerRequest.setValue(ActionEvent.RESUME_CONSUMER, forKeyPath: "action")
        resumeConsumerRequest.setValue(roomId, forKeyPath: "roomId")
        resumeConsumerRequest.setValue(consumerId, forKey: "consumerId")
        
        socket.send(message: resumeConsumerRequest)
    }
    
    func sendRtcStatsReport(socket: EchoSocket, roomId: String, rtcStatsReport: String) {
        let rtcStatsReportRequest: NSMutableDictionary = NSMutableDictionary.init()
        rtcStatsReportRequest.setValue(ActionEvent.RTC_STATS, forKey: "action")
        rtcStatsReportRequest.setValue(roomId, forKey: "roomId")
        rtcStatsReportRequest.setValue(rtcStatsReportRequest, forKey: "rtcStatsReport")
        
        socket.send(message: rtcStatsReportRequest)
    }
 */
}

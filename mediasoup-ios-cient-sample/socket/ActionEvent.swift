//
//  ActionEvent.swift
//  mediasoup-ios-cient-sample
//
//  Created by Ethan.
//  Copyright © 2019 Ethan. All rights reserved.
//

import Foundation

final internal class ActionEvent {
    public static let OPEN: String = "open"
    public static let ROOM_RTP_CAPABILITIES: String = "roomRtpCapabilities"
    public static let LOGIN_ROOM: String = "loginRoom"
    public static let CREATE_WEBRTC_TRANSPORT: String = "createWebRtcTransport"
    public static let CONNECT_WEBRTC_TRANSPORT: String = "connectWebRtcTransport"
    public static let PRODUCE: String = "produce"
    public static let NEW_USER: String = "newuser"
    public static let NEW_CONSUMER: String = "newconsumer"
    public static let PAUSE_PRODUCER: String = "pauseProducer"
    public static let RESUME_PRODUCER: String = "resumeProducer"
    public static let PAUSE_CONSUMER: String = "pauseConsumer"
    public static let RESUME_CONSUMER: String = "resumeConsumer"
    public static let RTC_STATS: String = "rtcStats"
}

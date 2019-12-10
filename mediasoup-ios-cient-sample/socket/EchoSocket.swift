//
//  EchoSocket.swift
//  mediasoup-ios-cient-sample
//
//  Created by Denvir Ethan on 2019/12/09.
//  Copyright © 2019 Denvir Ethan. All rights reserved.
//

import Foundation
import Starscream
import SwiftyJSON

public enum SocketError : Error {
    case INVALID_WS_URI
}

final internal class EchoSocket : WebSocketDelegate, MessageSubscriber {
    private var observers: [ObjectIdentifier : Observer] = [ObjectIdentifier : Observer]()
    
    private var socket: WebSocket?;
    
    func connect(wsUri: String) throws {
        /*
        if !wsUri.starts(with: "ws://") || !wsUri.starts(with: "wss://") {
            throw SocketError.INVALID_WS_URI
        }
        */
        
        if (self.socket != nil && self.socket?.isConnected ?? false) {
            return;
        }
        
        self.socket = WebSocket.init(url: URL.init(string: wsUri)!)
        self.socket!.disableSSLCertValidation = true
        self.socket!.delegate = self
        self.socket!.connect()
    }
    
    func send(message: JSON) {
        self.socket?.write(string: message.description)
    }
    
    func sendWithAck(message: JSON) -> JSON {
        let event: String = message["action"].stringValue
        
        let ackCall: AckCall = AckCall.init(event: event, socket: self)
        return ackCall.sendAckRequest(message: message)
    }
    
    func disconnect() {
        self.socket?.disconnect()
        self.socket = nil
    }
    
    func websocketDidConnect(socket: WebSocketClient) {
        print("websocketDidConnect")
        self.notifyObservers(event: ActionEvent.OPEN, data: nil)
    }
    
    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        print("websocketDidReceiveData")
    }
    
    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        print("websocketDidDisconnect")
    }
    
    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        print("websocketDisReceiveMessage " + text)
        let data: Data = text.data(using: .utf8)!
        let json: JSON = JSON.init(data)
        let event: String = json["action"].stringValue
        
        self.notifyObservers(event: event, data: json)
    }
    
    func register(observer: MessageObserver) {
        let id: ObjectIdentifier = ObjectIdentifier(observer)
        self.observers[id] = Observer(observer: observer)
    }
    
    func unregister(observer: MessageObserver) {
        let id: ObjectIdentifier = ObjectIdentifier(observer)
        self.observers.removeValue(forKey: id);
    }
    
    func notifyObservers(event: String, data: JSON?) {
        for (id, observer) in self.observers {
            guard let observer = observer.observer else {
                self.observers.removeValue(forKey: id)
                continue
            }
            
            observer.on(event: event, data: data)
        }
    }
    
    private class AckCall : MessageObserver {
        private let event: String
        private let semaphor: DispatchSemaphore
        //private var callback: (_ response: JSON) -> JSON? = nil
        private let socket: EchoSocket

        private var response: JSON?
        
        init(event: String, socket: EchoSocket) {
            self.event = event
            self.socket = socket
            self.semaphor = DispatchSemaphore.init(value: 0)
        }
        
        func sendAckRequest(message: JSON) -> JSON {
            print("sendAckRequest")
            
            self.socket.register(observer: self)
            self.socket.send(message: message)
            
            print("Wait")
            //let queue = DispatchQueue.init(label: "background", qos: .userInitiated)
            
            _ = self.semaphor.wait(timeout: .distantFuture)
            print("semaphor done")
            
            self.socket.unregister(observer: self)
            return self.response!
        }
        
        func on(event: String, data: JSON?) {
            print("Ack Response " + event)
            if event == self.event {
                self.response = JSON.init(data ?? JSON.init())
                self.semaphor.signal()
            }
        }
    }
}

private extension EchoSocket {
    struct Observer {
        weak var observer: MessageObserver?
    }
}

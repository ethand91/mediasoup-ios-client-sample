//
//  EchoSocket.swift
//  mediasoup-ios-cient-sample
//
//  Created by Ethan.
//  Copyright © 2019 Ethan. All rights reserved.
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
        // Allow self-signed certificates
        self.socket!.disableSSLCertValidation = true
        // Handle socket delegate methods on the global thread (semaphor will lock if not set to global..)
        self.socket!.callbackQueue = DispatchQueue.global()
        self.socket!.delegate = self
        self.socket!.connect()
    }
    
    func send(message: JSON) {
        self.socket?.write(string: message.description)
    }
    
    func sendWithAck(message: JSON, completionHandler: @escaping (_: JSON) -> Void) {
        let event: String = message["action"].stringValue

        DispatchQueue.init(label: "test", qos: .userInitiated).async {
            let ackCall: AckCall = AckCall.init(event: event, socket: self)
            let response: JSON = ackCall.sendAckRequest(message: message)
            
            completionHandler(response)
        }
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
    
    private class AckCall {
        private let event: String
        private let semaphor: DispatchSemaphore
        private let socket: EchoSocket

        private var response: JSON?
        
        init(event: String, socket: EchoSocket) {
            self.event = event
            self.socket = socket
            self.semaphor = DispatchSemaphore.init(value: 0)
        }
        
        func sendAckRequest(message: JSON) -> JSON {
            print("sendAckRequest")
            
            self.socket.send(message: message)
            
            let callable: AckCallable = AckCallable.init(event: self.event, socket: self.socket)
            
            callable.listen(callback: {(result: JSON?) -> Void in

                self.response = result!
                self.semaphor.signal()
            })
                        
            _ = self.semaphor.wait(timeout: .distantFuture)
            
            return self.response!
        }
    }
    
    private class AckCallable : MessageObserver {
        private let event: String
        private let socket: EchoSocket
        
        private var callback: ((_: JSON) -> Void)?
        
        init(event: String, socket: EchoSocket) {
            self.event = event
            self.socket = socket
        }
        
        func listen(callback: @escaping (_: JSON?) -> Void) {
            self.callback = callback
            
            self.socket.register(observer: self)
        }
        
        func on(event: String, data: JSON?) {
            if event == self.event {
                self.callback!(data!)
                self.socket.unregister(observer: self)
            }
        }
    }
}

private extension EchoSocket {
    struct Observer {
        weak var observer: MessageObserver?
    }
}

//
//  MessageObserver.swift
//  mediasoup-ios-cient-sample
//
//  Created by Denvir Ethan on 2019/12/09.
//  Copyright © 2019 Denvir Ethan. All rights reserved.
//

import Foundation
import SwiftyJSON

internal protocol MessageObserver: class {
    func on(event: String, data: JSON?)
}

internal protocol MessageSubscriber: class {
    func register(observer: MessageObserver)
    func unregister(observer: MessageObserver)
    func notifyObservers(event: String, data: JSON?)
}

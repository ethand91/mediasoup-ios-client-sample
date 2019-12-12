//
//  RoomListener.swift
//  mediasoup-ios-cient-sample
//
//  Created by Denvir Ethan on 2019/12/12.
//  Copyright © 2019 Denvir Ethan. All rights reserved.
//

import Foundation

protocol RoomListener {
    func onNewConsumer(consumer: Consumer)
}

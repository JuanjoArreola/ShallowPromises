//
//  Cancellable.swift
//  ShallowPromises
//
//  Created by JuanJo on 19/04/20.
//

import Foundation

public protocol Cancellable {
    mutating func cancel()
}

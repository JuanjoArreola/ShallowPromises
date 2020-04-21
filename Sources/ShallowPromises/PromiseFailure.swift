//
//  PromiseFailure.swift
//  ShallowPromises
//
//  Created by JuanJo on 19/04/20.
//

import Foundation

public enum PromiseFailure: Error {
    case cancelled, timeout
}

//
//  ConcretePromise.swift
//  ShallowPromises
//
//  Created by JuanJo on 19/04/20.
//

import Foundation

public struct Promise<U>: PromiseProtocol {
    
    public typealias T = U
    
    private var result: U?
    private var error: Error?
    
    private var futures: Futures<T>? = Futures<T>()
    
    public var littlePromise: Cancellable? {
        didSet {
            if let _ = error {
                littlePromise?.cancel()
            }
        }
    }
    
    public var isCompleted: Bool {
        return result != nil || error != nil
    }
    
    public init(successClosure: ((T) -> Void)? = nil) {
        if let closure = successClosure {
            futures?.add(successHandler: closure)
        }
    }
    
    public init(littlePromise: Cancellable) {
        self.littlePromise = littlePromise
    }
    
    private init(result: U?, error: Error?) {
        self.result = result
        self.error = error
    }
    
    public mutating func fulfill(with object: U) {
        if isCompleted {
            return
        }
        self.result = object
        futures?.complete(with: object)
        futures = nil
    }
    
    public mutating func complete(with error: Error) {
        if isCompleted {
            return
        }
        self.error = error
        futures?.complete(with: error)
        futures = nil
    }
    
    static func fulfilled(with result: U, in queue: DispatchQueue) -> Promise<U> {
        var promise = Promise()
        queue.async {
            promise.fulfill(with: result)
        }
        return promise
    }
    
    public mutating func then<V>(_ next: @escaping (U) -> Promise<V>) -> Promise<V> {
        if let result = result {
            return next(result)
        } else if let error = error {
            return Promise<V>(result: nil, error: error)
        } else {
            var promise = Promise<V>(littlePromise: self)
            futures?.add(successHandler: { result in
                var originalPromise = next(result)
                originalPromise.onSuccess { nextResult in
                    promise.fulfill(with: nextResult)
                }
            })
            futures?.add(errorHandler: { error in
                promise.complete(with: error)
            })
            return promise
        }
    }
    
    @discardableResult
    public mutating func onSuccess(_ closure: @escaping (U) -> Void) -> Promise<U> {
        if let object = result {
            closure(object)
        } else {
            futures?.add(successHandler: closure)
        }
        return self
    }
    
    @discardableResult
    public mutating func onError(_ closure: @escaping (Error) -> Void) -> Promise<U> {
        if let error = error {
            closure(error)
        } else {
            futures?.add(errorHandler: closure)
        }
        return self
    }
    
    @discardableResult
    public mutating func onCompletion(_ closure: @escaping () -> Void) -> Promise<U> {
        if isCompleted {
            closure()
        } else {
            futures?.add(finishHandler: closure)
        }
        return self
    }
    
    public mutating func cancel() {
        littlePromise?.cancel()
        complete(with: PromiseFailure.cancelled)
    }
    
}

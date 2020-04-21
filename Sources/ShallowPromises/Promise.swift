//
//  ConcretePromise.swift
//  ShallowPromises
//
//  Created by JuanJo on 19/04/20.
//

import Foundation

private let syncQueue: DispatchQueue = DispatchQueue(label: "com.shallowpromises.SyncQueue", attributes: [])

open class Promise<U>: Cancellable {
    
    private var result: U?
    private var error: Error?
    
    private var futures: Futures<U>? = Futures<U>()
    private var completionQueue: DispatchQueue?
    
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
    
    public init(successClosure: ((U) -> Void)? = nil, completionQueue queue: DispatchQueue? = nil) {
        if let closure = successClosure {
            futures?.appendSuccess(closure, in: queue)
        }
        completionQueue = queue
    }
    
    public init(littlePromise: Cancellable) {
        self.littlePromise = littlePromise
    }
    
    private init(result: U?, error: Error?) {
        self.result = result
        self.error = error
    }
    
    private func setResult(_ result: U) -> Futures<U>? {
        syncQueue.sync {
            if isCompleted {
                return nil
            }
            self.result = result
            let lastFutures = futures
            futures = nil
            return lastFutures
        }
    }
    
    public func fulfill(with result: U, in queue: DispatchQueue? = nil) {
        setResult(result)?.fulfill(with: result, in: queue)
    }
    
    private func setError(_ error: Error) -> Futures<U>? {
        syncQueue.sync {
            if isCompleted {
                return nil
            }
            self.error = error
            let lastFutures = futures
            futures = nil
            return lastFutures
        }
    }
    
    public func complete(with error: Error, in queue: DispatchQueue? = nil) {
        setError(error)?.complete(with: error, in: completionQueue ?? queue)
    }
    
    private func getResultOrRegisterThen<V>(_ next: @escaping (U) -> Promise<V>, in queue: DispatchQueue? = nil) -> Any {
        syncQueue.sync {
            if let result = result {
                return result
            } else if let error = error {
                return error
            } else {
                let promise = Promise<V>(littlePromise: self)
                futures?.appendSuccess({ result in
                    let originalPromise = next(result)
                    originalPromise.onSuccess { nextResult in
                        promise.fulfill(with: nextResult)
                    }
                    originalPromise.onError { nextError in
                        promise.complete(with: nextError)
                    }
                }, in: queue)
                futures?.appendError({ error in
                    promise.complete(with: error)
                }, in: queue)
                return promise
            }
        }
    }
    
    public func then<V>(in queue: DispatchQueue? = nil, _ next: @escaping (U) -> Promise<V>) -> Promise<V> {
        switch getResultOrRegisterThen(next, in: queue) {
        case let result as U:
            return next(result)
        case let error as Error:
            return Promise<V>(result: nil, error: error)
        case let promise as Promise<V>:
            return promise
        default:
            return Promise<V>(result: nil, error: nil)
        }
    }
    
    private func getResultOrRegister(_ closure: @escaping (U) -> Void, in queue: DispatchQueue? = nil) -> U? {
        syncQueue.sync {
            if let result = result {
                return result
            } else {
                futures?.appendSuccess(closure, in: queue)
                return nil
            }
        }
    }
    
    @discardableResult
    public func onSuccess(in queue: DispatchQueue? = nil, _ closure: @escaping (U) -> Void) -> Promise<U> {
        if let result = getResultOrRegister(closure, in: queue) {
            if let queue = queue {
                queue.async { closure(result) }
            } else {
                closure(result)
            }
        }
        return self
    }
    
    private func getErrorOrRegister(_ closure: @escaping (Error) -> Void, in queue: DispatchQueue? = nil) -> Error? {
        syncQueue.sync {
            if let error = error {
                return error
            } else {
                futures?.appendError(closure, in: queue)
                return nil
            }
        }
    }
    
    @discardableResult
    public func onError(in queue: DispatchQueue? = nil, _ closure: @escaping (Error) -> Void) -> Promise<U> {
        if let error = getErrorOrRegister(closure, in: queue) {
            if let queue = queue {
                queue.async { closure(error) }
            } else {
                closure(error)
            }
        }
        return self
    }
    
    private func isCompletedOrRegister(_ closure: @escaping () -> Void, in queue: DispatchQueue? = nil) -> Bool {
        syncQueue.sync {
            if isCompleted {
                return true
            } else {
                futures?.appendFinally(closure, in: queue)
                return false
            }
        }
    }
    
    @discardableResult
    public func finally(in queue: DispatchQueue? = nil, _ closure: @escaping () -> Void) -> Promise<U> {
        if isCompletedOrRegister(closure, in: queue) {
            if let queue = queue {
                queue.async { closure() }
            } else {
                closure()
            }
        }
        return self
    }
    
    public func cancel() {
        littlePromise?.cancel()
        complete(with: PromiseFailure.cancelled)
    }
    
}

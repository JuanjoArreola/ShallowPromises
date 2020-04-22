//
//  ConcretePromise.swift
//  ShallowPromises
//
//  Created by JuanJo on 19/04/20.
//

import Foundation

private let syncQueue = DispatchQueue(label: "com.shallowpromises.SyncQueue", attributes: [])

open class Promise<U>: Cancellable {
    
    private var result: U?
    private var error: Error?
    
    private var futures: Futures<U>? = Futures<U>()
    
    public var littlePromise: Cancellable? {
        didSet {
            if let _ = error {
                littlePromise?.cancel()
            }
        }
    }
    
    public init(successClosure: ((U) -> Void)? = nil, queue: DispatchQueue? = nil, littlePromise: Cancellable? = nil) {
        if let closure = successClosure {
            futures?.appendSuccess(closure, in: queue)
        }
        self.littlePromise = littlePromise
    }
    
    private init(result: U?, error: Error?) {
        self.result = result
        self.error = error
    }
    
    private func setResult(_ result: U?, error: Error?) -> Futures<U>? {
        syncQueue.sync {
            if self.result != nil || self.error != nil {
                return nil
            }
            self.result = result
            self.error = error
            let lastFutures = futures
            futures = nil
            return lastFutures
        }
    }
    
    public func fulfill(with result: U, in queue: DispatchQueue? = nil) {
        setResult(result, error: nil)?.fulfill(with: result, in: queue)
    }
    
    public func complete(with error: Error, in queue: DispatchQueue? = nil) {
        setResult(nil, error: error)?.complete(with: error, in: queue)
    }
    
    private func getResultOrRegisterThen<V>(_ next: @escaping (U) -> Promise<V>, in queue: DispatchQueue? = nil) -> Any {
        syncQueue.sync {
            if let result = result {
                return result
            } else if let error = error {
                return error
            } else {
                return registerNext(next, in: queue)
            }
        }
    }
    
    private func registerNext<V>(_ next: @escaping (U) -> Promise<V>, in queue: DispatchQueue?) -> Promise<V> {
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
        guard let result = getResultOrRegister(closure, in: queue) else {
            return self
        }
        queue?.async {
            closure(result)
        } ?? closure(result)
        
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
        guard let error = getErrorOrRegister(closure, in: queue) else {
            return self
        }
        queue?.async {
            closure(error)
        } ?? closure(error)
        
        return self
    }
    
    private func isCompletedOrRegister(_ closure: @escaping () -> Void, in queue: DispatchQueue? = nil) -> Bool {
        syncQueue.sync {
            if result != nil || error != nil {
                return true
            } else {
                futures?.appendFinally(closure, in: queue)
                return false
            }
        }
    }
    
    @discardableResult
    public func finally(in queue: DispatchQueue? = nil, _ closure: @escaping () -> Void) -> Promise<U> {
        if !isCompletedOrRegister(closure, in: queue) {
            return self
        }
        queue?.async {
            closure()
        } ?? closure()
    
        return self
    }
    
    public func cancel() {
        littlePromise?.cancel()
        complete(with: PromiseFailure.cancelled)
    }
    
}

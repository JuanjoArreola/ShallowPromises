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
    
    @discardableResult
    public func fulfill(with result: U, in queue: DispatchQueue? = nil) -> Self {
        setResult(result, error: nil)?.fulfill(with: result, in: queue)
        return self
    }
    
    @discardableResult
    public func complete(with error: Error, in queue: DispatchQueue? = nil) -> Self {
        setResult(nil, error: error)?.complete(with: error, in: queue)
        return self
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
    
    @discardableResult
    public func onSuccess(in queue: DispatchQueue? = nil, _ closure: @escaping (U) -> Void) -> Self {
        var safeResult: U?
        syncQueue.sync {
            if let result = result {
                safeResult = result
            } else {
                futures?.appendSuccess(closure, in: queue)
            }
        }
        if let result = safeResult {
            queue?.async {
                closure(result)
            } ?? closure(result)
        }
        return self
    }
    
    @discardableResult
    public func onError(in queue: DispatchQueue? = nil, _ closure: @escaping (Error) -> Void) -> Self {
        var safeError: Error?
        syncQueue.sync {
            if let error = error {
                safeError = error
            } else {
                futures?.appendError(closure, in: queue)
            }
        }
        if let error = safeError {
            queue?.async {
                closure(error)
            } ?? closure(error)
        }
        return self
    }
    
    @discardableResult
    public func finally(in queue: DispatchQueue? = nil, _ closure: @escaping () -> Void) -> Self {
        var isCompleted = false
        syncQueue.sync {
            isCompleted = result != nil || error != nil
            if !isCompleted {
                futures?.appendFinally(closure, in: queue)
            }
        }
        if isCompleted {
            queue?.async {
                closure()
            } ?? closure()
        }
        return self
    }
    
    public func cancel() {
        littlePromise?.cancel()
        complete(with: PromiseFailure.cancelled)
    }
    
}

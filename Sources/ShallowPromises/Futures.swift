//
//  Futures.swift
//  ShallowPromises
//
//  Created by JuanJo on 19/04/20.
//

import Foundation

class Futures<T> {
    
    private var successFutures: [SuccessFuture<T>] = []
    private var errorFutures: [ErrorFuture] = []
    private var finallyFutures: [FinallyFuture] = []
    
    func appendSuccess(_ closure: @escaping (T) -> Void, in queue: DispatchQueue?) {
        successFutures.append(SuccessFuture<T>(closure: closure, queue: queue))
    }
    
    func appendError(_ closure: @escaping (Error) -> Void, in queue: DispatchQueue?) {
        errorFutures.append(ErrorFuture(closure: closure, queue: queue))
    }
    
    func appendFinally(_ closure: @escaping () -> Void, in queue: DispatchQueue?) {
        finallyFutures.append(FinallyFuture(closure: closure, queue: queue))
    }
    
    func fulfill(with result: T, in promiseQueue: DispatchQueue?) {
        successFutures.forEach { future in
            let queue = future.queue ?? promiseQueue
            queue?.async {
                future.closure(result)
            } ?? future.closure(result)
        }
        complete(in: promiseQueue)
    }
    
    func complete(with error: Error, in promiseQueue: DispatchQueue?) {
        errorFutures.forEach { future in
            let queue = future.queue ?? promiseQueue
            queue?.async {
                future.closure(error)
            } ?? future.closure(error)
        }
        complete(in: promiseQueue)
    }
    
    private func complete(in promiseQueue: DispatchQueue?) {
        finallyFutures.forEach { future in
            let queue = future.queue ?? promiseQueue
            queue?.async {
                future.closure()
            } ?? future.closure()
        }
    }
}

struct SuccessFuture<T> {
    let closure: (T) -> Void
    let queue: DispatchQueue?
}

struct ErrorFuture {
    let closure: (Error) -> Void
    let queue: DispatchQueue?
}

struct FinallyFuture {
    let closure: () -> Void
    let queue: DispatchQueue?
}

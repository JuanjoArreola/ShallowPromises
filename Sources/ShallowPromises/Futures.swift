//
//  Futures.swift
//  ShallowPromises
//
//  Created by JuanJo on 19/04/20.
//

import Foundation

class Futures<T> {
    
    private var successFutures: [Future<T>] = []
    private var errorFutures: [Future<Error>] = []
    private var finallyFutures: [FinallyFuture] = []
    
    func appendSuccess(_ closure: @escaping (T) -> Void, in queue: DispatchQueue?) {
        successFutures.append(Future(closure: closure, queue: queue))
    }
    
    func appendError(_ closure: @escaping (Error) -> Void, in queue: DispatchQueue?) {
        errorFutures.append(Future(closure: closure, queue: queue))
    }
    
    func appendFinally(_ closure: @escaping () -> Void, in queue: DispatchQueue?) {
        finallyFutures.append(FinallyFuture(closure: closure, queue: queue))
    }
    
    func fulfill(with result: T, in queue: DispatchQueue?) {
        complete(futures: successFutures, with: result, in: queue)
    }
    
    func complete(with error: Error, in queue: DispatchQueue?) {
        complete(futures: errorFutures, with: error, in: queue)
    }
    
    private func complete<U>(futures: [Future<U>], with result: U, in queue: DispatchQueue?) {
        futures.forEach { future in
            let queue = future.queue ?? queue
            queue?.async {
                future.closure(result)
            } ?? future.closure(result)
        }
        finalize(in: queue)
    }
    
    private func finalize(in queue: DispatchQueue?) {
        finallyFutures.forEach { future in
            let queue = future.queue ?? queue
            queue?.async {
                future.closure()
            } ?? future.closure()
        }
    }
}

struct Future<T> {
    let closure: (T) -> Void
    let queue: DispatchQueue?
}

struct FinallyFuture {
    let closure: () -> Void
    let queue: DispatchQueue?
}

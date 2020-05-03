//
//  ProxyTests.swift
//  ShallowPromisesTests
//
//  Created by Juan Jose Arreola Simon on 29/04/20.
//

import XCTest
import ShallowPromises

class ProxyTests: XCTestCase {

    func testSuccess() throws {
        let expectation = self.expectation(description: "success")
        
        let promise = Promise<Int>()
        let proxy = promise.proxy()
        proxy.onSuccess { result in
            expectation.fulfill()
        }
        proxy.onError { _ in
            XCTFail()
        }
        promise.fulfill(with: 0)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testError() throws {
        let expectation = self.expectation(description: "error")
        
        let promise = Promise<Int>()
        let proxy = promise.proxy()
        proxy.onSuccess { _ in
            XCTFail()
        }
        proxy.onError { _ in
            expectation.fulfill()
        }
        promise.complete(with: TestError.test)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testFinally() throws {
        let expectation = self.expectation(description: "finally")
        
        let promise = Promise<Int>()
        let proxy = promise.proxy()
        proxy.finally {
            expectation.fulfill()
        }
        promise.fulfill(with: 0)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testCancel() throws {
        let expectation = self.expectation(description: "success")
        let cancelExpectation = self.expectation(description: "cancel")
        
        let promise = Promise<Int>()
        promise.onSuccess { _ in
            expectation.fulfill()
        }
        let proxy = promise.proxy()
        proxy.cancel()
        proxy.onError { _ in
            cancelExpectation.fulfill()
        }
        promise.fulfill(with: 0)
        
        wait(for: [expectation, cancelExpectation], timeout: 1.0)
    }

}

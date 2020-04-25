//
//  SuccessTests.swift
//  ShallowPromisesTests
//
//  Created by Juan Jose Arreola Simon on 25/04/20.
//

import XCTest
@testable import ShallowPromises

class SuccessTests: XCTestCase {

    func testSuccessFulfilled() {
        let expectation = self.expectation(description: "fulfilled")
        
        Promise().fulfill(with: 0).onSuccess { result in
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testSuccessPending() {
        let expectation = self.expectation(description: "pending")
        
        let promise = Promise<Int>().onSuccess { result in
            expectation.fulfill()
        }
        promise.fulfill(with: 0)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testSuccessQueue() {
        let expectation = self.expectation(description: "queue")
        
        Promise().fulfill(with: 0).onSuccess(in: .main) { result in
            XCTAssertEqual(result, 0)
        }.finally(in: .main) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testSuccessPendingQueue() {
        let expectation = self.expectation(description: "pending")
        
        let promise = Promise<Int>().onSuccess { result in
            XCTAssertEqual(result, 0)
        }.finally(in: .main) {
            expectation.fulfill()
        }
        promise.fulfill(with: 0)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    static var allTests = [
        ("testSuccessFulfilled", testSuccessFulfilled),
        ("testSuccessPending", testSuccessPending),
        ("testSuccessQueue", testSuccessQueue),
        ("testSuccessPendingQueue", testSuccessPendingQueue),
    ]

}

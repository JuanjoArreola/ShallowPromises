//
//  ThenTests.swift
//  ShallowPromisesTests
//
//  Created by Juan Jose Arreola Simon on 25/04/20.
//

import XCTest
import ShallowPromises

class ThenTests: XCTestCase {

    func testThenFulfilled() {
        let firstExpectation = self.expectation(description: "first")
        let secondExpectation = self.expectation(description: "second")
        
        let first = Promise().fulfill(with: 0).onSuccess { result in
            firstExpectation.fulfill()
        }
        let second = first.then { result -> Promise<Int> in
            return Promise().fulfill(with: 1)
        }
        second.onSuccess { result in
            secondExpectation.fulfill()
        }
        
        wait(for: [firstExpectation, secondExpectation], timeout: 1.0)
    }
    
    func testThenPending() {
        let firstExpectation = self.expectation(description: "first")
        let secondExpectation = self.expectation(description: "second")
        
        var temporal: Promise<Int>?
        let first = Promise<Int>().onSuccess { result in
            firstExpectation.fulfill()
        }
        let second = first.then { result -> Promise<Int> in
            let promise =  Promise().fulfill(with: 1)
            temporal = promise
            return promise
        }
        second.onSuccess { result in
            secondExpectation.fulfill()
        }
        first.fulfill(with: 0)
        temporal?.fulfill(with: 1)
        
        wait(for: [firstExpectation, secondExpectation], timeout: 1.0)
    }
    
    func testThenErrorFulfilled() {
        let firstExpectation = self.expectation(description: "first")
        let secondExpectation = self.expectation(description: "second")
        
        let first = Promise<Int>().complete(with: TestError.test).onSuccess { result in
            XCTFail()
        }.finally {
            firstExpectation.fulfill()
        }
        let second = first.then { result -> Promise<Int> in
            return Promise<Int>().complete(with: TestError.test)
        }
        second.onSuccess { result in
            XCTFail()
        }.onError { error in
            XCTAssertTrue(error is TestError)
        }.finally {
            secondExpectation.fulfill()
        }
        
        wait(for: [firstExpectation, secondExpectation], timeout: 1.0)
    }
    
    func testThenPendingQueue() {
        let firstExpectation = self.expectation(description: "first")
        let secondExpectation = self.expectation(description: "second")
        
        var temporal: Promise<Int>?
        let first = Promise<Int>().onSuccess { result in
            firstExpectation.fulfill()
        }
        let second = first.then(in: .main) { result -> Promise<Int> in
            let promise =  Promise().fulfill(with: 1)
            temporal = promise
            return promise
        }
        second.onSuccess(in: .main) { result in
            secondExpectation.fulfill()
        }
        first.fulfill(with: 0)
        temporal?.fulfill(with: 1)
        
        wait(for: [firstExpectation, secondExpectation], timeout: 1.0)
    }
    
    static var allTests = [
        ("testThenFulfilled", testThenFulfilled),
        ("testThenPending", testThenPending),
        ("testThenErrorFulfilled", testThenErrorFulfilled),
        ("testThenPendingQueue", testThenPendingQueue),
    ]

}

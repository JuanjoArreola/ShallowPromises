//
//  ErrorTests.swift
//  ShallowPromisesTests
//
//  Created by Juan Jose Arreola Simon on 25/04/20.
//

import XCTest
import ShallowPromises

class ErrorTests: XCTestCase {

    func testError() {
        let expectation = self.expectation(description: "testError")
        
        Promise<Int>().complete(with: TestError.test).onSuccess { result in
            XCTFail()
        }.onError { error in
            XCTAssertTrue(error is TestError)
        }.finally {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testErrorPending() {
        let expectation = self.expectation(description: "testError")
        
        let promise = Promise<Int>().onSuccess { result in
            XCTFail()
        }.onError { error in
            XCTAssertTrue(error is TestError)
        }.finally {
            expectation.fulfill()
        }
        promise.complete(with: TestError.test)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testErrorQueue() {
        let expectation = self.expectation(description: "testError")
        
        Promise<Int>().complete(with: TestError.test).onSuccess { result in
            XCTFail()
        }.onError(in: .main) { error in
            XCTAssertTrue(error is TestError)
        }.finally {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    static var allTests = [
        ("testError", testError),
        ("testErrorPending", testErrorPending),
        ("testErrorQueue", testErrorQueue),
    ]

}

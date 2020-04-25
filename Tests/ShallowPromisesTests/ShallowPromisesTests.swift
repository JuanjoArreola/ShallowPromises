import XCTest
@testable import ShallowPromises

final class ShallowPromisesTests: XCTestCase {
    
    func testFulfillTwice() {
        let expectation = self.expectation(description: "twice")
        
        Promise().fulfill(with: 0).fulfill(with: 1).onSuccess { result in
            XCTAssertEqual(result, 0)
        }.finally {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testCancelLittlePromise() {
        let expectation = self.expectation(description: "littlePromise")
        
        let littlePromise = Promise<Int>()
        littlePromise.onSuccess { _ in
            XCTFail()
        }.onError { error in
            XCTAssertTrue(error is PromiseFailure)
        }.finally {
            expectation.fulfill()
        }
        let promise = Promise<Int>(littlePromise: littlePromise)
        promise.cancel()
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testCancelledLittlePromise() {
        let expectation = self.expectation(description: "littlePromise")
        
        let littlePromise = Promise<Int>()
        littlePromise.onSuccess { _ in
            XCTFail()
        }.onError { error in
            XCTAssertTrue(error is PromiseFailure)
        }.finally {
            expectation.fulfill()
        }
        let promise = Promise<Int>().complete(with: TestError.test)
        promise.littlePromise = littlePromise
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testFinally() {
        let expectation = self.expectation(description: "testFinally")
        
        Promise<Int>().fulfill(with: 0, in: .main).finally {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testInitCompletion() {
        let expectation = self.expectation(description: "testFinally")
        
        Promise(successClosure: { (result: Int) in
            expectation.fulfill()
            }, queue: .main).fulfill(with: 0)
        
        wait(for: [expectation], timeout: 1.0)
    }

    static var allTests = [
        ("testFulfillTwice", testFulfillTwice),
        ("testCancelLittlePromise", testCancelLittlePromise),
        ("testCancelledLittlePromise", testCancelledLittlePromise),
        ("testFinally", testFinally),
        ("testInitCompletion", testInitCompletion),
    ]
}

enum TestError: Error {
    case test
}

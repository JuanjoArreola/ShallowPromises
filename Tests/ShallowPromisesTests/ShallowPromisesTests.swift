import XCTest
@testable import ShallowPromises

final class ShallowPromisesTests: XCTestCase {
    
    func testSuccess() {
        let expectation = self.expectation(description: "testSuccess")
        
        TestRequester.request().onSuccess { result in
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testError() {
        let expectation = self.expectation(description: "testSuccess")
        
        TestRequester.requestError().onError { error in
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testThen() {
        let expectation = self.expectation(description: "testSuccess")
        let firstExpectation = self.expectation(description: "Success")
        
        TestRequester.request()
            .then({ result -> Promise<Int> in
                firstExpectation.fulfill()
                return TestRequester.requestInt(from: result)
            })
            .onSuccess { result in
                expectation.fulfill()
        }
        
        wait(for: [firstExpectation, expectation], timeout: 1.0)
    }
    
    func testManyThen() {
        let first = self.expectation(description: "first")
        
        TestRequester.request()
            .then(TestRequester.requestInt(from:))
            .then(TestRequester.requestString(from:))
            .then(TestRequester.requestInt(from:))
            .onSuccess { result in
                first.fulfill()
        }
        
        wait(for: [first], timeout: 1.0)
    }

    static var allTests = [
        ("testSuccess", testSuccess),
    ]
}


class TestRequester {
    
    static func request() -> Promise<String> {
        let promise = Promise<String>()
        DispatchQueue.global().async {
            promise.fulfill(with: "result")
        }
        return promise
    }
    
    static func requestInt(from string: String) -> Promise<Int> {
        let promise = Promise<Int>()
        DispatchQueue.global().async {
            promise.fulfill(with: 1)
        }
        return promise
    }
    
    static func requestString(from int: Int) -> Promise<String> {
        let promise = Promise<String>()
        DispatchQueue.global().async {
            promise.fulfill(with: "One")
        }
        return promise
    }
    
    static func requestError() -> Promise<String> {
        let promise = Promise<String>()
        DispatchQueue.global().async {
            promise.complete(with: TestError.test)
        }
        return promise
    }
}

enum TestError: Error {
    case test
}

import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(ErrorTests.allTests),
        testCase(ShallowPromisesTests.allTests),
        testCase(SuccessTests.allTests),
        testCase(ThenTests.allTests),
    ]
}
#endif

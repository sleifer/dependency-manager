//
//  semverMatchingTests.swift
//  dependency-managerTests
//
//  Created by Simeon Leifer on 10/19/17.
//  Copyright © 2017 droolingcat.com. All rights reserved.
//

import XCTest

class semverMatchingTests: XCTestCase {

    var semverList: [SemVer] = []

    override func setUp() {
        super.setUp()

        if let semver = SemVer("1.0") {
            semverList.append(semver)
        }
        if let semver = SemVer("1.0.1") {
            semverList.append(semver)
        }
        if let semver = SemVer("1.0.2") {
            semverList.append(semver)
        }
        if let semver = SemVer("1.0.3") {
            semverList.append(semver)
        }
        if let semver = SemVer("1.1") {
            semverList.append(semver)
        }
        if let semver = SemVer("1.2") {
            semverList.append(semver)
        }
        if let semver = SemVer("1.3") {
            semverList.append(semver)
        }
        if let semver = SemVer("2.0") {
            semverList.append(semver)
        }
    }

    override func tearDown() {
        semverList.removeAll()

        super.tearDown()
    }

    func printSemVer(list: [SemVer]) {
        dump(list.map({ (item) -> String in
            return item.fullString
        }))
    }

    func testEqual() {
        let ver = SemVer("1.0.1")
        XCTAssertNotNil(ver)
        if let ver = ver {
            let matches = ver.matching(fromList: semverList, withTest: .equal)
            XCTAssertEqual(matches.count, 1)
            XCTAssertEqual(matches[0], ver)
        }
    }

    func testEqual2() {
        let ver = SemVer("v1.0.1")
        XCTAssertNotNil(ver)
        if let ver = ver {
            let matches = ver.matching(fromList: semverList, withTest: .equal)
            XCTAssertEqual(matches.count, 0)
        }
    }

    func testGTE() {
        let ver = SemVer("1.0.1")
        XCTAssertNotNil(ver)
        if let ver = ver {
            let matches = ver.matching(fromList: semverList, withTest: .greaterThanOrEqual)
            XCTAssertEqual(matches.count, 7)
            XCTAssertEqual(matches.last, SemVer("2.0"))
        }
    }

    func testGTE2() {
        let ver = SemVer("1.0")
        XCTAssertNotNil(ver)
        if let ver = ver {
            let matches = ver.matching(fromList: semverList, withTest: .greaterThanOrEqual)
            XCTAssertEqual(matches.count, 8)
            XCTAssertEqual(matches.last, SemVer("2.0"))
        }
    }

    func testGTE3() {
        let ver = SemVer("1")
        XCTAssertNotNil(ver)
        if let ver = ver {
            let matches = ver.matching(fromList: semverList, withTest: .greaterThanOrEqual)
            XCTAssertEqual(matches.count, 8)
            XCTAssertEqual(matches.last, SemVer("2.0.0"))
        }
    }

    func testCompatible() {
        let ver = SemVer("1.0.1")
        XCTAssertNotNil(ver)
        if let ver = ver {
            let matches = ver.matching(fromList: semverList, withTest: .compatible)
            XCTAssertEqual(matches.count, 3)
            XCTAssertEqual(matches.last, SemVer("1.0.3"))
        }
    }

    func testCompatible2() {
        let ver = SemVer("1.0")
        XCTAssertNotNil(ver)
        if let ver = ver {
            let matches = ver.matching(fromList: semverList, withTest: .compatible)
            XCTAssertEqual(matches.count, 4)
            XCTAssertEqual(matches.last, SemVer("1.0.3"))
        }
    }

    func testCompatible3() {
        let ver = SemVer("1")
        XCTAssertNotNil(ver)
        if let ver = ver {
            let matches = ver.matching(fromList: semverList, withTest: .compatible)
            XCTAssertEqual(matches.count, 7)
            XCTAssertEqual(matches.last, SemVer("1.3"))
        }
    }

}

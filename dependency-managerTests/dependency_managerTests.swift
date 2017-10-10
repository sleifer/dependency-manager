//
//  dependency_managerTests.swift
//  dependency-managerTests
//
//  Created by Simeon Leifer on 9/16/17.
//  Copyright © 2017 droolingcat.com. All rights reserved.
//

import XCTest

class dependency_managerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testMajor() throws {
        let parser = SemVerParser("3")
        let ver = try parser.parse()
        XCTAssertEqual(ver.fullString, "3")
        XCTAssertEqual(ver.major, 3)
        XCTAssertEqual(ver.minor, nil)
        XCTAssertEqual(ver.patch, nil)
        XCTAssertEqual(ver.preReleaseMajor, nil)
        XCTAssertEqual(ver.preReleaseMinor, nil)
        XCTAssertEqual(ver.buildMajor, nil)
        XCTAssertEqual(ver.buildMinor, nil)
    }

    func testMinor() throws {
        let parser = SemVerParser("1.0")
        let ver = try parser.parse()
        XCTAssertEqual(ver.fullString, "1.0")
        XCTAssertEqual(ver.major, 1)
        XCTAssertEqual(ver.minor, 0)
        XCTAssertEqual(ver.patch, nil)
        XCTAssertEqual(ver.preReleaseMajor, nil)
        XCTAssertEqual(ver.preReleaseMinor, nil)
        XCTAssertEqual(ver.buildMajor, nil)
        XCTAssertEqual(ver.buildMinor, nil)
    }

    func testPatch() throws {
        let parser = SemVerParser("1.0.2")
        let ver = try parser.parse()
        XCTAssertEqual(ver.fullString, "1.0.2")
        XCTAssertEqual(ver.major, 1)
        XCTAssertEqual(ver.minor, 0)
        XCTAssertEqual(ver.patch, 2)
        XCTAssertEqual(ver.preReleaseMajor, nil)
        XCTAssertEqual(ver.preReleaseMinor, nil)
        XCTAssertEqual(ver.buildMajor, nil)
        XCTAssertEqual(ver.buildMinor, nil)
    }

    func testMajorPre() throws {
        let parser = SemVerParser("5-beta.6")
        let ver = try parser.parse()
        XCTAssertEqual(ver.fullString, "5-beta.6")
        XCTAssertEqual(ver.major, 5)
        XCTAssertEqual(ver.minor, nil)
        XCTAssertEqual(ver.patch, nil)
        XCTAssertEqual(ver.preReleaseMajor, "beta")
        XCTAssertEqual(ver.preReleaseMinor, "6")
        XCTAssertEqual(ver.preReleaseMinorInt, 6)
        XCTAssertEqual(ver.buildMajor, nil)
        XCTAssertEqual(ver.buildMinor, nil)
    }

    func testMinorPre() throws {
        let parser = SemVerParser("1.4-beta.6")
        let ver = try parser.parse()
        XCTAssertEqual(ver.fullString, "1.4-beta.6")
        XCTAssertEqual(ver.major, 1)
        XCTAssertEqual(ver.minor, 4)
        XCTAssertEqual(ver.patch, nil)
        XCTAssertEqual(ver.preReleaseMajor, "beta")
        XCTAssertEqual(ver.preReleaseMinor, "6")
        XCTAssertEqual(ver.preReleaseMinorInt, 6)
        XCTAssertEqual(ver.buildMajor, nil)
        XCTAssertEqual(ver.buildMinor, nil)
    }

    func testPatchPre1() throws {
        let parser = SemVerParser("1.0.2-beta")
        let ver = try parser.parse()
        XCTAssertEqual(ver.fullString, "1.0.2-beta")
        XCTAssertEqual(ver.major, 1)
        XCTAssertEqual(ver.minor, 0)
        XCTAssertEqual(ver.patch, 2)
        XCTAssertEqual(ver.preReleaseMajor, "beta")
        XCTAssertEqual(ver.preReleaseMinor, nil)
        XCTAssertEqual(ver.buildMajor, nil)
        XCTAssertEqual(ver.buildMinor, nil)
    }

    func testPatchPre2() throws {
        let parser = SemVerParser("1.0.2-beta.5")
        let ver = try parser.parse()
        XCTAssertEqual(ver.fullString, "1.0.2-beta.5")
        XCTAssertEqual(ver.major, 1)
        XCTAssertEqual(ver.minor, 0)
        XCTAssertEqual(ver.patch, 2)
        XCTAssertEqual(ver.preReleaseMajor, "beta")
        XCTAssertEqual(ver.preReleaseMinor, "5")
        XCTAssertEqual(ver.preReleaseMinorInt, 5)
        XCTAssertEqual(ver.buildMajor, nil)
        XCTAssertEqual(ver.buildMinor, nil)
    }

    func testPatchBuild1() throws {
        let parser = SemVerParser("1.0.2+gmc")
        let ver = try parser.parse()
        XCTAssertEqual(ver.fullString, "1.0.2+gmc")
        XCTAssertEqual(ver.major, 1)
        XCTAssertEqual(ver.minor, 0)
        XCTAssertEqual(ver.patch, 2)
        XCTAssertEqual(ver.preReleaseMajor, nil)
        XCTAssertEqual(ver.preReleaseMinor, nil)
        XCTAssertEqual(ver.buildMajor, "gmc")
        XCTAssertEqual(ver.buildMinor, nil)
    }

    func testMajorBuild() throws {
        let parser = SemVerParser("1+gmc.4")
        let ver = try parser.parse()
        XCTAssertEqual(ver.fullString, "1+gmc.4")
        XCTAssertEqual(ver.major, 1)
        XCTAssertEqual(ver.minor, nil)
        XCTAssertEqual(ver.patch, nil)
        XCTAssertEqual(ver.preReleaseMajor, nil)
        XCTAssertEqual(ver.preReleaseMinor, nil)
        XCTAssertEqual(ver.buildMajor, "gmc")
        XCTAssertEqual(ver.buildMinor, "4")
        XCTAssertEqual(ver.buildMinorInt, 4)
    }

    func testMinorBuild() throws {
        let parser = SemVerParser("1.0+gmc.4")
        let ver = try parser.parse()
        XCTAssertEqual(ver.fullString, "1.0+gmc.4")
        XCTAssertEqual(ver.major, 1)
        XCTAssertEqual(ver.minor, 0)
        XCTAssertEqual(ver.patch, nil)
        XCTAssertEqual(ver.preReleaseMajor, nil)
        XCTAssertEqual(ver.preReleaseMinor, nil)
        XCTAssertEqual(ver.buildMajor, "gmc")
        XCTAssertEqual(ver.buildMinor, "4")
        XCTAssertEqual(ver.buildMinorInt, 4)
    }

    func testPatchBuild2() throws {
        let parser = SemVerParser("1.0.2+gmc.4")
        let ver = try parser.parse()
        XCTAssertEqual(ver.fullString, "1.0.2+gmc.4")
        XCTAssertEqual(ver.major, 1)
        XCTAssertEqual(ver.minor, 0)
        XCTAssertEqual(ver.patch, 2)
        XCTAssertEqual(ver.preReleaseMajor, nil)
        XCTAssertEqual(ver.preReleaseMinor, nil)
        XCTAssertEqual(ver.buildMajor, "gmc")
        XCTAssertEqual(ver.buildMinor, "4")
        XCTAssertEqual(ver.buildMinorInt, 4)
    }

    func testAll() throws {
        let parser = SemVerParser("1.0.2-beta.6+gmc.4")
        let ver = try parser.parse()
        XCTAssertEqual(ver.fullString, "1.0.2-beta.6+gmc.4")
        XCTAssertEqual(ver.major, 1)
        XCTAssertEqual(ver.minor, 0)
        XCTAssertEqual(ver.patch, 2)
        XCTAssertEqual(ver.preReleaseMajor, "beta")
        XCTAssertEqual(ver.preReleaseMinor, "6")
        XCTAssertEqual(ver.preReleaseMinorInt, 6)
        XCTAssertEqual(ver.buildMajor, "gmc")
        XCTAssertEqual(ver.buildMinor, "4")
        XCTAssertEqual(ver.buildMinorInt, 4)
    }

    func testBad() throws {
        let parser = SemVerParser("sync-hackathon-2015-11-09")
        let ver = try parser.parse()
        XCTAssertEqual(ver.fullString, "sync-hackathon-2015-11-09")
        XCTAssertEqual(ver.prefix, "sync-hackathon-")
        XCTAssertEqual(ver.major, 2015)
        XCTAssertEqual(ver.minor, nil)
        XCTAssertEqual(ver.patch, nil)
        XCTAssertEqual(ver.preReleaseMajor, "11-09")
        XCTAssertEqual(ver.preReleaseMinor, nil)
        XCTAssertEqual(ver.buildMajor, nil)
        XCTAssertEqual(ver.buildMinor, nil)
    }

    func testPrefix() throws {
        let parser = SemVerParser("v1.0.2")
        let ver = try parser.parse()
        XCTAssertEqual(ver.fullString, "v1.0.2")
        XCTAssertEqual(ver.prefix, "v")
        XCTAssertEqual(ver.major, 1)
        XCTAssertEqual(ver.minor, 0)
        XCTAssertEqual(ver.patch, 2)
        XCTAssertEqual(ver.preReleaseMajor, nil)
        XCTAssertEqual(ver.preReleaseMinor, nil)
        XCTAssertEqual(ver.buildMajor, nil)
        XCTAssertEqual(ver.buildMinor, nil)
    }

}

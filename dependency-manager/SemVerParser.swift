//
//  SemVerParser.swift
//  dependency-manager
//
//  Created by Simeon Leifer on 9/16/17.
//  Copyright © 2017 droolingcat.com. All rights reserved.
//

import Foundation

let groupOneSeparators: CharacterSet = CharacterSet(charactersIn: ".-+")
let groupTwoSeparators: CharacterSet = CharacterSet(charactersIn: ".+")
let groupThreeSeparators: CharacterSet = CharacterSet(charactersIn: ".")
let groupOneMembers: CharacterSet = CharacterSet(charactersIn: "0123456789")
let groupTwoMembers: CharacterSet = CharacterSet(charactersIn: "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ-")
let groupThreeMembers: CharacterSet = CharacterSet(charactersIn: "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ-")

struct SemVer {
    let major: Int
    let minor: Int?
    let patch: Int?
    let preReleaseMajor: String?
    let preReleaseMajorInt: Int?
    let preReleaseMinor: String?
    let preReleaseMinorInt: Int?
    let buildMajor: String?
    let buildMajorInt: Int?
    let buildMinor: String?
    let buildMinorInt: Int?
    let fullString: String
}

struct MutableSemVer {
    var major: Int?
    var minor: Int?
    var patch: Int?
    var preReleaseMajor: String?
    var preReleaseMajorInt: Int?
    var preReleaseMinor: String?
    var preReleaseMinorInt: Int?
    var buildMajor: String?
    var buildMajorInt: Int?
    var buildMinor: String?
    var buildMinorInt: Int?
    var fullString: String

    init(full: String) {
        fullString = full
    }
}

enum SemVerParserError: Error {
    case noValidVersion
}

enum SemVerScannerState: Int {
    case parsingVersion
    case parsingPreRelease
    case parsingBuild
    case done
}

enum SemVerGroup {
    case version
    case prerelease
    case build

    func valueCharacterSet() -> CharacterSet {
        switch self {
        case .version:
            return groupOneMembers
        case .prerelease:
            return groupTwoMembers
        case .build:
            return groupThreeMembers
        }
    }

    func separatorCharacterSet() -> CharacterSet {
        switch self {
        case .version:
            return groupOneSeparators
        case .prerelease:
            return groupTwoSeparators
        case .build:
            return groupThreeSeparators
        }
    }

}

class SemVerParser {

    var vers: MutableSemVer
    var scanner: Scanner
    var state: SemVerScannerState

    init(_ verStr: String) {
        vers = MutableSemVer(full: verStr)
        scanner = Scanner(string: verStr)
        scanner.charactersToBeSkipped = nil
        state = .parsingVersion
    }

    func parse() throws -> SemVer {
        while state != .done {
            switch state {
            case .parsingVersion:
                try parse(group: .version)
            case .parsingPreRelease:
                try parse(group: .prerelease)
            case .parsingBuild:
                try parse(group: .build)
            case .done:
                break
            }
        }
        if let major = vers.major {
            let outVers = SemVer(major: major, minor: vers.minor, patch: vers.patch, preReleaseMajor: vers.preReleaseMajor, preReleaseMajorInt: vers.preReleaseMajorInt, preReleaseMinor: vers.preReleaseMinor, preReleaseMinorInt: vers.preReleaseMinorInt, buildMajor: vers.buildMajor, buildMajorInt: vers.buildMajorInt, buildMinor: vers.buildMinor, buildMinorInt: vers.buildMinorInt, fullString: vers.fullString)
            return outVers
        } else {
            throw SemVerParserError.noValidVersion
        }
    }

    private func parse(group: SemVerGroup) throws {
        var atEnd: Bool = false
        var separatorStr: String = ""

        if let member = scanner.scanUpToCharacters(from: group.separatorCharacterSet()) {
            atEnd = scanner.isAtEnd
            if let separator = scanner.scanCharacters(from: group.separatorCharacterSet()) {
                if separator.count > 1 {
                    throw SemVerParserError.noValidVersion
                }
                separatorStr = separator
            }

            let validationScanner = Scanner(string: member)
            validationScanner.charactersToBeSkipped = nil
            if let verifyMember = validationScanner.scanCharacters(from: group.valueCharacterSet()) {
                if member == verifyMember {
                    switch state {
                    case .parsingVersion:
                        let value = Int(member)
                        if value == nil {
                            throw SemVerParserError.noValidVersion
                        }
                        if vers.major == nil {
                            vers.major = value
                        } else if vers.minor == nil {
                            vers.minor = value
                        } else if vers.patch == nil {
                            vers.patch = value
                        } else {
                            throw SemVerParserError.noValidVersion
                        }
                        if separatorStr == "-" {
                            state = .parsingPreRelease
                        } else if separatorStr == "+" {
                            state = .parsingBuild
                        }
                    case .parsingPreRelease:
                        if vers.preReleaseMajor == nil {
                            vers.preReleaseMajor = member
                            vers.preReleaseMajorInt = Int(member)
                        } else if vers.preReleaseMinor == nil {
                            vers.preReleaseMinor = member
                            vers.preReleaseMinorInt = Int(member)
                        } else {
                            throw SemVerParserError.noValidVersion
                        }
                        if separatorStr == "+" {
                            state = .parsingBuild
                        }
                    case .parsingBuild:
                        if vers.buildMajor == nil {
                            vers.buildMajor = member
                            vers.buildMajorInt = Int(member)
                        } else if vers.buildMinor == nil {
                            vers.buildMinor = member
                            vers.buildMinorInt = Int(member)
                        } else {
                            throw SemVerParserError.noValidVersion
                        }
                    case .done:
                        throw SemVerParserError.noValidVersion
                    }
                    if atEnd == true {
                        state = .done
                    }
                    return
                }
            }
        }
        throw SemVerParserError.noValidVersion
    }
}

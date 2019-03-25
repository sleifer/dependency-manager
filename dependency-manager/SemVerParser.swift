//
//  SemVerParser.swift
//  dependency-manager
//
//  Created by Simeon Leifer on 9/16/17.
//  Copyright © 2017 droolingcat.com. All rights reserved.
//

import Foundation

let versionGroupSeparators: CharacterSet = CharacterSet(charactersIn: ".-+")
let prereleaseGroupSeparators: CharacterSet = CharacterSet(charactersIn: ".+")
let buildGroupSeparators: CharacterSet = CharacterSet(charactersIn: ".")
let prefixGroupMembers: CharacterSet = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ-")
let versionGroupMembers: CharacterSet = CharacterSet(charactersIn: "0123456789")
let prereleaseGroupMembers: CharacterSet = CharacterSet(charactersIn: "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ-")
let buildGroupMembers: CharacterSet = CharacterSet(charactersIn: "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ-")

struct SemVer {
    let prefix: String?
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

    func matching(fromList: [SemVer], withTest: SemVerComparison) -> [SemVer] {
        let items = fromList.filter { (item: SemVer) -> Bool in
            switch withTest {
            case .equal:
                if item == self {
                    return true
                }
            case .greaterThanOrEqual, .compatible:
                if item >= self {
                    if withTest == .compatible {
                        if self.major != item.major {
                            return false
                        }
                        if let lh = self.minor, lh != item.minor ?? 99 {
                            return false
                        }
                    }
                    return true
                }
            }
            return false
        }
        return items
    }

    func copyDroppingLastVersionElement() -> SemVer? {
        var mutable = MutableSemVer(copying: self)
        if mutable.patch != nil {
            mutable.patch = nil
        } else if mutable.minor != nil {
            mutable.minor = nil
        } else {
            return nil
        }
        mutable.regenerateFullString()
        let newSemVer = mutable.copy()
        return newSemVer
    }
}

extension SemVer {
    init?(_ verStr: String) {
        let parser = SemVerParser(verStr)
        do {
            let semver = try parser.parse()

            self.prefix = semver.prefix
            self.major = semver.major
            self.minor = semver.minor
            self.patch = semver.patch
            self.preReleaseMajor = semver.preReleaseMajor
            self.preReleaseMajorInt = semver.preReleaseMajorInt
            self.preReleaseMinor = semver.preReleaseMinor
            self.preReleaseMinorInt = semver.preReleaseMinorInt
            self.buildMajor = semver.buildMajor
            self.buildMajorInt = semver.buildMajorInt
            self.buildMinor = semver.buildMinor
            self.buildMinorInt = semver.buildMinorInt
            self.fullString = semver.fullString
        } catch {
            return nil
        }
    }
}

enum SemVerComparison: String {
    case equal = "=="
    case greaterThanOrEqual = ">="
    case compatible = "~>"

    init?(test: String) {
        switch test {
        case "eq", "==":
            self = .equal
        case "ge", ">=":
            self = .greaterThanOrEqual
        case "co", "~>":
            self = .compatible
        default:
            return nil
        }
    }
}

extension SemVer: Comparable {
    static func < (lhs: SemVer, rhs: SemVer) -> Bool {
        if lhs.prefix ?? "" != rhs.prefix ?? "" {
            return lhs.prefix ?? "" < rhs.prefix ?? ""
        } else if lhs.major != rhs.major {
            return lhs.major < rhs.major
        } else if lhs.minor ?? 0 != rhs.minor ?? 0 {
            return lhs.minor ?? 0 < rhs.minor ?? 0
        } else if lhs.patch ?? 0 != rhs.patch ?? 0 {
            return lhs.patch ?? 0 < rhs.patch ?? 0
        } else if lhs.preReleaseMajorInt ?? 0 != rhs.preReleaseMajorInt ?? 0 {
            return lhs.preReleaseMajorInt ?? 0 < rhs.preReleaseMajorInt ?? 0
        } else if lhs.preReleaseMajor ?? "~" != rhs.preReleaseMajor ?? "~" {
            return lhs.preReleaseMajor ?? "~" < rhs.preReleaseMajor ?? "~"
        } else if lhs.preReleaseMinorInt ?? 0 != rhs.preReleaseMinorInt ?? 0 {
            return lhs.preReleaseMinorInt ?? 0 < rhs.preReleaseMinorInt ?? 0
        } else if lhs.preReleaseMinor ?? "~" != rhs.preReleaseMinor ?? "~" {
            return lhs.preReleaseMinor ?? "~" < rhs.preReleaseMinor ?? "~"
        } else if lhs.buildMajorInt ?? 0 != rhs.buildMajorInt ?? 0 {
            return lhs.buildMajorInt ?? 0 < rhs.buildMajorInt ?? 0
        } else if lhs.buildMajor ?? "~" != rhs.buildMajor ?? "~" {
            return lhs.buildMajor ?? "~" < rhs.buildMajor ?? "~"
        } else if lhs.buildMinorInt ?? 0 != rhs.buildMinorInt ?? 0 {
            return lhs.buildMinorInt ?? 0 < rhs.buildMinorInt ?? 0
        } else if lhs.buildMinor ?? "~" != rhs.buildMinor ?? "~" {
            return lhs.buildMinor ?? "~" < rhs.buildMinor ?? "~"
        } else {
            return lhs.fullString < rhs.fullString
        }
    }

    static func == (lhs: SemVer, rhs: SemVer) -> Bool {
        if lhs.prefix ?? "" != rhs.prefix ?? "" {
            return false
        } else if lhs.major != rhs.major {
            return false
        } else if lhs.minor ?? 0 != rhs.minor ?? 0 {
            return false
        } else if lhs.patch ?? 0 != rhs.patch ?? 0 {
            return false
        } else if lhs.preReleaseMajorInt ?? 0 != rhs.preReleaseMajorInt ?? 0 {
            return false
        } else if lhs.preReleaseMajor ?? "~" != rhs.preReleaseMajor ?? "~" {
            return false
        } else if lhs.preReleaseMinorInt ?? 0 != rhs.preReleaseMinorInt ?? 0 {
            return false
        } else if lhs.preReleaseMinor ?? "~" != rhs.preReleaseMinor ?? "~" {
            return false
        } else if lhs.buildMajorInt ?? 0 != rhs.buildMajorInt ?? 0 {
            return false
        } else if lhs.buildMajor ?? "~" != rhs.buildMajor ?? "~" {
            return false
        } else if lhs.buildMinorInt ?? 0 != rhs.buildMinorInt ?? 0 {
            return false
        } else if lhs.buildMinor ?? "~" != rhs.buildMinor ?? "~" {
            return false
        }
        return true
    }
}

struct MutableSemVer {
    var prefix: String?
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

    init(copying: SemVer) {
        prefix = copying.prefix
        major = copying.major
        minor = copying.minor
        patch = copying.patch
        preReleaseMajor = copying.preReleaseMajor
        preReleaseMajorInt = copying.preReleaseMajorInt
        preReleaseMinor = copying.preReleaseMinor
        preReleaseMinorInt = copying.preReleaseMinorInt
        buildMajor = copying.buildMajor
        buildMajorInt = copying.buildMajorInt
        buildMinor = copying.buildMinor
        buildMinorInt = copying.buildMinorInt
        fullString = copying.fullString
    }

    func copy() -> SemVer {
        let outVers = SemVer(prefix: self.prefix, major: self.major ?? 0, minor: self.minor, patch: self.patch, preReleaseMajor: self.preReleaseMajor, preReleaseMajorInt: self.preReleaseMajorInt, preReleaseMinor: self.preReleaseMinor, preReleaseMinorInt: self.preReleaseMinorInt, buildMajor: self.buildMajor, buildMajorInt: self.buildMajorInt, buildMinor: self.buildMinor, buildMinorInt: self.buildMinorInt, fullString: self.fullString)
        return outVers
    }

    mutating func regenerateFullString() {
        let prefix = self.prefix ?? ""

        var versParts: [String] = []
        if let value = self.major {
            versParts.append(String(value))
        }
        if let value = self.minor {
            versParts.append(String(value))
        }
        if let value = self.patch {
            versParts.append(String(value))
        }
        let version = versParts.joined(separator: ".")

        var prerelease: String = ""
        if let major = self.preReleaseMajor, let minor = self.preReleaseMinor {
            prerelease = "-\(major).\(minor)"
        } else if let major = self.preReleaseMajor {
            prerelease = "-\(major)"
        } else if let minor = self.preReleaseMinor {
            prerelease = "-\(minor)"
        }

        var build: String = ""
        if let major = self.buildMajor, let minor = self.buildMinor {
            build = "+\(major).\(minor)"
        } else if let major = self.buildMajor {
            build = "+\(major)"
        } else if let minor = self.buildMinor {
            build = "+\(minor)"
        }

        self.fullString = prefix + version + prerelease + build
    }
}

enum SemVerParserError: Error {
    case noValidVersion
}

enum SemVerScannerState: Int {
    case parsingPrefix
    case parsingVersion
    case parsingPreRelease
    case parsingBuild
    case done
}

enum SemVerGroup {
    case prefix
    case version
    case prerelease
    case build

    func valueCharacterSet() -> CharacterSet {
        switch self {
        case .prefix:
            return prefixGroupMembers
        case .version:
            return versionGroupMembers
        case .prerelease:
            return prereleaseGroupMembers
        case .build:
            return buildGroupMembers
        }
    }

    func separatorCharacterSet() -> CharacterSet? {
        switch self {
        case .prefix:
            return nil
        case .version:
            return versionGroupSeparators
        case .prerelease:
            return prereleaseGroupSeparators
        case .build:
            return buildGroupSeparators
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
        state = .parsingPrefix
    }

    func parse() throws -> SemVer {
        while state != .done {
            switch state {
            case .parsingPrefix:
                try parse(group: .prefix)
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
            let outVers = SemVer(prefix: vers.prefix, major: major, minor: vers.minor, patch: vers.patch, preReleaseMajor: vers.preReleaseMajor, preReleaseMajorInt: vers.preReleaseMajorInt, preReleaseMinor: vers.preReleaseMinor, preReleaseMinorInt: vers.preReleaseMinorInt, buildMajor: vers.buildMajor, buildMajorInt: vers.buildMajorInt, buildMinor: vers.buildMinor, buildMinorInt: vers.buildMinorInt, fullString: vers.fullString)
            return outVers
        } else {
            throw SemVerParserError.noValidVersion
        }
    }

    // swiftlint:disable cyclomatic_complexity

    private func parse(group: SemVerGroup) throws {
        var atEnd: Bool = false
        var separatorStr: String = ""
        var member: String?

        if let separatorSet = group.separatorCharacterSet() {
            if let value = scanner.scanUpToCharacters(from: separatorSet) {
                member = value
                atEnd = scanner.isAtEnd
                if let separator = scanner.scanCharacters(from: separatorSet) {
                    if separator.count > 1 {
                        throw SemVerParserError.noValidVersion
                    }
                    separatorStr = separator
                }
            }
        } else {
            member = scanner.scanCharacters(from: group.valueCharacterSet())
            atEnd = scanner.isAtEnd
        }

        if let member = member {
            let validationScanner = Scanner(string: member)
            validationScanner.charactersToBeSkipped = nil
            if let verifyMember = validationScanner.scanCharacters(from: group.valueCharacterSet()) {
                if member == verifyMember {
                    switch state {
                    case .parsingPrefix:
                        vers.prefix = member
                        state = .parsingVersion
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
            } else {
                switch state {
                case .parsingPrefix:
                    state = .parsingVersion
                    return
                case .parsingVersion, .parsingPreRelease, .parsingBuild, .done:
                    throw SemVerParserError.noValidVersion
                }
            }
        } else {
            switch state {
            case .parsingPrefix:
                state = .parsingVersion
                return
            case .parsingVersion, .parsingPreRelease, .parsingBuild, .done:
                throw SemVerParserError.noValidVersion
            }
        }
        throw SemVerParserError.noValidVersion
    }

    // swiftlint:enable cyclomatic_complexity
}

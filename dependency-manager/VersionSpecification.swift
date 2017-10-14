//
//  VersionSpecification.swift
//  dependency-manager
//
//  Created by Simeon Leifer on 10/14/17.
//  Copyright © 2017 droolingcat.com. All rights reserved.
//

import Foundation

struct VersionSpec {
    var name: String
    var comparison: SemVerComparison
    var version: String
    var semver: SemVer?

    func toStr() -> String {
        return "\(name), \(comparison.rawValue) \(version)"
    }

    func versSpecStr() -> String {
        return "\(comparison.rawValue) \(version)"
    }
}

extension VersionSpec: Comparable {
    static func < (lhs: VersionSpec, rhs: VersionSpec) -> Bool {
        return lhs.name < rhs.name
    }

    static func == (lhs: VersionSpec, rhs: VersionSpec) -> Bool {
        return lhs.name == rhs.name
    }
}

enum VersionSpecParseRegex: Int {
    case whole = 0
    case name
    case comparison
    case version
    case count

    static func pattern() -> String {
        return "([a-zA-Z0-9-_]+) *, *(==|>=|~>) *(.*)"
    }
}

extension Array where Element:StringProtocol {
    func versionSpec(_ part: VersionSpecParseRegex) -> Element {
        return self[part.rawValue]
    }
}

class VersionSpecification {

    var specs: [String: VersionSpec] = [:]

    init() {
    }

    init(fromFile: String) {
        do {
            let text = try String(contentsOfFile: fromFile)
            let matches = text.regex(VersionSpecParseRegex.pattern())
            for match in matches {
                if let comp = SemVerComparison(rawValue: match.versionSpec(.comparison)) {
                    var semver: SemVer?
                    let parser = SemVerParser(match.versionSpec(.version))
                    do {
                        semver = try parser.parse()
                    } catch {
                    }
                    if let semver = semver {
                        let spec = VersionSpec(name: match.versionSpec(.name), comparison: comp, version: match.versionSpec(.version), semver: semver)
                        specs[spec.name] = spec
                    }
                }
            }
        } catch {
            print(error)
        }
    }

    func write(toFile: String) {
        let items = specs.values.map { (spec) -> String in
            return spec.toStr()
        }
        let text = items.joined(separator: "\n")
        do {
            try text.write(toFile: toFile, atomically: true, encoding: .utf8)
        } catch {
            print(error)
        }
    }

    func spec(forName: String) -> VersionSpec? {
        return specs[forName]
    }

    func setSpec(name: String, spec: VersionSpec?) {
        if let spec = spec {
            specs[name] = spec
        } else {
            specs.removeValue(forKey: name)
        }
    }
}

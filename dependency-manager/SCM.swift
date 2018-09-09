//
//  SCM.swift
//  dependency-manager
//
//  Created by Simeon Leifer on 10/11/17.
//  Copyright © 2017 droolingcat.com. All rights reserved.
//

import Foundation
import CommandLineCore

enum SCMError: Error {
    case scmCommandMissing
}

public enum SCMResult {
    case success(text: String)
    case error(code: Int32, text: String)

    func text() -> String {
        switch self {
        case .success(let text):
            return text
        case .error(_, let text):
            return text
        }
    }

    func code() -> Int32 {
        switch self {
        case .success:
            return 0
        case .error(let code, _):
            return code
        }
    }
}

protocol NamedObject {
    var name: String { get }
}

struct SubmoduleInfo: NamedObject {
    let sha: String
    let path: String
    let url: String
    let name: String
    let version: String
    let semver: SemVer?
}

extension SubmoduleInfo: Comparable {
    static func < (lhs: SubmoduleInfo, rhs: SubmoduleInfo) -> Bool {
        return lhs.name < rhs.name
    }

    static func == (lhs: SubmoduleInfo, rhs: SubmoduleInfo) -> Bool {
        return lhs.name == rhs.name
    }
}

extension Array where Element: NamedObject {
    func spec(named: String) -> Element? {
        return self.filter { (item) -> Bool in
            return item.name == named
        }.first
    }
}

protocol SCM {
    var verbose: Bool { get set }
    var isInstalled: Bool { get }
    var isInitialized: Bool { get }

    func submodules() -> [SubmoduleInfo]

    @discardableResult
    func fetch(_ path: String) -> SCMResult

    @discardableResult
    func checkout(_ path: String, object: String) -> SCMResult

    func tags(_ path: String) -> [SemVer]
}

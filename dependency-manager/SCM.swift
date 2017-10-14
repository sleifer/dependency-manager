//
//  SCM.swift
//  dependency-manager
//
//  Created by Simeon Leifer on 10/11/17.
//  Copyright © 2017 droolingcat.com. All rights reserved.
//

import Foundation

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
        case .success(_):
            return 0
        case .error(let code, _):
            return code
        }
    }
}

struct SubmoduleInfo {
    let path: String
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

extension SCM {
    @discardableResult
    func runCommand(_ cmd: String, args: [String], completion: ProcessRunnerHandler? = nil) -> ProcessRunner {
        let runner = ProcessRunner(cmd, args: args)
        var done: Bool = false
        runner.start() { (runner) in
            if let completion = completion {
                completion(runner)
            }
            done = true
        }
        if completion == nil {
            while done == false {
                spinRunLoop()
            }
            return runner
        }
        return runner
    }
}

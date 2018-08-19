//
//  OutdatedCommand.swift
//  dependency-manager
//
//  Created by Simeon Leifer on 10/11/17.
//  Copyright © 2017 droolingcat.com. All rights reserved.
//

import Foundation
import CommandLineCore

class OutdatedCommand: Command {
    override func run(cmd: ParsedCommand) {
        let submodules = scm.submodules()
        for submodule in submodules {
            print("submodule: \(submodule.name)")
            print("  path: \(submodule.path)")
            print("  url: \(submodule.url)")
            print("  current version: \(submodule.version)")

            var newver: SemVer? = nil
            if let spec = versionSpecs.spec(forName: submodule.name), let semver = spec.semver, let moduleSemver = submodule.semver {
                print("  spec: \(spec.versSpecStr())")

                let result = scm.fetch(submodule.path)
                if case .error(_, let text) = result {
                    print(text)
                }

                let tags = scm.tags(submodule.path)
                let matching = semver.matching(fromList: tags, withTest: spec.comparison)
                if let last = matching.last {
                    if submodule.semver == nil {
                        newver = last
                    } else if let cursemver = submodule.semver, last > cursemver {
                        newver = last
                    }
                    if let newver = newver {
                        print("  New version available: \(newver.fullString)")
                    } else {
                        print("  Up to date.")
                    }
                } else {
                    print("  No versions matching spec found.")
                }

                let outOfBandFull = "\(moduleSemver.prefix ?? "")\(moduleSemver.major).\(moduleSemver.minor ?? 0).\(moduleSemver.patch ?? 0)"
                if let outOfBandBase = SemVer.init(outOfBandFull) {
                    let matching = outOfBandBase.matching(fromList: tags, withTest: .greaterThanOrEqual)
                    if let last = matching.last {
                        if last > moduleSemver && (newver == nil || last > newver!) {
                            print("  Out of spec new version available: \(last.fullString)")
                        }
                    }
                }
            }

            print()
        }
    }
}

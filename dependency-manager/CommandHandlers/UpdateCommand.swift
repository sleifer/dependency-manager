//
//  UpdateCommand.swift
//  dependency-manager
//
//  Created by Simeon Leifer on 10/11/17.
//  Copyright © 2017 droolingcat.com. All rights reserved.
//

import Foundation
import CommandLineCore

class UpdateCommand: Command {
    override func run(cmd: ParsedCommand) {
        let submodules = scm.submodules()
        for submodule in submodules {
            var updateIt: Bool = true
            if cmd.parameters.count != 0 {
                if cmd.parameters.contains(submodule.name) == true {
                    updateIt = true
                } else {
                    updateIt = false
                }
            }
            if updateIt == true {
                print("submodule: \(submodule.name)")
                print("  path: \(submodule.path)")
                print("  current version: \(submodule.version)")

                var newver: SemVer? = nil
                if let spec = versionSpecs.spec(forName: submodule.name), let semver = spec.semver {
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
                            print("  Updating to version: \(newver.fullString)")
                            scm.checkout(submodule.path, object: newver.fullString)
                        } else {
                            print("  Up to date.")
                        }
                    } else {
                        print("  No versions matching spec found.")
                    }
                }

                print()
            }
        }
    }
}

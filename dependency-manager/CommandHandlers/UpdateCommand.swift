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
    required init() {
    }

    func run(cmd: ParsedCommand, core: CommandCore) {
        let submodules = scm.submodules()
        if submodules.count == 0 {
            print("Either there are no submodules or they have not been initialized.")
        }

        let catalog = Catalog.load()
        var addedToCatalog: Bool = false

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
                print("  url: \(submodule.url)")
                print("  current version: \(submodule.version)")

                addedToCatalog = addedToCatalog || catalog.add(name: submodule.name, url: submodule.url)

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
                            if let cursemver = submodule.semver, last < cursemver {
                                print("  Current version is beyond spec.")
                            } else {
                                print("  Up to date.")
                            }
                        }
                    } else {
                        print("  No versions matching spec found.")
                    }
                }

                print()
            }
        }

        if addedToCatalog == true {
            catalog.save()
        }
    }

    static func commandDefinition() -> SubcommandDefinition {
        var command = SubcommandDefinition()
        command.name = "update"
        command.synopsis = "Update one or all submodules to latest valid version"

        var parameter = ParameterInfo()
        parameter.hint = "module-name"
        parameter.help = "Name of module to update"

        if scm.isInstalled == true && scm.isInitialized == true {
            let submodules = scm.submodules()
            parameter.completions = submodules.map { (info) -> String in
                return info.name
            }
        }
        command.optionalParameters.append(parameter)

        return command
    }
}

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
    required init() {
    }

    // swiftlint:disable cyclomatic_complexity

    func run(cmd: ParsedCommand, core: CommandCore) {
        var verbose = false
        if cmd.option("--verbose") != nil {
            verbose = true
        }

        let submodules = scm.submodules()
        if submodules.count == 0 {
            print("Either there are no submodules or they have not been initialized.")
        }

        let catalog = Catalog.load()
        var addedToCatalog: Bool = false

        for submodule in submodules {
            if verbose == true {
                print("submodule: \(submodule.name)")
                print("  path: \(submodule.path)")
                print("  url: \(submodule.url)")
                print("  current version: \(submodule.version)")
            }

            addedToCatalog = addedToCatalog || catalog.add(name: submodule.name, url: submodule.url)

            var newver: SemVer?
            if let spec = versionSpecs.spec(forName: submodule.name), let semver = spec.semver, let moduleSemver = submodule.semver {
                if verbose == true {
                    print("  spec: \(spec.versSpecStr())")
                } else {
                    print("\(submodule.name) \(spec.versSpecStr()) @ \(submodule.version)")
                }

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
                        if let cursemver = submodule.semver, last < cursemver {
                            print("  Current version is beyond spec.")
                        } else {
                            print("  Up to date.")
                        }
                    }
                } else {
                    print("  No versions matching spec found.")
                }

                let outOfBandFull = "\(moduleSemver.prefix ?? "")\(moduleSemver.major).\(moduleSemver.minor ?? 0).\(moduleSemver.patch ?? 0)"
                if let outOfBandBase = SemVer.init(outOfBandFull) {
                    let release = tags.filter { (ver) -> Bool in
                        if ver.preReleaseMajor == nil {
                            return true
                        }
                        return false
                    }
                    if release.count > 0 {
                        let matching = outOfBandBase.matching(fromList: release, withTest: .greaterThanOrEqual)
                        if let last = matching.last {
                            if last > moduleSemver && (newver == nil || last > newver!) {
                                print("  Out of spec new version available: \(last.fullString)")
                            }
                        }
                    }
                    let prerelease = tags.filter { (ver) -> Bool in
                        if ver.preReleaseMajor == nil {
                            return false
                        }
                        return true
                    }
                    if prerelease.count > 0 {
                        let matching = outOfBandBase.matching(fromList: prerelease, withTest: .greaterThanOrEqual)
                        if let last = matching.last {
                            if last > moduleSemver && (newver == nil || last > newver!) {
                                print("  Out of spec new prerelease version available: \(last.fullString)")
                            }
                        }
                    }
                }
            } else {
                if verbose == false {
                    print("\(submodule.name) @ \(submodule.version)")
                }
            }

            print()
        }

        if addedToCatalog == true {
            catalog.save()
        }
    }

    // swiftlint:enable cyclomatic_complexity

    static func commandDefinition() -> SubcommandDefinition {
        var command = SubcommandDefinition()
        command.name = "outdated"
        command.synopsis = "Check all submodules for newer valid version"

        var verboseOption = CommandOption()
        verboseOption.shortOption = "-v"
        verboseOption.longOption = "--verbose"
        verboseOption.help = "Verbose output (module urls)"
        command.options.append(verboseOption)

        return command
    }
}

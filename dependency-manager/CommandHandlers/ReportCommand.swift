//
//  ReportCommand.swift
//  dependency-manager
//
//  Created by Simeon Leifer on 7/27/18.
//  Copyright © 2018 droolingcat.com. All rights reserved.
//

import CommandLineCore
import Foundation

class ReportCommand: Command {
    var ceilingDirectory: String = "/"

    required init() {}

    // swiftlint:disable cyclomatic_complexity

    /// Check a submodule for updates relative to a spec
    /// - Parameters:
    ///   - submodule: submodule to check for updates
    ///   - aSpec: spec to test against
    ///   - terse: Bool for whether result message should be terse or not (suitable for CSV); false by default
    ///   - noAlpha: Bool for whether to ignore alpha prerelease or not; false by default
    ///   - noBeta: Bool for whether to ignore beta prerelease or not; false by default
    /// - Returns: a tuple with update info message, bool for whether submodule is up to date
    fileprivate func updateCheck(_ submodule: SubmoduleInfo, _ aSpec: VersionSpec, terse: Bool = false, noAlpha: Bool = false, noBeta: Bool = false) -> (String, Bool) {
        var msg: String = ""
        var current: Bool = true
        let result = scm.fetch(submodule.path)
        if case .error(_, let text) = result {
            if terse == true {
                msg = "<fetch error>"
            } else {
                msg = text
            }
        }

        var newver: SemVer?
        let tags = scm.tags(submodule.path)
        if let semver = aSpec.semver {
            let matching = semver.matching(fromList: tags, withTest: aSpec.comparison)
            if let last = matching.last {
                if submodule.semver == nil {
                    newver = last
                } else if let cursemver = submodule.semver, last > cursemver {
                    newver = last
                }
                if let newver = newver {
                    current = false
                    if terse == true {
                        msg = "update available: \(newver.fullString)"
                    } else {
                        msg = "      New version available: \(newver.fullString)"
                    }
                } else {
                    if let cursemver = submodule.semver, last < cursemver {
                        current = false
                        if terse == true {
                            msg = "beyond spec"
                        } else {
                            msg = "      Current version is beyond spec."
                        }
                    } else {
                        if terse == true {
                            msg = "up to date"
                        } else {
                            msg = "      Up to date."
                        }
                    }
                }
            } else {
                current = false
                if terse == true {
                    msg = "no matching spec found"
                } else {
                    msg = "      No versions matching spec found."
                }
            }
        }

        if let moduleSemver = submodule.semver {
            let outOfBandFull = "\(moduleSemver.prefix ?? "")\(moduleSemver.major).\(moduleSemver.minor ?? 0).\(moduleSemver.patch ?? 0)"
            if let outOfBandBase = SemVer(outOfBandFull) {
                let release = tags.filter { (ver) -> Bool in
                    if ver.preReleaseMajor == nil {
                        return true
                    }
                    return false
                }
                if release.count > 0 {
                    let matching = outOfBandBase.matching(fromList: release, withTest: .greaterThanOrEqual)
                    if let last = matching.last {
                        if last > moduleSemver, newver == nil || last > newver! {
                            if terse == true {
                                current = false
                                if msg.count > 0 {
                                    msg += ", "
                                }
                                msg += "upgrade available: \(last.fullString)"
                            } else {
                                current = false
                                if msg.count > 0 {
                                    msg += "\n"
                                }
                                msg += "      Out of spec new version available: \(last.fullString)"
                            }
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
                        if last > moduleSemver, newver == nil || last > newver!, noAlpha == false || last.preReleaseMajor != "alpha", noBeta == false || last.preReleaseMajor != "beta" {
                            if terse == true {
                                current = false
                                if msg.count > 0 {
                                    msg += ", "
                                }
                                msg += "prerelease upgrade available: \(last.fullString)"
                            } else {
                                current = false
                                if msg.count > 0 {
                                    msg += "\n"
                                }
                                msg += "      Out of spec new prerelease version available: \(last.fullString)"
                            }
                        }
                    }
                }
            }
        }

        if msg.count == 0 {
            current = false
            if terse == true {
                msg = "no version specifier"
            } else {
                msg = "      No version specifier."
            }
        }

        return (msg, current)
    }

    // swiftlint:enable cyclomatic_complexity

    // swiftlint:disable cyclomatic_complexity

    func run(cmd: ParsedCommand, core: CommandCore) {
        let verbose = cmd.boolOption("--verbose")
        let csv = cmd.boolOption("--csv")
        let unmanaged = cmd.boolOption("--unmanaged")
        let info = cmd.boolOption("--info")
        let check = cmd.boolOption("--check")
        let nocurrent = cmd.boolOption("--nocurrent")
        let noalpha = cmd.boolOption("--noalpha")
        let nobeta = cmd.boolOption("--nobeta")

        let baseDirectory = FileManager.default.currentDirectoryPath
        ceilingDirectory = baseDirectory.deletingLastPathComponent

        var searchDirPaths = cmd.parameters

        if cmd.parameters.count == 0 {
            searchDirPaths.append(FileManager.default.currentDirectoryPath)
        }

        let filters = cmd.options(named: "--filter").compactMap { (option) -> String? in
            option.arguments.first
        }

        let catalog = Catalog.load()

        for searchDirPath in searchDirPaths {
            if csv == true {
                if check == true {
                    print("\"project name\",\"project path\",\"module name\",\"module spec\",\"module version\",\"updates\",\"module path\",\"module url\",\"managed\"")
                } else if info == true {
                    print("\"project name\",\"project path\",\"module name\",\"module spec\",\"module version\",\"module path\",\"module url\",\"managed\"")
                } else {
                    print("\"project name\",\"project path\",\"module name\",\"module path\",\"module url\",\"managed\"")
                }
            } else {
                print("\nReport in \(searchDirPath):")
            }

            let fm = FileManager.default
            let enumerator = fm.enumerator(atPath: searchDirPath)
            while let file = enumerator?.nextObject() as? String {
                if file.lastPathComponent == ".git" {
                    let dirPath = searchDirPath.appendingPathComponent(file).deletingLastPathComponent
                    let specPath = dirPath.appendingPathComponent(versionSpecsFileName)
                    if fm.fileExists(atPath: specPath) == true {
                        fm.changeCurrentDirectoryPath(dirPath)
                        CommandCore.core!.set(baseDirectory: dirPath)
                        let modules = scm.submodules()
                        let name = file.deletingLastPathComponent.lastPathComponent
                        let spec = VersionSpecification(fromFile: specPath)
                        var header: String? = "  Project: \(name)\n  \(dirPath)"
                        for aSpec in spec.allSpecs() {
                            if csv == true {
                                if let submodule = modules.spec(named: aSpec.name) {
                                    catalog.add(name: aSpec.name, url: submodule.url)
                                    if check == true {
                                        let (updateText, current) = updateCheck(submodule, aSpec, terse: true, noAlpha: noalpha, noBeta: nobeta)
                                        if !(nocurrent == true && current == true) {
                                            print("\"\(name)\",\"\(dirPath)\",\"\(aSpec.name)\",\"\(aSpec.versSpecStr()) \",\"\(submodule.version)\",\"\(updateText)\",\"\(submodule.path)\",\"\(submodule.url)\",\"managed\"")
                                        }
                                    } else if info == true {
                                        if filters.count == 0 || filters.contains(aSpec.name) {
                                            print("\"\(name)\",\"\(dirPath)\",\"\(aSpec.name)\",\"\(aSpec.versSpecStr()) \",\"\(submodule.version)\",\"\(submodule.path)\",\"\(submodule.url)\",\"managed\"")
                                        }
                                    } else {
                                        if filters.count == 0 || filters.contains(aSpec.name) {
                                            print("\"\(name)\",\"\(dirPath)\",\"\(aSpec.name)\",\"\(submodule.path)\",\"\(submodule.url)\",\"managed\"")
                                        }
                                    }
                                }
                            } else {
                                if let submodule = modules.spec(named: aSpec.name) {
                                    catalog.add(name: aSpec.name, url: submodule.url)

                                    if filters.count == 0 || filters.contains(aSpec.name) {
                                        if let text = header {
                                            print(text)
                                            header = nil
                                        }
                                        if info == true || check == true {
                                            print("    \(aSpec.name) \(aSpec.versSpecStr()) @ \(submodule.version)")

                                            if check == true {
                                                let (updateText, current) = updateCheck(submodule, aSpec)
                                                if !(nocurrent == true && current == true) {
                                                    print(updateText)
                                                }
                                            }
                                        } else {
                                            print("    \(aSpec.name)")
                                        }
                                        if verbose == true {
                                            print("      path: \(submodule.path)")
                                            print("      url: \(submodule.url)")
                                        }
                                    }
                                }
                            }
                        }
                    } else if unmanaged == true, isInManagedDir(path: dirPath) == false {
                        fm.changeCurrentDirectoryPath(dirPath)
                        let modules: [SubmoduleInfo] = scm.submodules()
                        if modules.count > 0 {
                            let name = dirPath.lastPathComponent
                            if csv == false {
                                print("  Project: \(name) (unmanaged)")
                                print("  \(dirPath)")
                            }
                            for module in modules {
                                if csv == true {
                                    catalog.add(name: module.name, url: module.url)
                                    print("\"\(name)\",\"\(dirPath)\",\"\(module.name)\",\"\(module.path)\",\"\(module.url)\",\"unmanaged\"")
                                } else {
                                    print("    \(module.name)")
                                    catalog.add(name: module.name, url: module.url)
                                    if verbose == true {
                                        print("      path: \(module.path)")
                                        print("      url: \(module.url)")
                                    }
                                }
                            }
                        }
                    }
                }
            }
            if csv == false {
                print("Done.")
            }
        }

        catalog.save()

        FileManager.default.changeCurrentDirectoryPath(baseDirectory)
    }

    // swiftlint:enable cyclomatic_complexity

    static func commandDefinition() -> SubcommandDefinition {
        var command = SubcommandDefinition()
        command.name = "report"
        command.synopsis = "Report on modules used in one or more repositories"
        command.hasFileParameters = true
        command.warnOnMissingSpec = false

        var infoOption = CommandOption()
        infoOption.shortOption = "-i"
        infoOption.longOption = "--info"
        infoOption.help = "Show current versions of modules"
        command.options.append(infoOption)

        var noUpToDateOption = CommandOption()
        noUpToDateOption.longOption = "--nocurrent"
        noUpToDateOption.help = "Do not show items that are up to date with no available updates"
        command.options.append(noUpToDateOption)

        var noAlphaOption = CommandOption()
        noAlphaOption.longOption = "--noalpha"
        noAlphaOption.help = "Do not show items that are labeled alpha"
        command.options.append(noAlphaOption)

        var noBetaOption = CommandOption()
        noBetaOption.longOption = "--nobeta"
        noBetaOption.help = "Do not show items that are labeled beta"
        command.options.append(noBetaOption)

        var checkOption = CommandOption()
        checkOption.shortOption = "-k"
        checkOption.longOption = "--check"
        checkOption.help = "Check for updates to modules"
        command.options.append(checkOption)

        var verboseOption = CommandOption()
        verboseOption.shortOption = "-v"
        verboseOption.longOption = "--verbose"
        verboseOption.help = "Verbose output (module urls)"
        command.options.append(verboseOption)

        var unmanagedOption = CommandOption()
        unmanagedOption.shortOption = "-u"
        unmanagedOption.longOption = "--unmanaged"
        unmanagedOption.help = "Report on projects that do not use dependency manager but have submodules"
        command.options.append(unmanagedOption)

        var csvOption = CommandOption()
        csvOption.shortOption = "-c"
        csvOption.longOption = "--csv"
        csvOption.help = "Output report in CSV format"
        command.options.append(csvOption)

        var filterOption = CommandOption()
        filterOption.shortOption = "-f"
        filterOption.longOption = "--filter"
        filterOption.help = "Only show projects using specific module"
        filterOption.argumentCount = 1

        let catalog = Catalog.load()
        filterOption.completions = catalog.entries.map { (entry) -> String in
            entry.name
        }.sorted { (left, right) -> Bool in
            if left.lowercased() < right.lowercased() {
                return true
            }
            return false
        }

        command.options.append(filterOption)

        var parameter = ParameterInfo()
        parameter.hint = "path"
        parameter.help = "Path to repository or directory or repositories"
        command.optionalParameters.append(parameter)

        return command
    }

    func isInManagedDir(path: String) -> Bool {
        let fm = FileManager.default
        var inManaged: Bool = false
        var dirPath = path.deletingLastPathComponent
        while true {
            let specPath = dirPath.appendingPathComponent(versionSpecsFileName)
            if fm.fileExists(atPath: specPath) == true {
                inManaged = true
                return inManaged
            }
            dirPath = dirPath.deletingLastPathComponent
            if dirPath == ceilingDirectory {
                return inManaged
            }
        }
    }
}

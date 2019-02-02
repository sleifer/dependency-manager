//
//  ReportCommand.swift
//  dependency-manager
//
//  Created by Simeon Leifer on 7/27/18.
//  Copyright © 2018 droolingcat.com. All rights reserved.
//

import Foundation
import CommandLineCore
import ObjectMapper

class ReportCommand: Command {
    var ceilingDirectory: String = "/"

    required init() {
    }

    fileprivate func updateCheck(_ submodule: SubmoduleInfo, _ aSpec: VersionSpec, terse: Bool = false) -> String {
        let result = scm.fetch(submodule.path)
        if case .error(_, let text) = result {
            if terse == true {
                return "<error>"
            } else {
                return text
            }
        }

        var newver: SemVer? = nil
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
                    if terse == true {
                        return "update available: \(newver.fullString)"
                    } else {
                        return "      New version available: \(newver.fullString)"
                    }
                } else {
                    if let cursemver = submodule.semver, last < cursemver {
                        if terse == true {
                            return "beyond spec"
                        } else {
                            return "      Current version is beyond spec."
                        }
                    } else {
                        if terse == true {
                            return "up to date"
                        } else {
                            return "      Up to date."
                        }
                    }
                }
            } else {
                if terse == true {
                    return "no matching spec found"
                } else {
                    return "      No versions matching spec found."
                }
            }
        }

        if let moduleSemver = submodule.semver {
            let outOfBandFull = "\(moduleSemver.prefix ?? "")\(moduleSemver.major).\(moduleSemver.minor ?? 0).\(moduleSemver.patch ?? 0)"
            if let outOfBandBase = SemVer.init(outOfBandFull) {
                let matching = outOfBandBase.matching(fromList: tags, withTest: .greaterThanOrEqual)
                if let last = matching.last {
                    if last > moduleSemver && (newver == nil || last > newver!) {
                        if terse == true {
                            return "upgrade available: \(last.fullString)"
                        } else {
                            return "      Out of spec new version available: \(last.fullString)"
                        }
                    }
                }
            }
        }

        if terse == true {
            return "no version specifier"
        } else {
            return "      No version specifier."
        }
    }

    func run(cmd: ParsedCommand, core: CommandCore) {
        var verbose = false
        if cmd.option("--verbose") != nil {
            verbose = true
        }
        var csv = false
        if cmd.option("--csv") != nil {
            csv = true
        }
        var unmanaged = false
        if cmd.option("--unmanaged") != nil {
            unmanaged = true
        }
        var info = false
        if cmd.option("--info") != nil {
            info = true
        }
        var check = false
        if cmd.option("--check") != nil {
            check = true
        }

        let baseDirectory = FileManager.default.currentDirectoryPath
        ceilingDirectory = baseDirectory.deletingLastPathComponent

        var searchDirPaths = cmd.parameters

        if cmd.parameters.count == 0 {
            searchDirPaths.append(FileManager.default.currentDirectoryPath)
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
                        if csv == false {
                            print("  Project: \(name)")
                            print("  \(dirPath)")
                        }
                        for aSpec in spec.allSpecs() {
                            if csv == true {
                                if let submodule = modules.spec(named: aSpec.name) {
                                    catalog.add(name: aSpec.name, url: submodule.url)
                                    if check == true {
                                        let updateText = updateCheck(submodule, aSpec, terse: true)
                                        print("\"\(name)\",\"\(dirPath)\",\"\(aSpec.name)\",\"\(aSpec.versSpecStr()) \",\"\(submodule.version)\",\"\(updateText)\",\"\(submodule.path)\",\"\(submodule.url)\",\"managed\"")
                                    } else  if info == true {
                                        print("\"\(name)\",\"\(dirPath)\",\"\(aSpec.name)\",\"\(aSpec.versSpecStr()) \",\"\(submodule.version)\",\"\(submodule.path)\",\"\(submodule.url)\",\"managed\"")
                                    } else {
                                        print("\"\(name)\",\"\(dirPath)\",\"\(aSpec.name)\",\"\(submodule.path)\",\"\(submodule.url)\",\"managed\"")
                                    }
                                }
                            } else {
                                if let submodule = modules.spec(named: aSpec.name) {
                                    catalog.add(name: aSpec.name, url: submodule.url)
                                    if info == true || check == true {
                                        print("    \(aSpec.name) \(aSpec.versSpecStr()) @ \(submodule.version)")

                                        if check == true {
                                            let updateText = updateCheck(submodule, aSpec)
                                            print(updateText)
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
                    } else if unmanaged == true && isInManagedDir(path: dirPath) == false {
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
        return inManaged
    }
}

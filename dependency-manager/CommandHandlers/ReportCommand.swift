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
    required init() {
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

        let baseDirectory = FileManager.default.currentDirectoryPath

        var searchDirPaths = cmd.parameters

        if cmd.parameters.count == 0 {
            searchDirPaths.append(FileManager.default.currentDirectoryPath)
        }

        let catalog = Catalog.load()

        for searchDirPath in searchDirPaths {
            if csv == true {
                print("\"project name\",\"project path\",\"module name\",\"module path\",\"module url\",\"managed\"")
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
                        FileManager.default.changeCurrentDirectoryPath(dirPath)
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
                                    print("\"\(name)\",\"\(dirPath)\",\"\(aSpec.name)\",\"\(submodule.path)\",\"\(submodule.url)\",\"managed\"")
                                }
                            } else {
                                print("    \(aSpec.name)")
                                if let submodule = modules.spec(named: aSpec.name) {
                                    catalog.add(name: aSpec.name, url: submodule.url)
                                    if verbose == true {
                                        print("      path: \(submodule.path)")
                                        print("      url: \(submodule.url)")
                                    }
                                }
                            }
                        }
                    } else if unmanaged == true {
                        FileManager.default.changeCurrentDirectoryPath(dirPath)
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
}

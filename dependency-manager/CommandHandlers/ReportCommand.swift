//
//  ReportCommand.swift
//  dependency-manager
//
//  Created by Simeon Leifer on 7/27/18.
//  Copyright © 2018 droolingcat.com. All rights reserved.
//

import Foundation
import CommandLineCore

class ReportCommand: Command {
    override func run(cmd: ParsedCommand) {
        var verbose = false
        if cmd.option("--verbose") != nil {
            verbose = true
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

        for searchDirPath in searchDirPaths {
            print("\nReport in \(searchDirPath):")

            let fm = FileManager.default
            let enumerator = fm.enumerator(atPath: searchDirPath)
            while let file = enumerator?.nextObject() as? String {
                if file.lastPathComponent == ".git" {
                    let dirPath = searchDirPath.appendingPathComponent(file).deletingLastPathComponent
                    let specPath = dirPath.appendingPathComponent(versionSpecsFileName)
                    if fm.fileExists(atPath: specPath) == true {
                        var modules: [SubmoduleInfo]?
                        if verbose == true {
                            FileManager.default.changeCurrentDirectoryPath(dirPath)
                            modules = scm.submodules()
                        }
                        let name = file.deletingLastPathComponent.lastPathComponent
                        let spec = VersionSpecification(fromFile: specPath)
                        print("  Project: \(name)")
                        print("  \(dirPath)")
                        for aSpec in spec.allSpecs() {
                            print("    \(aSpec.name)")
                            if let submodule = modules?.spec(named: aSpec.name) {
                                print("      path: \(submodule.path)")
                                print("      url: \(submodule.url)")
                            }
                        }
                    } else if unmanaged == true {
                        FileManager.default.changeCurrentDirectoryPath(dirPath)
                        let modules: [SubmoduleInfo] = scm.submodules()
                        if modules.count > 0 {
                            let name = dirPath.lastPathComponent
                            print("  Project: \(name) (unmanaged)")
                            print("  \(dirPath)")
                            for module in modules {
                                print("    \(module.name)")
                                if verbose == true {
                                    print("      path: \(module.path)")
                                    print("      url: \(module.url)")
                                }
                            }
                        }
                    }
                }
            }

            print("Done.")
        }

        FileManager.default.changeCurrentDirectoryPath(baseDirectory)
    }
}

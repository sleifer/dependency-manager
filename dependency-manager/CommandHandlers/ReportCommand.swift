//
//  ReportCommand.swift
//  dependency-manager
//
//  Created by Simeon Leifer on 7/27/18.
//  Copyright © 2018 droolingcat.com. All rights reserved.
//

import Foundation

class ReportCommand: Command {
    override func run(cmd: ParsedCommand) {
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
                        let name = file.deletingLastPathComponent.lastPathComponent
                        let spec = VersionSpecification(fromFile: specPath)
                        print("  Project: \(name)")
                        for aSpec in spec.allSpecs() {
                            print("    \(aSpec.name)")
                        }
                    }
                }
            }

            print("Done.")
        }
    }
}

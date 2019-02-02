//
//  main.swift
//  dependency-manager
//
//  Created by Simeon Leifer on 9/14/17.
//  Copyright © 2017 droolingcat.com. All rights reserved.
//

import Foundation
import CommandLineCore

let toolVersion = "0.34"
let versionSpecsFileName = ".module-versions"
let scm: SCM = Git()
var versionSpecs = VersionSpecification()

func main() {
    #if DEBUG
    // for testing in Xcode
    let path = "~/Documents/Code/".expandingTildeInPath
    FileManager.default.changeCurrentDirectoryPath(path)
    #endif

    let core = CommandCore()
    core.set(version: toolVersion)
    core.set(help: "A tool to keep submodule dependencies up to date.")

    core.add(command: AddCommand.self)
    core.add(command: CatalogCommand.self)
    core.add(command: InitCommand.self)
    core.add(command: OutdatedCommand.self)
    core.add(command: ReportCommand.self)
    core.add(command: SpecCommand.self)
    core.add(command: UpdateCommand.self)

    #if DEBUG
    // for testing in Xcode
    let args = ["dm", "report", "-k"]
    #else
    let args = CommandLine.arguments
    #endif

    if scm.isInstalled == true && scm.isInitialized == true {
        versionSpecs = VersionSpecification(fromFile: core.baseSubPath(versionSpecsFileName))
    }

    core.process(args: args)
}

main()

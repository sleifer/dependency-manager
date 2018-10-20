//
//  main.swift
//  dependency-manager
//
//  Created by Simeon Leifer on 9/14/17.
//  Copyright © 2017 droolingcat.com. All rights reserved.
//

import Foundation
import CommandLineCore

let toolVersion = "0.20"
let versionSpecsFileName = ".module-versions"
let scm: SCM = Git()
var versionSpecs = VersionSpecification()
let core = CommandCore()

func main() {
    #if DEBUG
    // for testing in Xcode
    let path = "~/Documents/Code/homoidentus".expandingTildeInPath
    FileManager.default.changeCurrentDirectoryPath(path)
    #endif

    core.set(version: toolVersion)
    core.set(help: "A tool to keep submodule dependencies up to date.")

    core.add(command: InitCommand.self)
    core.add(command: SpecCommand.self)
    core.add(command: OutdatedCommand.self)
    core.add(command: UpdateCommand.self)
    core.add(command: ReportCommand.self)

    #if DEBUG
    // for testing in Xcode
    let args = ["dm", "bashcomp", "update", ""]
    #else
    let args = CommandLine.arguments
    #endif

    versionSpecs = VersionSpecification(fromFile: core.baseSubPath(versionSpecsFileName))

    core.process(args: args)
}

main()

//
//  RemoveCommand.swift
//  dependency-manager
//
//  Created by Simeon Leifer on 1/11/20.
//  Copyright © 2018 droolingcat.com. All rights reserved.
//

import Foundation
import CommandLineCore

class RemoveCommand: Command {
    required init() {
    }

    fileprivate func removeSubmodule(core: CommandCore, specName: String) {
        let modules = scm.submodules()

        let matchedModule = modules.filter { (info) -> Bool in
            if info.name == specName {
                return true
            }
            return false
        }.first

        if let match = matchedModule {
            let modulePath = "submodules".appendingPathComponent(match.name)
            ProcessRunner.runCommand("git submodule deinit \"\(modulePath)\"", echoOutput: true)
            ProcessRunner.runCommand("git rm \"\(modulePath)\"", echoOutput: true)
            // ProcessRunner.runCommand("git commit -m \"Remove submodule: \(modulePath)\"", echoOutput: true)
            ProcessRunner.runCommand("rm -rf \".git/modules/\(modulePath)\"", echoOutput: true)

            versionSpecs.setSpec(name: match.name, spec: nil)
            versionSpecs.write(toFile: core.baseSubPath(versionSpecsFileName))

        } else {
            print("Can't find module: \(specName)")
        }
    }

    func run(cmd: ParsedCommand, core: CommandCore) {
        if cmd.parameters.count == 0 {
            print("No submodule names specified to remove.")
            return
        }
        for param in cmd.parameters {
            removeSubmodule(core: core, specName: param)
        }
    }

    static func commandDefinition() -> SubcommandDefinition {
        var command = SubcommandDefinition()
        command.name = "remove"
        command.synopsis = "Remove submodule(s) from repository and spec."

        var parameter = ParameterInfo()
        parameter.hint = "module-name"
        parameter.help = "Name of module to remove"

        parameter.completions = versionSpecs.allSpecs().map { (spec) -> String in
            return spec.name
        }.sorted { (left, right) -> Bool in
            if left.lowercased() < right.lowercased() {
                return true
            }
            return false
        }

        command.requiredParameters.append(parameter)

        return command
    }
}

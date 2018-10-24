//
//  SpecCommand.swift
//  dependency-manager
//
//  Created by Simeon Leifer on 10/11/17.
//  Copyright © 2017 droolingcat.com. All rights reserved.
//

import Foundation
import CommandLineCore

class SpecCommand: Command {
    required init() {
    }

    func run(cmd: ParsedCommand, core: CommandCore) {
        if cmd.parameters.count == 0 {
            for spec in versionSpecs.allSpecs() {
                print(spec.toStr())
            }
        } else if cmd.parameters.count == 3 {
            if let spec = VersionSpec.parse(name: cmd.parameters[0], comparison: cmd.parameters[1], version: cmd.parameters[2]) {
                versionSpecs.setSpec(name: spec.name, spec: spec)
                versionSpecs.write(toFile: core.baseSubPath(versionSpecsFileName))
                print("Set: \(spec.toStr())")
            } else {
                print("Invalid spec.")
            }
        } else {
            print("Wrong number of parameters.")
            print("  Zero to list.")
            print("  Three (name, comparison, version spec) to set.")
        }
    }

    static func commandDefinition() -> SubcommandDefinition {
        var command = SubcommandDefinition()
        command.name = "spec"
        command.synopsis = "List or update version range for one or all submodules"

        var moduleParameter = ParameterInfo()
        moduleParameter.hint = "module-name"
        moduleParameter.help = "Name of module set/update spec for"
        if scm.isInstalled == true && scm.isInitialized == true {
            let submodules = scm.submodules()
            moduleParameter.completions = submodules.map { (info) -> String in
                return info.name
            }
        }
        command.optionalParameters.append(moduleParameter)

        var testParameter = ParameterInfo()
        testParameter.hint = "test"
        testParameter.help = "Version comparison mode: ==/eq, >=/ge, or ~>/co"
        testParameter.completions = ["eq", "ge", "co"]
        command.optionalParameters.append(testParameter)

        var versionParameter = ParameterInfo()
        versionParameter.hint = "version"
        versionParameter.help = "Version to compare against"
        command.optionalParameters.append(versionParameter)

        return command
    }
}

//
//  InitCommand.swift
//  dependency-manager
//
//  Created by Simeon Leifer on 10/11/17.
//  Copyright © 2017 droolingcat.com. All rights reserved.
//

import Foundation
import CommandLineCore

class InitCommand: Command {
    required init() {
    }

    func run(cmd: ParsedCommand, core: CommandCore) {
        var force = false
        if cmd.option("--force") != nil {
            force = true
        }
        if versionSpecs.missing == false && force == false {
            print(".module-versions already exists, use --force to replace.")
        } else {
            versionSpecs = VersionSpecification()
            let submodules = scm.submodules()
            for submodule in submodules {
                var semver: SemVer?
                let parser = SemVerParser(submodule.version)
                do {
                    semver = try parser.parse()
                } catch {
                }
                let spec = VersionSpec(name: submodule.name, comparison: .equal, version: submodule.version, semver: semver)
                versionSpecs.setSpec(name: spec.name, spec: spec)
            }
            versionSpecs.write(toFile: core.baseSubPath(versionSpecsFileName))
            print("Created/replaced .module-versions.")
        }
    }

    static func commandDefinition() -> SubcommandDefinition {
        var command = SubcommandDefinition()
        command.name = "init"
        command.synopsis = "Create .module-versions file"

        var forceOption = CommandOption()
        forceOption.shortOption = "-f"
        forceOption.longOption = "--force"
        forceOption.help = "Recreate existing .module-versions"
        command.options.append(forceOption)

        return command
    }
}

//
//  InitCommand.swift
//  dependency-manager
//
//  Created by Simeon Leifer on 10/11/17.
//  Copyright © 2017 droolingcat.com. All rights reserved.
//

import Foundation

class InitCommand: Command {
    override func run(cmd: ParsedCommand) {
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
            versionSpecs.write(toFile: baseSubPath(versionSpecsFileName))
            print("Created/replaced .module-versions.")
        }
    }
}

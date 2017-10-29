//
//  SpecCommand.swift
//  dependency-manager
//
//  Created by Simeon Leifer on 10/11/17.
//  Copyright © 2017 droolingcat.com. All rights reserved.
//

import Foundation

class SpecCommand: Command {
    override func run(cmd: ParsedCommand) {
        if cmd.parameters.count == 0 {
            for spec in versionSpecs.allSpecs() {
                print(spec.toStr())
            }
        } else if cmd.parameters.count == 3 {
            if let spec = VersionSpec.parse(name: cmd.parameters[0], comparison: cmd.parameters[1], version: cmd.parameters[2]) {
                versionSpecs.setSpec(name: spec.name, spec: spec)
                versionSpecs.write(toFile: baseSubPath(versionSpecsFileName))
                print("Set: \(spec.toStr())")
            } else {
                print("Invalid spec.")
            }
        } else {
            print("Wrong number of parameters.")
            print("  Zero to list.")
            print("  Two (name, version spec) to set.")
        }
    }
}

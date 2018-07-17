//
//  CommandDefinition.swift
//  dependency-manager
//
//  Created by Simeon Leifer on 10/10/17.
//  Copyright © 2017 droolingcat.com. All rights reserved.
//

import Foundation

func makeCommandDefinition() -> CommandDefinition {
    var definition = CommandDefinition()
    definition.help = "Tool to keep submodule dependencies up to date"

    var version = CommandOption()
    version.longOption = "--version"
    version.help = "Show tool version information"
    definition.options.append(version)

    var help = CommandOption()
    help.shortOption = "-h"
    help.longOption = "--help"
    help.help = "Show this help"
    definition.options.append(help)

    // spec command
    var specCommand = SubcommandDefinition()
    specCommand.name = "spec"
    specCommand.synopsis = "List or update version range for one or all submodules"
    specCommand.help = ""

    definition.subcommands.append(specCommand)

    // update command
    var updateCommand = SubcommandDefinition()
    updateCommand.name = "update"
    updateCommand.synopsis = "Update one or all submodules to latest valid version"
    updateCommand.help = ""

    var updateCommand_parameter = ParameterInfo()
    updateCommand_parameter.hint = "module-name"
    updateCommand_parameter.help = "Name of module to update"
    updateCommand.optionalParameters.append(updateCommand_parameter)

    definition.subcommands.append(updateCommand)

    // outdated command
    var outdatedCommand = SubcommandDefinition()
    outdatedCommand.name = "outdated"
    outdatedCommand.synopsis = "Check all submodules for newer valid version"
    outdatedCommand.help = ""

    definition.subcommands.append(outdatedCommand)

    // init command
    var initCommand = SubcommandDefinition()
    initCommand.name = "init"
    initCommand.synopsis = "Create .module-versions file"
    initCommand.help = ""

    var initCommand_force = CommandOption()
    initCommand_force.shortOption = "-f"
    initCommand_force.longOption = "--force"
    initCommand_force.help = "Recreate existing .module-versions"
    initCommand.options.append(initCommand_force)

    definition.subcommands.append(initCommand)

    // bashcomp
    var bashcompCommand = SubcommandDefinition()
    bashcompCommand.name = "bashcomp"
    bashcompCommand.hidden = true
    bashcompCommand.suppressesOptions = true
    bashcompCommand.warnOnMissingSpec = false

    definition.subcommands.append(bashcompCommand)

    // bashcompfile
    var bashcompfileCommand = SubcommandDefinition()
    bashcompfileCommand.name = "bashcompfile"
    bashcompfileCommand.hidden = true
    bashcompfileCommand.warnOnMissingSpec = false

    definition.subcommands.append(bashcompfileCommand)

    return definition
}

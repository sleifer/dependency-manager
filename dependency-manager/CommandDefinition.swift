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

    var specCommand_help = CommandOption()
    specCommand_help.shortOption = "-h"
    specCommand_help.longOption = "--help"
    specCommand_help.help = "Show this help"
    specCommand.options.append(specCommand_help)

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

    var updateCommand_help = CommandOption()
    updateCommand_help.shortOption = "-h"
    updateCommand_help.longOption = "--help"
    updateCommand_help.help = "Show this help"
    updateCommand.options.append(updateCommand_help)

    definition.subcommands.append(updateCommand)

    // outdated command
    var outdatedCommand = SubcommandDefinition()
    outdatedCommand.name = "outdated"
    outdatedCommand.synopsis = "Check all submodules for newer valid version"
    outdatedCommand.help = ""

    var outdatedCommand_help = CommandOption()
    outdatedCommand_help.shortOption = "-h"
    outdatedCommand_help.longOption = "--help"
    outdatedCommand_help.help = "Show this help"
    outdatedCommand.options.append(outdatedCommand_help)

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

    var initCommand_help = CommandOption()
    initCommand_help.shortOption = "-h"
    initCommand_help.longOption = "--help"
    initCommand_help.help = "Show this help"
    initCommand.options.append(initCommand_help)

    definition.subcommands.append(initCommand)

    return definition
}

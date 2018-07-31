//
//  CommandDefinition.swift
//  dependency-manager
//
//  Created by Simeon Leifer on 10/10/17.
//  Copyright © 2017 droolingcat.com. All rights reserved.
//

import Foundation
import CommandLineCore

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

    definition.subcommands.append(initCommand())
    definition.subcommands.append(specCommand())
    definition.subcommands.append(outdatedCommand())
    definition.subcommands.append(updateCommand())
    definition.subcommands.append(reportCommand())

    return definition
}

fileprivate func specCommand() -> SubcommandDefinition {
    var command = SubcommandDefinition()
    command.name = "spec"
    command.synopsis = "List or update version range for one or all submodules"

    return command
}

fileprivate func updateCommand() -> SubcommandDefinition {
    var command = SubcommandDefinition()
    command.name = "update"
    command.synopsis = "Update one or all submodules to latest valid version"

    var parameter = ParameterInfo()
    parameter.hint = "module-name"
    parameter.help = "Name of module to update"
    command.optionalParameters.append(parameter)

    return command
}

fileprivate func outdatedCommand() -> SubcommandDefinition {
    var command = SubcommandDefinition()
    command.name = "outdated"
    command.synopsis = "Check all submodules for newer valid version"

    return command
}

fileprivate func initCommand() -> SubcommandDefinition {
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

fileprivate func reportCommand() -> SubcommandDefinition {
    var command = SubcommandDefinition()
    command.name = "report"
    command.synopsis = "Report on modules used in one or more repositories"
    command.hasFileParameters = true
    command.warnOnMissingSpec = false

    var parameter = ParameterInfo()
    parameter.hint = "path"
    parameter.help = "Path to repository or directory or repositories"
    command.optionalParameters.append(parameter)

    return command
}

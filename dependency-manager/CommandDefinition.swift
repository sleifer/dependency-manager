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

    var spec = SubcommandDefinition()
    spec.name = "spec"
    spec.synopsis = "List or update version range for one or all submodules"
    spec.help = ""

    var spec_help = CommandOption()
    spec_help.shortOption = "-h"
    spec_help.longOption = "--help"
    spec_help.help = "Show this help"
    spec.options.append(spec_help)

    definition.subcommands.append(spec)

    var update = SubcommandDefinition()
    update.name = "update"
    update.synopsis = "Update one or all submodules to latest valid version"
    update.help = ""

    var update_parameter = ParameterInfo()
    update_parameter.hint = "module-name"
    update_parameter.help = "Name of module to update"
    update.optionalParameters.append(update_parameter)

    var update_help = CommandOption()
    update_help.shortOption = "-h"
    update_help.longOption = "--help"
    update_help.help = "Show this help"
    update.options.append(update_help)

    definition.subcommands.append(update)

    var outdated = SubcommandDefinition()
    outdated.name = "outdated"
    outdated.synopsis = "Check all submodules for newer valid version"
    outdated.help = ""

    var outdated_help = CommandOption()
    outdated_help.shortOption = "-h"
    outdated_help.longOption = "--help"
    outdated_help.help = "Show this help"
    outdated.options.append(outdated_help)

    definition.subcommands.append(outdated)

    return definition
}

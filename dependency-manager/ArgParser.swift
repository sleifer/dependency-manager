//
//  ArgParser.swift
//  dependency-manager
//
//  Created by Simeon Leifer on 10/10/17.
//  Copyright © 2017 droolingcat.com. All rights reserved.
//

import Foundation

struct CommandOption {
    var shortOption: String?
    var longOption: String
    var argumentCount: Int
    var help: String

    init() {
        longOption = ""
        argumentCount = 0
        help = ""
    }
}

struct ParsedOption {
    var longOption: String
    var arguments: [String]

    init() {
        longOption = ""
        arguments = []
    }
}

struct ParameterInfo {
    var hint: String
    var help: String

    init() {
        hint = ""
        help = ""
    }
}

struct CommandDefinition {
    var options: [CommandOption]
    var requiredParameters: [ParameterInfo]
    var optionalParameters: [ParameterInfo]
    var help: String
    var subcommands: [SubcommandDefinition]

    init() {
        options = []
        requiredParameters = []
        optionalParameters = []
        help = ""
        subcommands = []
    }
}

struct SubcommandDefinition {
    var options: [CommandOption]
    var requiredParameters: [ParameterInfo]
    var optionalParameters: [ParameterInfo]
    var name: String
    var synopsis: String
    var help: String

    init() {
        options = []
        requiredParameters = []
        optionalParameters = []
        name = ""
        synopsis = ""
        help = ""
    }
}

struct ParsedCommand {
    var globalOptions: [ParsedOption]
    var subcommand: String?
    var options: [ParsedOption]
    var parameters: [String]

    init() {
        globalOptions = []
        options = []
        parameters = []
    }
}

class ArgParser {

    let definition: CommandDefinition

    var args: [String] = []
    var parsed: ParsedCommand = ParsedCommand()

    init(definition inDefinition: CommandDefinition) {
        definition = inDefinition
    }

    func parse(_ inArgs: [String]) -> ParsedCommand {
        args = inArgs

        if args.count == 1 {
            printHelp()
        }

        var availableOptions = optionMap(definition.options)
        let availableSubcommands = subcommandMap(definition.subcommands)
        var subcommand: SubcommandDefinition?

        let sargs = args.dropFirst()
        for arg in sargs {
            if let value = availableOptions[arg] {
                var option = ParsedOption()
                option.longOption = value.longOption
                // TODO: (SKL) need to handle options with args
                parsed.options.append(option)
            } else if let value = availableSubcommands[arg], subcommand == nil {
                parsed.subcommand = value.name
                subcommand = value
                availableOptions = optionMap(value.options)
            } else {
                parsed.parameters.append(arg)
            }
        }

        return parsed
    }

    func optionMap(_ optionArray: [CommandOption]) -> [String: CommandOption] {
        var map: [String: CommandOption] = [:]

        for option in optionArray {
            if let short = option.shortOption {
                map[short] = option
            }
            map[option.longOption] = option
        }

        return map
    }

    func subcommandMap(_ subcommandArray: [SubcommandDefinition]) -> [String: SubcommandDefinition] {
        var map: [String: SubcommandDefinition] = [:]

        for option in subcommandArray {
            map[option.name] = option
        }

        return map
    }

    func printHelp() {
        let toolname = args[0].lastPathComponent
        print("Usage: \(toolname) [OPTIONS] COMMAND [ARGS]...")
        print()
        print("\(definition.help)")
        if definition.options.count > 0 {
            print()
            print("Options:")
            var optionStrings: [[String]] = []
            for option in definition.options {
                var argCount = ""
                if option.argumentCount > 0 {
                    argCount = "<\(option.argumentCount) args>"
                }
                if let shortOption = option.shortOption {
                    optionStrings.append(["\(shortOption), \(option.longOption)", argCount, option.help])
                } else {
                    optionStrings.append(["\(option.longOption)", argCount, option.help])
                }
            }
            var maxOptionLength = 0
            var maxArgCountLength = 0
            for optionInfo in optionStrings {
                let len1 = optionInfo[0].count
                if len1 > maxOptionLength {
                    maxOptionLength = len1
                }
                let len2 = optionInfo[1].count
                if len2 > maxArgCountLength {
                    maxArgCountLength = len2
                }
            }
            let pad = String(repeating: " ", count: max(maxOptionLength, maxArgCountLength))
            for optionInfo in optionStrings {
                print("\(optionInfo[0].padding(toLength: maxOptionLength, withPad: pad, startingAt: 0)) \(optionInfo[1].padding(toLength: maxArgCountLength, withPad: pad, startingAt: 0)) \(optionInfo[2])")
            }
        }
        if definition.subcommands.count > 0 {
            print()
            print("Commands:")
            var maxNameLength = 0
            for sub in definition.subcommands {
                let len1 = sub.name.count
                if len1 > maxNameLength {
                    maxNameLength = len1
                }
            }
            let pad = String(repeating: " ", count: maxNameLength)
            for sub in definition.subcommands {
                print("\(sub.name.padding(toLength: maxNameLength, withPad: pad, startingAt: 0))    \(sub.synopsis)")
            }
        }
    }
}

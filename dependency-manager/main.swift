//
//  main.swift
//  dependency-manager
//
//  Created by Simeon Leifer on 9/14/17.
//  Copyright © 2017 droolingcat.com. All rights reserved.
//

import Foundation

let toolVersion = "0.9.7"
let versionSpecsFileName = ".module-versions"
let runLoop = RunLoop.current
var backgroundCount: Int = 0
let scm: SCM = Git()
var baseDirectory: String = ""
var versionSpecs = VersionSpecification()
var commandName: String = ""

func main() {
    autoreleasepool {
        let parser = ArgParser(definition: makeCommandDefinition())

        do {
            #if DEBUG
                let args = ["dm", "init", "--help"]
                commandName = args[0]
                let parsed = try parser.parse(args)
            #else
                let parsed = try parser.parse(CommandLine.arguments)
                commandName = CommandLine.arguments[0].lastPathComponent
            #endif

            #if DEBUG
                // for testing in Xcode
                let path = "~/Documents/Code/homoidentus".expandingTildeInPath
                FileManager.default.changeCurrentDirectoryPath(path)
            #endif

            baseDirectory = FileManager.default.currentDirectoryPath

            var skipSubcommand = false
            var warnOnMissingSpec = true
            var cmd: Command?

            if parser.helpPrinted == true || parsed.warnOnMissingSpec == false {
                warnOnMissingSpec = false
            }

            if parsed.option("--version", type: .either) != nil {
                print("Version \(toolVersion)")
                skipSubcommand = true
                warnOnMissingSpec = false
            }
            if parsed.option("--help", type: .either) != nil {
                parser.printHelp()
                skipSubcommand = true
                warnOnMissingSpec = false
            }

            if scm.isInstalled == false && warnOnMissingSpec == true {
                print("Can't locate git tool.")
                return
            }
            if scm.isInitialized == false && warnOnMissingSpec == true {
                print("git is not initialized in this directory.")
                return
            }

            versionSpecs = VersionSpecification(fromFile: baseSubPath(versionSpecsFileName))

            if skipSubcommand == false {
                switch parsed.subcommand ?? "root" {
                case "bashcomp":
                    cmd = BashcompCommand(parser: parser)
                case "bashcompfile":
                    cmd = BashcompfileCommand()
                case "outdated":
                    cmd = OutdatedCommand()
                case "spec":
                    cmd = SpecCommand()
                case "update":
                    cmd = UpdateCommand()
                    break
                case "init":
                    cmd = InitCommand()
                    warnOnMissingSpec = false
                    break
                case "root":
                    if parsed.parameters.count > 0 {
                        print("Unknown command: \(parsed.parameters[0])")
                        warnOnMissingSpec = false
                    }
                    break
                default:
                    print("Unknown command.")
                    warnOnMissingSpec = false
                }
            }

            if warnOnMissingSpec == true && versionSpecs.missing == true {
                print("\(versionSpecsFileName) missing, use '\(commandName) init' to create it.")
            } else if let cmd = cmd {
                cmd.run(cmd: parsed)
            }
        } catch {
            print("Invalid arguments.")
            parser.printHelp()
        }

        while (backgroundCount > 0 && (spinRunLoop())) {
            // do nothing
        }
    }
}

func baseSubPath(_ subpath: String) -> String {
    var path = subpath.standardizingPath
    if path.isAbsolutePath == false {
        path = baseDirectory.appendingPathComponent(path)
    }
    return path
}

func setCurrentDir(_ subpath: String) {
    FileManager.default.changeCurrentDirectoryPath(baseSubPath(subpath))
}

func resetCurrentDir() {
    setCurrentDir(baseDirectory)
}

@discardableResult
func spinRunLoop() -> Bool {
    return runLoop.run(mode: .defaultRunLoopMode, before: Date(timeIntervalSinceNow: 2))
}

func startBackgroundTask() {
    backgroundCount = backgroundCount + 1
}

func endBackgroundTask() {
    backgroundCount = backgroundCount - 1
}

main()

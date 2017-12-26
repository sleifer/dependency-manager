//
//  main.swift
//  dependency-manager
//
//  Created by Simeon Leifer on 9/14/17.
//  Copyright © 2017 droolingcat.com. All rights reserved.
//

import Foundation

let toolVersion = "0.9.1"
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
                let args = ["dm", "spec", "CwlSignal", "~>", "2.0-beta-35"]
                commandName = args[0]
                let parsed = try parser.parse(args)
            #else
                let parsed = try parser.parse(CommandLine.arguments)
                commandName = CommandLine.arguments[0].lastPathComponent
            #endif

            #if DEBUG
                // for testing in Xcode
                let path = "~/NotBackedUp/homoidentus-dm-test".expandingTildeInPath
                FileManager.default.changeCurrentDirectoryPath(path)
            #endif

            baseDirectory = FileManager.default.currentDirectoryPath

            if scm.isInstalled == false {
                print("Can't locate git tool.")
                return
            }
            if scm.isInitialized == false {
                print("git is not initialized in this directory.")
                return
            }

            var skipSubcommand = false

            if parsed.option("--version", type: .global) != nil {
                print("Version \(toolVersion)")
                skipSubcommand = true
            }
            if parsed.option("--help", type: .global) != nil {
                parser.printHelp()
                skipSubcommand = true
            }

            versionSpecs = VersionSpecification(fromFile: baseSubPath(versionSpecsFileName))

            if skipSubcommand == false {
                switch parsed.subcommand ?? "root" {
                case "outdated":
                    let cmd = OutdatedCommand()
                    cmd.run(cmd: parsed)
                case "spec":
                    let cmd = SpecCommand()
                    cmd.run(cmd: parsed)
                case "update":
                    let cmd = UpdateCommand()
                    cmd.run(cmd: parsed)
                    break
                case "root":
                    if parsed.parameters.count > 0 {
                        print("Unknown command: \(parsed.parameters[0])")
                    }
                    break
                default:
                    print("Unknown command.")
                }
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

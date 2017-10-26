//
//  main.swift
//  dependency-manager
//
//  Created by Simeon Leifer on 9/14/17.
//  Copyright © 2017 droolingcat.com. All rights reserved.
//

import Foundation

let versionSpecsFileName = ".module-versions"
let runLoop = RunLoop.current
var backgroundCount: Int = 0
let scm: SCM = Git()
var baseDirectory: String = ""
var versionSpecs = VersionSpecification()

func main() {
    autoreleasepool {
        let parser = ArgParser(definition: makeCommandDefinition())

        #if DEBUG
            let args = ["dm", "update"]
            let parsed = parser.parse(args)
        #else
            let parsed = parser.parse(CommandLine.arguments)
        #endif

        #if DEBUG
            // for testing in Xcode
            FileManager.default.changeCurrentDirectoryPath("/Users/simeon/NotBackedUp/homoidentus-dm-test")
        #endif

        baseDirectory = FileManager.default.currentDirectoryPath
        versionSpecs = VersionSpecification(fromFile: baseSubPath(versionSpecsFileName))

        if scm.isInstalled == false {
            print("Can't locate git tool.")
            return
        }
        if scm.isInitialized == false {
            print("git is not initialized in this directory.")
            return
        }

        switch parsed.subcommand ?? "root" {
        case "outdated":
            let cmd = OutdatedCommand()
            cmd.run()
        case "spec":
            let cmd = SpecCommand()
            cmd.run()
        case "update":
            let cmd = UpdateCommand()
            cmd.run()
            break
        case "root":
            break
        default:
            print("Unknown command.")
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

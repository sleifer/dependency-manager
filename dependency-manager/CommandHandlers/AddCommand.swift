//
//  AddCommand.swift
//  dependency-manager
//
//  Created by Simeon Leifer on 10/21/18.
//  Copyright © 2018 droolingcat.com. All rights reserved.
//

import CommandLineCore
import Foundation

class AddCommand: Command {
    required init() {}

    fileprivate func addSubmodule(core: CommandCore, entry: CatalogEntry, compatibleMode: Bool) {
        do {
            // make directory
            var isDir: ObjCBool = ObjCBool(false)
            let submodulesPath = core.baseSubPath("submodules")
            let exists = FileManager.default.fileExists(atPath: submodulesPath, isDirectory: &isDir)
            if exists == true, isDir.boolValue == false {
                print("submodules already exists and is not a directory.")
                return
            } else if exists == false {
                try FileManager.default.createDirectory(atPath: submodulesPath, withIntermediateDirectories: true, attributes: nil)
            }

            // add submodule
            let submodulePath = "submodules/\(entry.name)"
            ProcessRunner.runCommand(["git", "submodule", "add", entry.url, submodulePath], echoOutput: true)

            core.setCurrentDir(submodulePath)
            ProcessRunner.runCommand(["git", "submodule", "update", "--init", "--recursive"], echoOutput: true)
            core.resetCurrentDir()

            // set to newest version
            let tags = scm.tags(submodulePath)
            if let newest = tags.last {
                scm.checkout(submodulePath, object: newest.fullString)

                // add to spec
                let comparison = compatibleMode == true ? "~>" : "=="
                var version: String?
                if compatibleMode == true {
                    if let replacement = newest.copyDroppingLastVersionElement() {
                        version = replacement.fullString
                    } else {
                        print("Can't calculate compatible mode version string.")
                    }
                } else {
                    version = newest.fullString
                }
                if let version = version {
                    if let spec = VersionSpec.parse(name: entry.name, comparison: comparison, version: version) {
                        versionSpecs.setSpec(name: spec.name, spec: spec)
                        versionSpecs.write(toFile: core.baseSubPath(versionSpecsFileName))
                        print("Set spec: \(spec.toStr())")
                    } else {
                        print("Invalid spec.")
                    }
                }
            } else {
                print("Can't determine newest version to add to spec.")
            }
        } catch {
            print("Error: \(error)")
        }
    }

    func run(cmd: ParsedCommand, core: CommandCore) {
        var compatibleMode: Bool = false
        if cmd.option("--compatible") != nil {
            compatibleMode = true
        }

        let catalog = Catalog.load()
        if cmd.parameters.count == 0 {
            print("No submodule names specified to add.")
            return
        }
        for param in cmd.parameters {
            let entry = catalog.entries.filter { (entry) -> Bool in
                entry.name.lowercased() == param.lowercased()
            }.first
            if let opt = cmd.option("--url"), opt.arguments.count == 1, cmd.parameters.count == 1 {
                let url = opt.arguments[0]
                if catalog.add(name: param, url: url) == true {
                    let newEntry = CatalogEntry(name: param, url: url)
                    addSubmodule(core: core, entry: newEntry, compatibleMode: compatibleMode)
                    catalog.save()
                } else {
                    print("Issue adding definition for \(param) to catalog.")
                }
            } else if let entry = entry {
                addSubmodule(core: core, entry: entry, compatibleMode: compatibleMode)
            } else {
                print("Missing definition for \(param) in catalog.")
            }
        }
    }

    static func commandDefinition() -> SubcommandDefinition {
        var command = SubcommandDefinition()
        command.name = "add"
        command.synopsis = "Add submodule(s) from catalog to current repository and spec."

        var compatibleOption = CommandOption()
        compatibleOption.shortOption = "-c"
        compatibleOption.longOption = "--compatible"
        compatibleOption.help = "Add module to spec in compatible mode (vs equal)"
        command.options.append(compatibleOption)

        var urlOption = CommandOption()
        urlOption.shortOption = "-u"
        urlOption.longOption = "--url"
        urlOption.help = "Url for module, for when it isn't in the catalog"
        urlOption.argumentCount = 1
        command.options.append(urlOption)

        var parameter = ParameterInfo()
        parameter.hint = "module-name"
        parameter.help = "Name of module to add"

        let catalog = Catalog.load()
        parameter.completions = catalog.entries.map { (entry) -> String in
            entry.name
        }.sorted { (left, right) -> Bool in
            if left.lowercased() < right.lowercased() {
                return true
            }
            return false
        }

        command.requiredParameters.append(parameter)

        return command
    }
}

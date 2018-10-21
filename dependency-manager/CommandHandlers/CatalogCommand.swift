//
//  CatalogCommand.swift
//  dependency-manager
//
//  Created by Simeon Leifer on 10/21/18.
//  Copyright © 2018 droolingcat.com. All rights reserved.
//

import Foundation
import CommandLineCore

class CatalogCommand: Command {
    required init() {
    }

    func run(cmd: ParsedCommand, core: CommandCore) {
        let catalog = Catalog.load()
        if catalog.entries.count == 0 {
            print("No submodules in catalog.")
            return
        }
        let sortedEntries = catalog.entries.sorted { (left, right) -> Bool in
            if left.name.lowercased() < right.name.lowercased() {
                return true
            }
            return false
        }
        print("\(sortedEntries.count) submodule(s) in catalog:")
        let items = sortedEntries.equalLengthPad(padding: { (entry) -> String in
            return entry.name
        }, compose: { (text, entry) -> String in
            return "\(text) - \(entry.url)"
        })
        for item in items {
            print(item)
        }
    }

    static func commandDefinition() -> SubcommandDefinition {
        var command = SubcommandDefinition()
        command.name = "catalog"
        command.synopsis = "List submodule info from catalog."

        return command
    }
}

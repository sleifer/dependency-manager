//
//  Catalog.swift
//  dependency-manager
//
//  Created by Simeon Leifer on 10/19/18.
//  Copyright © 2018 droolingcat.com. All rights reserved.
//

import Foundation

let catalogPath = "~/.dm-catalog.json".expandingTildeInPath

struct CatalogEntry: Codable, Equatable {
    var name: String
    var url: String

    public static func == (lhs: CatalogEntry, rhs: CatalogEntry) -> Bool {
        if lhs.name == rhs.name, lhs.url == rhs.url {
            return true
        }
        return false
    }
}

class Catalog: Codable, JSONReadWrite {
    typealias HostClass = Catalog
    var entries: [CatalogEntry] = []

    @discardableResult
    func add(name: String, url: String) -> Bool {
        let entry = CatalogEntry(name: name, url: url)
        if entries.contains(entry) == false {
            entries.append(entry)
            return true
        }
        return false
    }

    static func load() -> Catalog {
        if let catalog = read(contentsOf: URL(fileURLWithPath: catalogPath)) {
            return catalog
        }
        return Catalog()
    }

    func save() {
        entries.sort { (left, right) -> Bool in
            if left.name.lowercased() < right.name.lowercased() {
                return true
            }
            return false
        }
        write(to: URL(fileURLWithPath: catalogPath))
    }
}

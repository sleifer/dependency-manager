//
//  Catalog.swift
//  dependency-manager
//
//  Created by Simeon Leifer on 10/19/18.
//  Copyright © 2018 droolingcat.com. All rights reserved.
//

import Foundation
import ObjectMapper

let catalogPath = "~/.dm-catalog.json".expandingTildeInPath

struct CatalogEntry {
    var name: String
    var url: String
}

extension CatalogEntry: Equatable {
    public static func == (lhs: CatalogEntry, rhs: CatalogEntry) -> Bool {
        if lhs.name == rhs.name && lhs.url == rhs.url {
            return true
        }
        return false
    }
}

extension CatalogEntry: Mappable {
    init?(map: Map) {
        name = ""
        url = ""
    }

    mutating func mapping(map: Map) {
        name <- map["name"]
        url <- map["url"]
    }
}

class Catalog: Mappable {
    var entries: [CatalogEntry] = []

    init() {
    }

    required init?(map: Map) {
    }

    func mapping(map: Map) {
        entries <- map["entries"]
    }

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
        var newCatalog: Catalog?

        do {
            if FileManager.default.fileExists(atPath: catalogPath) == true {
                let catalogUrl = URL(fileURLWithPath: catalogPath)
                let json = try String(contentsOf: catalogUrl, encoding: .utf8)
                newCatalog = Catalog(JSONString: json)
            }
        } catch {
            print("Error loading catalog: \(error)")
        }

        if let newCatalog = newCatalog {
            return newCatalog
        }
        return Catalog()
    }

    func save() {
        do {
            entries.sort { (left, right) -> Bool in
                if left.name > right.name {
                    return true
                }
                return false
            }
            let json = self.toJSONString(prettyPrint: true)
            let catalogUrl = URL(fileURLWithPath: catalogPath)
            try json?.write(to: catalogUrl, atomically: true, encoding: .utf8)
        } catch {
            print("Error saving catalog: \(error)")
        }
    }
}

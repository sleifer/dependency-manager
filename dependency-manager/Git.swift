//
//  Git.swift
//  dependency-manager
//
//  Created by Simeon Leifer on 10/11/17.
//  Copyright © 2017 droolingcat.com. All rights reserved.
//

import Foundation
import CommandLineCore

enum SubmoduleParseRegex: Int {
    case whole = 0
    case sha
    case pathRoot
    case name
    case version
    case count

    static func pattern() -> String {
        return "[ +]([0-9a-f]+) ((?:[^ /]+/)*)?([^ /]+)+ \\((.*)\\)"
    }
}

extension ProcessRunner {
    func scmResult() -> SCMResult {
        if self.status == 0 {
            return SCMResult.success(text: self.stdOut)
        } else {
            return SCMResult.error(code: self.status, text: self.stdErr)
        }
    }
}

class Git: SCM {
    var verbose: Bool = false

    var isInstalled: Bool {
        get {
            let proc = ProcessRunner.runCommand("which", args: ["git"])
            if proc.status == 0 {
                return true
            } else {
                return false
            }
        }
    }

    var isInitialized: Bool {
        get {
            let fileManager = FileManager.default
            let result = fileManager.fileExists(atPath: ".git")
            return result
        }
    }

    fileprivate func fixupSubmodules(_ submodules: [SubmoduleInfo]) -> [SubmoduleInfo] {
        defer {
            CommandCore.core!.resetCurrentDir()
        }
        var fixed: [SubmoduleInfo] = []
        for module in submodules {
            var newModule = module
            CommandCore.core!.setCurrentDir(module.path)
            do {
                let proc = try runGit(["describe", "--tag", module.sha, "--exact-match"])
                if proc.status == 0 {
                    let newVersion = proc.stdOut.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    var semver: SemVer?
                    let parser = SemVerParser(newVersion)
                    do {
                        semver = try parser.parse()
                    } catch {
                    }
                    newModule = SubmoduleInfo(sha: module.sha, path: module.path, url: module.url, name: module.name, version: newVersion, semver: semver)
                }
            } catch {
            }
            fixed.append(newModule)
        }
        return fixed
    }

    func submodules() -> [SubmoduleInfo] {
        do {
            let proc = try runGit(["submodule"])
            if proc.status == 0 {
                var subs = parseSubmodule(proc.stdOut)
                subs = fixupSubmodules(subs)
                return subs
            } else {
                print(proc.stdErr)
            }
        } catch {
            print("\(error)")
        }
        return []
    }

    @discardableResult
    func fetch(_ path: String) -> SCMResult {
        CommandCore.core!.setCurrentDir(path)
        defer {
            CommandCore.core!.resetCurrentDir()
        }
        do {
            let proc = try runGit(["fetch", "--all", "--prune", "--recurse-submodules"])
            return proc.scmResult()
        } catch {
            return SCMResult.error(code: -1, text: error as! String)
        }
    }

    @discardableResult
    func checkout(_ path: String, object: String) -> SCMResult {
        CommandCore.core!.setCurrentDir(path)
        defer {
            CommandCore.core!.resetCurrentDir()
        }
        do {
            let proc = try runGit(["checkout", object])
            return proc.scmResult()
        } catch {
            return SCMResult.error(code: -1, text: error as! String)
        }
    }

    func tags(_ path: String) -> [SemVer] {
        CommandCore.core!.setCurrentDir(path)
        defer {
            CommandCore.core!.resetCurrentDir()
        }
        do {
            let proc = try runGit(["tag"])
            if proc.status == 0 {
                let tags = parseTags(proc.stdOut)
                return tags.sorted()
            } else {
                print(proc.stdErr)
            }
        } catch {
            print("\(error)")
        }
        return []
    }

    fileprivate func runGit(_ args: [String]) throws -> ProcessRunner {
        if isInstalled == true {
            return ProcessRunner.runCommand("git", args: args)
        }
        throw SCMError.scmCommandMissing
    }

    fileprivate func parseSubmodule(_ text: String) -> [SubmoduleInfo] {
        var modules: [SubmoduleInfo] = []
        let matches = text.regex(SubmoduleParseRegex.pattern())
        for match in matches {
            if match.count == SubmoduleParseRegex.count.rawValue {
                let sha = match[SubmoduleParseRegex.sha.rawValue]
                let path = match[SubmoduleParseRegex.pathRoot.rawValue] + match[SubmoduleParseRegex.name.rawValue]
                var url: String = ""
                var semver: SemVer?
                let parser = SemVerParser(match[SubmoduleParseRegex.version.rawValue])
                do {
                    semver = try parser.parse()
                } catch {
                }
                do {
                    let proc = try runGit(["config", "--file=.gitmodules", "submodule.\(path).url"])
                    if proc.status == 0 {
                        url = proc.stdOut.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    }
                } catch {
                }
                let oneModule = SubmoduleInfo(sha: sha, path: path, url: url, name: match[SubmoduleParseRegex.name.rawValue], version: match[SubmoduleParseRegex.version.rawValue], semver: semver)
                modules.append(oneModule)
            }
        }
        return modules.sorted()
    }

    fileprivate func parseTags(_ text: String) -> [SemVer] {
        var tags: [SemVer] = []
        let lines = text.split(separator: "\n")
        for line in lines {
            let text = String(line)
            let parser = SemVerParser(text)
            do {
                let semver = try parser.parse()
                tags.append(semver)
            } catch {
                if verbose == true {
                    print("Issue: unparsable tag: \(text)")
                }
            }
        }
        return tags
    }
}

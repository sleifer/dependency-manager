//
//  BashcompfileCommand.swift
//  dependency-manager
//
//  Created by Simeon Leifer on 10/11/17.
//  Copyright © 2017 droolingcat.com. All rights reserved.
//

import Foundation

class BashcompfileCommand: Command {
    let text = """
_dm()
{
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts="$(${COMP_WORDS[0]} bashcomp ${COMP_WORDS[@]:1:$COMP_CWORD})"

    COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
    return 0
}
complete -F _dm dm
"""

    override func run(cmd: ParsedCommand) {
        print(text)
    }
}

#!/bin/bash
# bash.d command completions

_bashd_module_complete() {
    local cur prev words cword
    _init_completion || return
    
    local commands="list enable disable search info reload status"
    local types="aliases plugins completions functions"
    
    case "${prev}" in
        bashd_module_enable|bashd_module_disable|bashd_module_info)
            if [[ ${cword} -eq 2 ]]; then
                COMPREPLY=($(compgen -W "${types}" -- "${cur}"))
            elif [[ ${cword} -eq 3 ]]; then
                local type="${words[2]}"
                local dir="${BASHD_REPO_ROOT}/${type}"
                if [[ "$type" == "functions" ]]; then
                    dir="${BASHD_REPO_ROOT}/bash_functions.d"
                fi
                if [[ -d "$dir" ]]; then
                    local modules
                    modules=$(find "$dir" -type f \( -name "*.sh" -o -name "*.bash" \) -exec basename {} \; 2>/dev/null | sed 's/\.\(sh\|bash\)$//' | sort -u)
                    COMPREPLY=($(compgen -W "${modules}" -- "${cur}"))
                fi
            fi
            return 0
            ;;
        bashd_module_list)
            COMPREPLY=($(compgen -W "${types} all" -- "${cur}"))
            return 0
            ;;
    esac
    
    COMPREPLY=($(compgen -W "${commands}" -- "${cur}"))
}

complete -F _bashd_module_complete bashd_module_enable
complete -F _bashd_module_complete bashd_module_disable
complete -F _bashd_module_complete bashd_module_list
complete -F _bashd_module_complete bashd_module_search
complete -F _bashd_module_complete bashd_module_info

# Alias completions
complete -F _bashd_module_complete bashd-enable
complete -F _bashd_module_complete bashd-disable
complete -F _bashd_module_complete bashd-list
complete -F _bashd_module_complete bashd-search
complete -F _bashd_module_complete bashd-info

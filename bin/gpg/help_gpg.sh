#!/bin/bash

main() {
    readarray arr < <(cat ~/dotfiles/bin/gpg_help.json | jq -c '.sections[] | .name as $secname | .subsection[] | .name as $subname | .items[] | [$secname, $subname, .command, .description]')

    local column_size="%-20s %40s\n"
    local section=""
    local saved=""
    local subsection=""
    local saved_subsection=""
    for i in "${arr[@]}";do
        y=$(sed 's/","/:/g' <<< "$i")
        #y=${3:y:3}
        IFS=':' read -r -a array <<< "$y"
        #echo "${array[0]}"
        #echo "${array[2]}"
        section="${array[0]}"
        subsection="${array[1]}"
        section=${section:2}
        if [[ "${section}" == "${saved}" ]]; then
            if [[ ! "${subsection}" == "${saved_subsection}" ]]; then
                saved_subsection="${subsection}"
                local desc="${array[3]}"
                desc=${desc:0:-2}
                printf "\n"
                printf "%60s" "= $subsection ="
                printf "\n\n"
                printf "%-60s %-60s\n" "${array[2]}" "${desc}"
            else
                saved_subsection="${subsection}"
                printf "%-60s %-60s\n" "${array[2]}" "${desc}"
            fi
        else
            saved="${section}"
            printf "\n\n"
            printf "%60s" "== $section =="
            printf "\n"
            printf "%60s" "= $subsection ="
            printf "\n\n"
            printf "%-60s %-60s\n" "Command" "Description"
            printf "%-60s %-60s\n" "---------" "---------"
            local desc="${array[3]}"
            desc=${desc:0:-2}
            printf "%-60s %-60s\n" "${array[2]}" "${desc}"
        fi
    done
}
main
#         if [[ arr[i][0] == *$stringB* ]]; then
#             # Do something here
#         else
#             # Do Something here
#         fi
#         if
#            printf($column_size, "Command", "Description");

#         printf($column_size, names[i], addresses[i], sizes[i]);
#     }

# echo ${#arr[@]}
# unset arr
# printf %s\\n a b c | {
#     readarray arr
#     echo ${#arr[@]}
# }

# '.realnames as $names | .posts[] | {title, author: $names[.author]}'
# cat ~/dotfiles/bin/gpg_help.json | jq -r 'keys[] as $k | "\($k), \(.[$k] | .ip)"'

# cat ~/dotfiles/bin/gpg_help.json | jq '.section[] | .subsection[] | "\(.name) .items[]"'
# jq -r 'to_entries[] | [.key, .value.ip] | @tsv'

# jq '.section[] | .subsection[] | "\(.name) .items[]"'


# cat ~/dotfiles/bin/gpg_help.json | jq -c '.sections[] | .name as $secname | .subsection[] | .name as $subname | .items[] | {$secname, $subname, command, description}' | readarray -t arr ; echo ${#arr[@]}

#  | readarray -t arr ; echo ${#arr[@]}

#!/bin/bash
# Some functions I am using in my scripts
fileDate() {
    stat "$@" | awk '{print $10}'
}
fileSize() {
    optChar='f'
               fmtString='%z'
    stat -$optChar "$fmtString" "$@"
}

fileType() {
    test="$(stat "${*}" )" || true
    if [[ $test ]]; then
        myStr="$(stat "$*" | awk '{print $3}')" # get the file type string
        if [[ "${myStr:0:1}" = 'd' ]]; then
            echo "directory"
        elif [[ "${myStr:0:1}" = '-' ]]; then
            echo "file"
        elif [[ "${myStr:0:1}" = 'l' ]]; then
            str="$(readlink -f "$@")"
            t="${str// /\\ }"
            x="fileType ${t}"
            eval "$x"
        fi # end if
    else
        echo "unknown"
    fi # end if
}

isLocalFS() {
    myStr="$(df -P "$*" | tail -n +2 | awk '{print $1}')" # get the file type string
    if [[ "${myStr:0:4}" = '/dev' ]]; then
        return 0
    else
        return 1
    fi # end if
}

isDir()  {
    dir=$(fileType "$@")
    if [[ "$dir" = "directory" ]]; then
        return 0
    else
        return 1
    fi
}

isFile()  {
    file=$(fileType "$@")
    if [[ "$file" = "file" ]]; then
        return 0
    else
        return 1
    fi
}

compareFiles() {
    local file1="$1"
    local file2="$2"
    local size1
    local size2
    local date1
    local date2

    test1="$(stat "$file1" 2> /dev/null)" || true
    test2="$(stat "$file2" 2> /dev/null)" || true
    if [[ $test1 && $test2 ]]; then
        size1="$(fileSize "$file1")"
        size2="$(fileSize "$file2")"
        date1="$(fileDate "$file1")"
        date2="$(fileDate "$file2")"
        if [[ $size1 -eq $size2 && $date1 -eq $date2 ]]; then
            return 0
        else
            return 1
        fi
    else
        return 1
    fi
}
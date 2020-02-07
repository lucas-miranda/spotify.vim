"
" TODO:
"   - [ ] Treat cases where path ends with separator
"   - [ ] Auto identify separator used at path
"

function! path#separator()
    if has('win32')
        return '\'
    endif

    return '/'
endfunction

function! path#parent_fullpath(path, ...)
    if a:0 > 0 && type(a:1) == 1 " 1: string
        let l:separator = a:1
    else
        let l:separator = path#separator()
    endif

    let l:parent_fullpath = ''
    let l:path_splitted = split(a:path, l:separator)
    let l:index = 0

    while l:index < len(l:path_splitted)
        if l:index < len(l:path_splitted) - 1
            let l:parent_fullpath .= l:path_splitted[l:index] . l:separator
        endif

        let l:index += 1
    endwhile

    if has('unix')
        " prepend unix '/' to fullpath
        if a:path[0] == l:separator
            let l:parent_fullpath = l:separator . l:parent_fullpath
        endif
    endif

    return l:parent_fullpath
endfunction

function! path#child_fullpath(path, item_name, ...)
    if a:0 > 0 && type(a:1) == 1 " 1: string
        let l:separator = a:1
    else
        let l:separator = path#separator()
    endif

    let l:child_path = ''

    let l:path_splitted = split(a:path, l:separator)
    let l:start_build_path = 0

    for item in l:path_splitted
        if !l:start_build_path
            if item ==? a:item_name
                let l:start_build_path = 1
            endif

            continue
        endif

        let l:child_path = l:child_path . item . '\'
    endfor

    return l:child_path
endfunction

function! path#fullname(path, ...)
    if a:0 > 0 && type(a:1) == 1 " 1: string
        let l:separator = a:1
    else
        let l:separator = path#separator()
    endif

    let l:path_splitted = split(a:path, l:separator)
    return l:path_splitted[len(l:path_splitted) - 1]
endfunction

function! path#name(path, ...)
    if a:0 > 0 
        let l:fullname = path#fullname(a:path, a:1)
    else
        let l:fullname = path#fullname(a:path)
    endif

    let l:matches = matchlist(l:fullname, '\(.\+\)\..\+\|\(.\+\)')

    if l:matches[1] != ''
        return l:matches[1]
    elseif l:matches[2] != ''
        return l:matches[2]
    endif

    return ''
endfunction

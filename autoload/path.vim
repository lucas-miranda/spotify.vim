function! path#separator()
    if has('win32')
        return '\'
    endif

    return '/'
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

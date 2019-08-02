if !exists('s:spotify_providers')
    let g:spotify_providers_verbose = 0
    let s:spotify_providers = {}
    let s:is_std_providers_loaded = 0
endif

let s:me = resolve(expand('<sfile>:p'))

" ------------ "
"  public api
" ------------ "

function! spotify#providers#load(...) abort
    let l:force_load = 0

    if a:0 > 0 && a:1
        let l:force_load = 1
    endif

    if s:is_std_providers_loaded && !l:force_load
        if g:spotify_providers_verbose > 0
            echo 'Providers already loaded'
        endif
        return
    endif

    let l:providers_path = path#parent_fullpath(s:me) . 'std_providers' . path#separator()
    let l:providers_files = glob(l:providers_path . '*.vim', 0, 1)

    if type(l:providers_files) != 3 " 3: list
        return
    endif

    for provider_filename in l:providers_files
        let l:provider_name = path#name(provider_filename)
        let l:provider_namespace = 'spotify#std_providers#' . l:provider_name
        let l:name = substitute(l:provider_name, '.provider', '', 'g')

        let l:provider = {
        \   'name': l:name,
        \   'start': l:provider_namespace . '#start',
        \   'stop': l:provider_namespace . '#stop',
        \   'status': l:provider_namespace . '#status',
        \   'is_running': l:provider_namespace . '#is_running',
        \ }

        call spotify#providers#register(l:name, l:provider)

        if g:spotify_providers_verbose > 0
            echo 'Registered Provider: ' . l:name
        endif
    endfor

    let s:is_std_providers_loaded = 1

    if g:spotify_providers_verbose > 0
        echo 'Registered providers successfully'
    endif
endfunction

function! spotify#providers#register(name, provider) abort
    let s:spotify_providers[a:name] = a:provider
endfunction

function! spotify#providers#get(name) abort
    if !has_key(s:spotify_providers, a:name)
        echoerr "Invalid provider name '" . a:name . "'"
        return
    endif

    return s:spotify_providers[a:name]
endfunction

function! spotify#providers#call(name, function_name, ...) abort
    let l:provider = spotify#providers#get(a:name)

    let l:args = ''

    if a:0 > 0
        let l:args = join(a:000, ', ')
    endif

    execute('let l:ret =  ' . l:provider[a:function_name] . '(' . l:args . ')')
    return l:ret
endfunction

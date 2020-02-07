" ------------- "
"  global vars
" ------------- "

if !exists('g:provider_name')
    let g:spotify_requests_delay = 1 " seconds
    let g:spotify_verbose = 0
    let g:max_requests_failed = 3

    if has('win32')
        let g:provider_name = "win32"
    elseif has('unix')
        let g:provider_name = "unix"
    endif
endif

" ------------- "
"  script vars
" ------------- "

if !exists('s:provider')
    let s:request_errors_count = 0
    let s:on_request_fail_wait_time = 3000 " milli
    let s:provider = {}
endif

" ------------------ "
"  helper functions
" ------------------ "

function! s:has_all_keys(dict, ...)
    for key in a:000
        if !has_key(a:dict, key)
            return 0
        endif
    endfor

    return 1
endfunction

" ------------------- "
"  private functions 
" ------------------- "

function! s:verify_provider(name) abort
    " make sure providers are loaded
    call spotify#providers#load()

    if !exists('s:provider') || type(s:provider) != 4 || !has_key(s:provider, 'name') || s:provider['name'] !=? a:name " 4: dict
        let s:provider = spotify#providers#get(a:name)
    endif
endfunction

function! s:provider_call(function_name, ...)
    if a:0 > 0
        let l:args = join(a:000, ', ')
        execute('let l:ret = spotify#providers#call(g:provider_name, a:function_name, ' . l:args . ')')
        return l:ret
    endif

    return spotify#providers#call(g:provider_name, a:function_name)
endfunction

function! s:provider_call_err(function_name, ...)
    if a:0 > 0
        let l:args = join(a:000, ', ')
        execute('let l:started_without_problems = spotify#providers#call(g:provider_name, a:function_name, ' . l:args . ')')
    else
        let l:started_without_problems = spotify#providers#call(g:provider_name, a:function_name)
    endif

    if l:started_without_problems < 1
        if g:spotify_verbose > 0
            echo "Some problem occurred with provider '" . g:provider_name . "' at '" . a:function_name . "'."
        endif

        return 0
    endif

    return 1
endfunction

" ------------ "
"  public api
" ------------ "

function! spotify#requests#start() abort
    if spotify#requests#is_running()
        if g:spotify_verbose > 0
            echo 'Spotify requests is already running.'
        endif
        return 0
    endif

    call s:verify_provider(g:provider_name)

    let s:request_errors_count = 0
    let l:start_status = s:provider_call_err('start', g:spotify_requests_delay)

    if l:start_status <= 0
        return 0
    endif

    if g:spotify_verbose > 0
        echo "Spotify Requests Started."
    endif

    return 1
endfunction

function! spotify#requests#stop() abort
    if spotify#requests#is_running()
        if g:spotify_verbose > 0
            echo "Spotify requests already is stopped."
        endif
        return
    endif

    let l:stop_status = s:provider_call('stop')
    call spotify#player#update()

    if l:stop_status <= 0
        return 0
    endif

    if g:spotify_verbose > 0
        echo "Spotify requests stopping."
    endif
endfunction

function! spotify#requests#is_running() abort
    call s:verify_provider(g:provider_name)
    return s:provider_call('is_running')
endfunction

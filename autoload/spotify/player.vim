" ------------- "
"  global vars
" ------------- "

if !exists('g:spotify_display')
    let g:spotify_display = {
        \ 'icon': {
        \   'playing': '',
        \   'paused': '',
        \   'stopped': ''
        \ }
    \ }
endif

" ---------------- "
"  initialization
" ---------------- "

if !exists('s:track_data')
    let s:track_data = {
        \ 'type': 'none',
        \ 'name': '',
        \ 'artist': '',
        \ 'album': '',
        \ 'progress': -1.0,
        \ 'is_playing': 0
    \ }
endif

" ------------------- "
"  private functions
" ------------------- "

function! s:update_display() abort
    if !exists('s:current_status') || !has_key(g:spotify_display.icon, s:current_status)
        let s:current_status = 'stopped'
    endif

    let s:current_display = g:spotify_display.icon[s:current_status]

    if s:track_data.type ==? 'none' || (s:track_data.type ==? 'track' && empty(s:track_data.name) && empty(s:track_data.artist))
        let s:current_display .= ' Nothing'
    elseif s:track_data.type ==? 'ad'
        let s:current_display .= ' Advertisement'
    elseif s:track_data.type ==? 'track'
        let s:current_display .= ' ' . s:track_data.name . ' - ' . s:track_data.artist

        if has_key(s:track_data, 'album') && s:track_data.album != ''
            let s:current_display .= ' (' . s:track_data.album . ')'
        endif

        if has_key(s:track_data, 'progress') && s:track_data.progress >= 0.0
            let l:track_progress = float2nr(s:track_data.progress * 100.0) . '%'
            let s:current_display .= ' ' .l:track_progress
        endif
    endif
endfunction

" ------------ "
"  public api
" ------------ "

function! spotify#player#update(...) abort
    if !spotify#requests#is_running() || !exists('s:current_display')
        let s:track_data.type = 'none'
        let s:current_status = 'stopped'
    elseif a:0 > 0 && type(a:1) == 4 && !empty(a:1) " 4: dict
        let s:track_data.type = a:1.type

        if s:track_data.type ==? 'ad' || s:track_data.type ==? 'none'
            " nothing to deal with
        elseif s:track_data.type ==? 'track'
            if has_key(a:1, 'name')
                let s:track_data.name = a:1.name
            endif

            if has_key(a:1, 'artist')
                let s:track_data.artist = a:1.artist
            endif

            if has_key(a:1, 'album')
                let s:track_data.album = a:1.album
            endif

            if has_key(a:1, 'progress')
                let s:track_data.progress = a:1.progress
            endif
        else
            echoerr 'spotify.vim: Unknown type ' . s:track_data.type . ''
        endif

        let s:track_data.is_playing = a:1.is_playing
        let s:current_status = s:track_data.is_playing ? 'playing' : 'paused'
    endif

    call s:update_display()
endfunction

function! spotify#player#track() abort
    return s:track_data.name
endfunction

function! spotify#player#artist() abort
    return s:track_data.artist
endfunction

function! spotify#player#album() abort
    return s:track_data.album
endfunction

function! spotify#player#status() abort
    if !exists('s:current_status') || !has_key(g:spotify_display.icon, s:current_status)
        let s:current_status = 'stopped'
    endif

    return s:current_status
endfunction

function! spotify#player#status_icon() abort
    return g:spotify_display.icon[spotify#player#status()]
endfunction

function! spotify#player#display() abort
    if !exists('s:current_display') || !spotify#requests#is_running()
        call spotify#player#update()
    endif

    return s:current_display
endfunction

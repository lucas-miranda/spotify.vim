function! s:spotify_status() abort
python3 << PYTHON_EOF
import subprocess
import re
import vim

vim.command("let l:spotify_data = { 'title': ''}");

window_ids_regex = re.compile(r'\n')
spotify_window_title_regex = re.compile(r'(.+)\-(.+)\n?')

xdotool_process = subprocess.run(["xdotool", "search", "--class", "spotify"], capture_output=True)
xdotool_stdout = xdotool_process.stdout.decode("utf-8")
windows_ids = window_ids_regex.split(xdotool_stdout)

for window_id in windows_ids:
    xdotool_getwindowname = subprocess.run(["xdotool", "getwindowname", window_id], capture_output=True)
    window_name = xdotool_getwindowname.stdout.decode("utf-8")
    window_name_match = spotify_window_title_regex.match(window_name)

    if window_name_match:
        vim.command('let l:spotify_data = { "title": "%s - %s" }' % (window_name_match.group(1), window_name_match.group(2)))
    else:
        window_name_splitted = window_name.lower().split('\n')
        if len(window_name_splitted) > 0:
            window_name = window_name_splitted[0]

        if window_name == "spotify free" or window_name == "spotify premium" or window_name == "advertisement":
            vim.command('let l:spotify_data = { "title": "%s" }' % window_name)

PYTHON_EOF

    return l:spotify_data
endfunction

function! spotify#std_providers#unix_provider#request_update(timer_id) abort
    let l:status = s:spotify_status()

    if type(l:status) != 4 || !has_key(l:status, 'title') || l:status['title'] == ''
        call spotify#player#update({
        \   'type': 'none',
        \   'is_playing': 0
        \ })
        return
    endif

    let l:title = l:status.title

    if l:title ==? 'advertisement'
        call spotify#player#update({
        \   'type': 'ad',
        \   'is_playing': 1
        \ })
    elseif l:title ==? 'spotify free' || l:title ==? 'spotify premium'
        call spotify#player#update({
        \   'type': 'track',
        \   'is_playing': 0
        \ })
    else
        let l:matches = matchlist(l:title, '\(.\{-1,}\) - \(.\+\)')

        if len(l:matches) >= 3
            let l:track_name = l:matches[2]
            let l:artist = l:matches[1]

            call spotify#player#update({
            \   'type': 'track',
            \   'name': l:track_name,
            \   'artist': l:artist,
            \   'is_playing': 1
            \ })
        endif
    endif

    let s:request_errors_count = 0 " each successful request resets errors count
endfunction

" ------------ "
"  public api
" ------------ "

function! spotify#std_providers#unix_provider#start(delay) abort
    if spotify#std_providers#unix_provider#is_running()
        timer_stop(s:update_timer_info.id)
    endif

    let l:timer_id = timer_start(a:delay * 1000, 'spotify#std_providers#unix_provider#request_update', { 'repeat': -1 })
    let s:update_timer_info = timer_info(l:timer_id)[0]
    return 1
endfunction

function! spotify#std_providers#unix_provider#stop() abort
    if !spotify#std_providers#unix_provider#is_running()
        return 1
    endif

    timer_stop(s:update_timer_info.id)
    return 1
endfunction

function! spotify#std_providers#unix_provider#status() abort
    return s:spotify_status()
endfunction

function! spotify#std_providers#unix_provider#is_running() abort
    if exists('s:update_timer_info') && type(s:update_timer_info) == 4
        let l:info = timer_info(s:update_timer_info.id)
        if type(l:info) == 3 && len(l:info) > 0 && type(l:info[0]) == 4 && l:info[0].callback ==# s:update_timer_info.callback " 3: list, 4: dict
            return 1
        endif
    endif

    return 0
endfunction

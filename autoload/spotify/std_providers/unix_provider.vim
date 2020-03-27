function! s:spotify_status() abort
python3 << PYTHON_EOF
import subprocess
import re
import vim

song_data = {
    'title': '',
    'artist': '',
    'status': '' 
}

playerctl_process = subprocess.run(['playerctl', '--player=spotify', 'metadata', 'title'], capture_output=True, encoding='UTF-8')
if playerctl_process.returncode == 0:
    song_data['title'] = playerctl_process.stdout.replace('\n', '').replace("'", "''")

playerctl_process = subprocess.run(['playerctl', '--player=spotify', 'metadata', 'artist'], capture_output=True, encoding='UTF-8')
if playerctl_process.returncode == 0:
    song_data['artist'] = playerctl_process.stdout.replace('\n', '').replace("'", "''")

playerctl_process = subprocess.run(['playerctl', '--player=spotify', 'status'], capture_output=True, encoding='UTF-8')
if playerctl_process.returncode == 0:
    song_data['status'] = playerctl_process.stdout.replace('\n', '').lower()

vim.command(f"""let l:spotify_data = {{ 'title': '{song_data['title']}', 'artist': '{song_data['artist']}', 'status': '{song_data['status']}' }}""")
PYTHON_EOF

    return l:spotify_data
endfunction

function! spotify#std_providers#unix_provider#request_update(timer_id) abort
    let l:status = s:spotify_status()

    if type(l:status) != 4 || l:status['status'] == ''
        call spotify#player#update({
        \   'type': 'none',
        \   'is_playing': 0
        \ })
        return
    endif

    let l:title = l:status.title
    let l:artist = l:status.artist
    let l:song_status = l:status.status

    let l:is_playing = 0
    if l:song_status ==? 'playing'
        let l:is_playing = 1
    endif

    if l:title ==? 'advertisement'
        call spotify#player#update({
        \   'type': 'ad',
        \   'is_playing': l:is_playing
        \ })
    else
        call spotify#player#update({
        \   'type': 'track',
        \   'name': l:title,
        \   'artist': l:artist,
        \   'is_playing': l:is_playing
        \ })
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

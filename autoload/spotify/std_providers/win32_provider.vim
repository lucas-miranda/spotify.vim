function! s:spotify_status() abort
python << PYTHON_EOF
import os
import pathlib
import win32api, win32con, win32gui, win32process
import vim

vim.command("let l:spotify_data = { 'title': ''}");

ignore_titles = [ 'G', 'Default IME', 'MSCTFIME UI' ]

def callback_get_processes(hwnd, processes):
    thread_id, pid = win32process.GetWindowThreadProcessId(hwnd)
    title = win32gui.GetWindowText(hwnd)
    processes.append(dict({ 'pid': pid, 'title': title }))

processes = []
win32gui.EnumWindows(callback_get_processes, processes)

for process in processes:
    try:
        handle = win32api.OpenProcess(win32con.PROCESS_QUERY_INFORMATION | win32con.PROCESS_VM_READ, False, process['pid'])
        process_name = win32process.GetModuleFileNameEx(handle, None)
        handle.close()

        process_path = pathlib.PurePath(process_name)
        if process_path.name.lower() == 'spotify.exe' and len(process['title']) > 0 and not (process['title'] in ignore_titles):
            vim.command('let l:spotify_data = {{ "title": "{}" }}'.format(process['title'].replace('"', '\"')))
    except Exception:
        pass

PYTHON_EOF

    return l:spotify_data
endfunction

function! spotify#std_providers#win32_provider#request_update(timer_id) abort
    let l:status = s:spotify_status()

    if type(l:status) != 4 || !has_key(l:status, 'title') || l:status['title'] == ''
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

function! spotify#std_providers#win32_provider#start(delay) abort
    if spotify#std_providers#win32_provider#is_running()
        timer_stop(s:update_timer_info.id)
    endif

    let l:timer_id = timer_start(a:delay * 1000, 'spotify#std_providers#win32_provider#request_update', { 'repeat': -1 })
    let s:update_timer_info = timer_info(l:timer_id)[0]
    return 1
endfunction

function! spotify#std_providers#win32_provider#stop() abort
    if !spotify#std_providers#win32_provider#is_running()
        return 1
    endif

    timer_stop(s:update_timer_info.id)
    return 1
endfunction

function! spotify#std_providers#win32_provider#status() abort
    return s:spotify_status()
endfunction

function! spotify#std_providers#win32_provider#is_running() abort
    if exists('s:update_timer_info') && type(s:update_timer_info) == 4
        let l:info = timer_info(s:update_timer_info.id)
        if type(l:info) == 3 && len(l:info) > 0 && type(l:info[0]) == 4 && l:info[0].callback ==# s:update_timer_info.callback " 3: list, 4: dict
            return 1
        endif
    endif

    return 0
endfunction

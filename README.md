Description
------------

A plugin to get info about Spotify. 
It's main goal is to use with a statusline to show current track info without leaving vim.

Features
-------------

- Currently works on Windows and Linux.
- Retrieves from time to time the track and artist from Spotify window.
- Provides a set of functions to get current track data, so you can use whenever you want.

Dependencies
-------------

### Windows

- [NeoVim](https://neovim.io/)
- Python 2 (with vim correctly detecting it)
  - [pywin32](https://github.com/mhammond/pywin32)
  - [pynvim](https://github.com/neovim/pynvim)

### Linux

- [NeoVim](https://neovim.io/)
- Python 3 (with vim correctly detecting it)
  - [pynvim](https://github.com/neovim/pynvim)
- [playerctl](https://github.com/altdesktop/playerctl)

Installation
-------------

Using a package manager:

 - [vim-plug](https://github.com/junegunn/vim-plug):
   - Add `Plug 'lucas-miranda/spotify.vim'` 
   - `:PlugInstall`

Planned
--------

- Incorporate Mac OS.
- Obtain even more information of Spotify (Track progress, album name, etc).

License
--------

Spotify.vim is under [MIT License](/LICENSE)

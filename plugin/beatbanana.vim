" beatbanana
" Author: skanehira
" License: MIT

if exists('loaded_beatbanana')
  finish
endif
let g:loaded_beatbanana = 1

command! BeatBananaStart call beatbanana#start()
command! BeatBananaStop call beatbanana#stop()

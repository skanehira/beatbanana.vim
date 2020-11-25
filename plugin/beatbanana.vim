" beatbanana
" Author: skanehira
" License: MIT

if exists('loaded_beatbanana')
  finish
endif
let g:loaded_beatbanana = 1

command! Start call beatbanana#start()
command! Stop call beatbanana#stop()

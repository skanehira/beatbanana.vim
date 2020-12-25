" beatbanana
" Author: skanehira
" License: MIT

hi! beatbanana_bar ctermfg=110 ctermbg=110
hi! beatbanana_bottom_bar ctermfg=17 ctermbg=17
hi! beatbanana_hit ctermfg=203  ctermbg=203
hi! beatbanana_hit_good ctermfg=107  ctermbg=107

let s:bottom_bar_winid_set = {}
" {
" 'j': [0, 1, 2, ...],
" 'k': [10, 11, 12, ...],
" ...
" }
let s:bar_winid_set = {
      \ 'a': [],
      \ 's': [],
      \ 'd': [],
      \ 'f': [],
      \ 'h': [],
      \ 'j': [],
      \ 'k': [],
      \ 'l': [],
      \ }

let s:bar_timers = []

function! s:make_block_text(word, col_len) abort
  let text = ''
  for i in range(a:col_len)
    let text .= a:word
  endfor
  return text
endfunction

function! s:new_block(opt, timer) abort
  let text = s:make_block_text('0', a:opt.col_len)
  let winid = popup_create(text, {
        \ 'col': a:opt.col_pos,
        \ 'line': 1,
        \ 'minwidth': strlen(text),
        \ })

  call win_execute(winid, 'syntax match beatbanana_bar /0/')

  let timer = timer_start(60, function("s:move_block_down", [winid, a:opt.press_key]), {
        \ 'repeat': -1,
        \ })
  call add(s:bar_timers, timer)
  call add(s:bar_winid_set[a:opt.press_key], winid)
endfunction

function! s:make_block(opt, timer) abort
  call add(s:bar_timers, timer_start(rand(srand()) % 1000, function('s:new_block', [a:opt])))
endfunction

function! s:move_block_down(winid, press_key, timer) abort
  let opt = popup_getpos(a:winid)
  if empty(opt)
    return
  endif
  if opt.line is# s:winheight
    call timer_stop(a:timer)
    call popup_close(a:winid)
    call s:delete_block_winid(a:press_key, a:winid)
    return
  endif

  let opt.line += 1
  call popup_move(a:winid, opt)
endfunction

function! s:delete_block_winid(press_key, winid) abort
  let idx = index(s:bar_winid_set[a:press_key], a:winid)
  if idx isnot -1
    call remove(s:bar_winid_set[a:press_key], idx)
  endif
endfunction

function! s:make_bottom_block(opt) abort
  let text = s:make_block_text('1', a:opt.col_len)
  let winid = popup_create(text, {
        \ 'col': a:opt.col_pos,
        \ 'line': s:winheight,
        \ 'minwidth': strlen(text),
        \ })

  call win_execute(winid, 'syntax match beatbanana_bottom_bar /1/')
  let s:bottom_bar_winid_set[a:opt.press_key] = winid
endfunction

function! s:restore_bottom_bar_highlight(winid, timer) abort
  call win_execute(a:winid, 'syntax match beatbanana_bottom_bar /1/')
endfunction

function! s:collision_detection(key) abort
  let winids = s:bar_winid_set[a:key]
  if empty(winids)
    return 0
  endif

  let bar_winid = winids[0]
  let opt = popup_getpos(bar_winid)

  return opt.line is# s:winheight || opt.line is# s:winheight - 1
endfunction

function! s:press_bottom_bar(key) abort
  let winid = s:bottom_bar_winid_set[a:key]
  if s:collision_detection(a:key)
    call win_execute(winid, 'syntax match beatbanana_hit_good /1/')
  else
    call win_execute(winid, 'syntax match beatbanana_hit /1/')
  endif
  call add(s:bar_timers, timer_start(150, function('s:restore_bottom_bar_highlight', [winid])))
endfunction

function! s:popups_clear() abort
  for ids in values(s:bar_winid_set)
    for id in ids
      call popup_close(id)
    endfor
  endfor

  for id in values(s:bottom_bar_winid_set)
    call popup_close(id)
  endfor
endfunction

function! s:timers_clear() abort
  for t in s:bar_timers
    call timer_stop(t)
  endfor
endfunction

function! beatbanana#start() abort
  tabnew beatbanana
  let s:bufid = bufnr()
  let s:winid = win_getid()
  let s:winheight = winheight(s:winid) -1
  let s:winwidth = winwidth(s:winid)
  let s:bottom_bar_keys = ['a', 's', 'd', 'f', 'h', 'j', 'k', 'l']

  let col_len = s:winwidth / 8 - 4
  let col_pos = 4
  for i in range(8)
    let press_key = s:bottom_bar_keys[i]
    let opt = {
          \ 'press_key': press_key,
          \ 'col_len': col_len,
          \ 'col_pos': col_pos,
          \ }
    call s:make_bottom_block(opt)
    exe printf('nnoremap <silent> <buffer> %s :call <SID>press_bottom_bar("%s")<CR>', press_key, press_key)
    call add(s:bar_timers, timer_start(1000, function('s:make_block', [opt]), {'repeat': -1}))
    let col_pos += (col_len + 4)
  endfor
  mapclear! <buffer>
endfunction

func beatbanana#stop() abort
  exe printf('bw! %d', s:bufid)
  call s:popups_clear()
  call s:timers_clear()
endfunc

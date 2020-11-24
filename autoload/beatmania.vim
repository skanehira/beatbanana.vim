" beatmania
" Author: skanehira
" License: MIT

hi! beatmania_bar ctermfg=110 ctermbg=110
hi! beatmania_bottom_bar ctermfg=17 ctermbg=17
hi! beatmania_hit ctermfg=203  ctermbg=203

let s:bar_winid_set = {}

function! s:make_bar_text(word, col_len) abort
  let text = ''
  for i in range(a:col_len)
    let text .= a:word
  endfor
  return text
endfunction

function! s:new_bar(opt, timer) abort
  let text = s:make_bar_text('0', a:opt.col_len)
  let winid = popup_create(text, {
        \ 'col': a:opt.col_pos,
        \ 'line': 1,
        \ 'minwidth': strlen(text),
        \ })

  call win_execute(winid, 'syntax match beatmania_bar /0/')

  call timer_start(30, function("s:move_down", [winid]), {
        \ 'repeat': -1,
        \ })
endfunction

function! s:make_bar(opt, timer) abort
  call timer_start(rand(srand()) % 1000, function('s:new_bar', [a:opt]))
endfunction

function! s:move_down(winid, timer) abort
  let opt = popup_getpos(a:winid)
  if opt.line is# s:winheight
    call timer_stop(a:timer)
    call popup_close(a:winid)
    return
  endif

  let opt.line += 1
  call popup_move(a:winid, opt)
endfunction

function! s:make_bottom_bar(opt) abort
  let text = s:make_bar_text('1', a:opt.col_len)
  let winid = popup_create(text, {
        \ 'col': a:opt.col_pos,
        \ 'line': s:winheight,
        \ 'minwidth': strlen(text),
        \ })

  call win_execute(winid, 'syntax match beatmania_bottom_bar /1/')
  let s:bar_winid_set[a:opt.press_key] = winid
endfunction

function! s:restore_bottom_bar_highlight(winid, timer) abort
  call win_execute(a:winid, 'syntax match beatmania_bottom_bar /1/')
endfunction

function! s:get_bar_winid(key) abort
  return s:bar_winid_set[a:key]
endfunction

function! s:press_bottom_bar(key) abort
  let winid = s:get_bar_winid(a:key)
  call win_execute(winid, 'syntax match beatmania_hit /1/')
  call timer_start(200, function('s:restore_bottom_bar_highlight', [winid]))
endfunction

function! s:start() abort
  vnew beatmania
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
    call s:make_bottom_bar(opt)
    exe printf('nnoremap <silent> <buffer> %s :call <SID>press_bottom_bar("%s")<CR>', press_key, press_key)
    call timer_start(700, function('s:make_bar', [opt]), {'repeat': -1})
    let col_pos += (col_len + 4)
  endfor
endfunction

func s:stop() abort
  bw!
  call popup_clear()
  call timer_stopall()
endfunc

command! Start call <SID>start()
command! Stop call <SID>stop()


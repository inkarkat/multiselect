" multiselect.vim: multiple persistent selections
" Author: Hari Krishna (hari_vim at yahoo dot com)
" Last Change: 24-May-2006 @ 15:32
" Created: 08-Sep-2006 @ 22:17
" Requires: Vim-7.0, genutils.vim(2.0)
" Version: 2.2.0
" Licence: This program is free software; you can redistribute it and/or
"          modify it under the terms of the GNU General Public License.
"          See http://www.gnu.org/copyleft/gpl.txt 
" Download From:
"     http://www.vim.org/script.php?script_id=953
" Acknowledgements:
"     See :help multiselect-acknowledgements
" Description:
"     See doc/multiselect.txt

if exists('loaded_multiselect')
  finish
endif
if v:version < 700
  echomsg 'multiselect: You need at least Vim 7.0'
  finish
endif

" Dependency checks.
if !exists('loaded_genutils')
  runtime plugin/genutils.vim
endif
if !exists('loaded_genutils') || loaded_genutils < 200
  echomsg "multiselect: You need a newer version of genutils.vim plugin"
  finish
endif
let loaded_multiselect = 202

" Initializations {{{

if !exists('g:multiselQuickSelAdds')
  let g:multiselQuickSelAdds = 0
endif

if !exists('g:multiselUseSynHi')
  let g:multiselUseSynHi = 0
endif

if !exists('g:multiselAbortOnErrors')
  let g:multiselAbortOnErrors = 1
endif

if !exists('g:multiselMouseSelAddMod')
  let g:multiselMouseSelAddMod = 'C-'
endif

if !exists('g:multiselMouseSelAddKey')
  let g:multiselMouseSelAddKey = 'Left'
endif

command! -range MSAdd :call multiselect#AddSelection(<line1>, <line2>)
command! MSDelete :call multiselect#DeleteSelection()
command! -range=% MSClear :call multiselect#ClearSelection(<line1>, <line2>)
command! MSRestore :call multiselect#RestoreSelections()
command! MSRefresh :call multiselect#RefreshSelections()
command! -range MSInvert :call multiselect#InvertSelections(<line1>, <line2>)
command! MSHide :call multiselect#HideSelections()
command! -bang -nargs=1 -complete=command MSExecCmd
      \ :call multiselect#ExecCmdOnSelection(<q-args>, 0, <bang>0)
command! -bang -nargs=1 -complete=command MSExecNormalCmd
      \ :call multiselect#ExecCmdOnSelection(<q-args>, 1, <bang>0)
command! -bang MSExecDelete
      \ :silent call multiselect#ExecCmdOnSelection('delete _', 0, <bang>0)
      \ |call multiselect#ClearSelection(1, line('$'))
      " Note: Use :silent to suppress the reporting of deleted lines.
command! -bang -register MSExecYank
      \ :if <q-register> =~# '^\u$'
      \ | call ingo#register#accumulate#ExecuteOrFunc(<q-register>, "call multiselect#ExecCmdOnSelection('yank v:val', 0, <bang>0)")
      \ |else
      \ | call setreg(<q-register>, '')
      \ | call ingo#register#accumulate#ExecuteOrFunc(<q-register>, "call multiselect#ExecCmdOnSelection('yank v:val', 0, <bang>0)")
      \ | call setreg(<q-register>, substitute(getreg(<q-register>), '^\n', '', ''))
      \ |endif
command! -bang -nargs=1 -complete=command MSSubstitute
      \ :call multiselect#ExecCmdOnSelection('substitute' . <q-args>, 0, <bang>0)
command! -bang MSShow :call multiselect#ShowSelections(<bang>0)
command! -bang MSPrint :call multiselect#ExecCmdOnSelection('number', 0, <bang>0)
command! MSNext :call multiselect#NextSelection(1)
command! MSPrev :call multiselect#NextSelection(-1)
command! -range=% -nargs=1 MSMatchAdd :call multiselect#AddSelectionsByMatch(<line1>,
      \ <line2>, <q-args>, 0)
command! -range=% -nargs=1 MSVMatchAdd :call multiselect#AddSelectionsByMatch(<line1>,
      \ <line2>, <q-args>, 1)
command! -range=% -nargs=1 MSMatchAddBySynGroup :call
      \ multiselect#AddSelectionsBySynGroup(<line1>, <line2>, <q-args>, 0)
command! -range=% -nargs=1 MSVMatchAddBySynGroup :call
      \ multiselect#AddSelectionsBySynGroup(<line1>, <line2>, <q-args>, 1)
command! -range=% -nargs=1 MSMatchAddByDiffHlGroup :call
      \ multiselect#AddSelectionsByDiffHlGroup(<line1>, <line2>, <q-args>, 0)
command! -range=% -nargs=1 MSVMatchAddByDiffHlGroup :call
      \ multiselect#AddSelectionsByDiffHlGroup(<line1>, <line2>, <q-args>, 1)

if (! exists("no_plugin_maps") || ! no_plugin_maps) &&
      \ (! exists("no_multiselect_maps") || ! no_multiselect_maps) " [-2f]

if (! exists("no_multiselect_mousemaps") || ! no_multiselect_mousemaps)
  " NOTE: The conditional <Esc> is because sometimes for a single line
  " selection, Vim doesn't seem to start the visual mode, so an unconditional
  " <Esc> will generate 'eb's.
  exec 'noremap <expr> <silent> <'.g:multiselMouseSelAddMod.
        \ g:multiselMouseSelAddKey.'Mouse> '.
        \ '"\<'.g:multiselMouseSelAddKey.'Mouse>".'.
        \ '(mode()=~"[vV\<C-V>]"?"\<Esc>":"")."V"'
  exec 'noremap <silent> <'.g:multiselMouseSelAddMod.
        \ g:multiselMouseSelAddKey.'Drag> <'.g:multiselMouseSelAddKey.'Drag>'
  exec 'noremap <silent> <'.g:multiselMouseSelAddMod.
        \ g:multiselMouseSelAddKey.'Release> '.
        \ (g:multiselQuickSelAdds ? ':MSAdd' : ':MSInvert').
        \ '<CR><'.g:multiselMouseSelAddKey.'Release>'
endif

vnoremap <silent> <Plug>MSSelect m`:MSInvert<Enter>g``
if ! hasmapto('<Plug>MSSelect', 'x')
  xmap <Enter> <Plug>MSSelect
endif

function! s:AddMap(name, map, cmd, mode, silent)
  if (!hasmapto('<Plug>MS'.a:name, a:mode) && !empty(a:map))
    exec a:mode.'map <unique> <Leader>'.a:map.' <Plug>MS'.a:name
  endif
  exec a:mode.'map '.(a:silent?'<silent> ':'').'<script> <Plug>MS'.a:name.
        \ ' '.a:cmd
endfunction

call s:AddMap('AddSelection', 'msa', 'm`:MSAdd<CR>``', 'x', 1)
call s:AddMap('AddSelection', 'msa', ':MSAdd<CR>', 'n', 1)
call s:AddMap('DeleteSelection', 'msd', ':MSDelete<CR>', 'n', 1)
call s:AddMap('ClearSelection', 'msc', ':MSClear<CR>', 'x', 1)
call s:AddMap('ClearSelection', 'msc', ':MSClear<CR>', 'n', 1)
call s:AddMap('RestoreSelections', 'msr', ':MSRestore<CR>', 'n', 1)
call s:AddMap('RefreshSelections', 'msf', ':MSRefresh<CR>', 'n', 1)
call s:AddMap('HideSelections', 'msh', ':MSHide<CR>', 'n', 1)
call s:AddMap('InvertSelections', 'msi', ':MSInvert<CR>', 'n', 1)
call s:AddMap('InvertSelections', 'msi', ':MSInvert<CR>', 'x', 1)
call s:AddMap('ShowSelections', 'mss', ':MSShow<CR>', 'n', 1)
call s:AddMap('PrintSelections', 'msp', ':MSPrint<CR>', 'n', 1)
call s:AddMap('NextSelection', 'ms]', ':MSNext<CR>', 'n', 1)
call s:AddMap('PrevSelection', 'ms[', ':MSPrev<CR>', 'n', 1)
call s:AddMap('ExecCmdOnSelection', 'ms:', ':MSExecCmd<Space>', 'n', 0)
call s:AddMap('ExecNormalCmdOnSelection', 'msn', ':MSExecNormalCmd<Space>', 'n',
      \ 0)
call s:AddMap('ExecDelete', '', ':MSExecDelete<CR>', 'n', 1)
call s:AddMap('ExecYank', 'msy', ':execute "MSExecYank" v:register<CR>', 'n', 1)
call s:AddMap('MatchAddSelection', 'msm', ':MSMatchAdd<Space>', 'x', 0)
call s:AddMap('MatchAddSelection', 'msm', ':MSMatchAdd<Space>', 'n', 0)
call s:AddMap('VMatchAddSelection', 'msv', ':MSVMatchAdd<Space>', 'x', 0)
call s:AddMap('VMatchAddSelection', 'msv', ':MSVMatchAdd<Space>', 'n', 0)

delf s:AddMap
endif

" Initializations }}}


" vim6:fdm=marker et sw=2

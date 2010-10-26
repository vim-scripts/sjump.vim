" vim:set fileencoding=utf-8 sw=3 ts=8 et:vim
"
" Author: Marko Mahnič
" Created: October 2010
" License: GPL (http://www.gnu.org/copyleft/gpl.html)
" This program comes with ABSOLUTELY NO WARRANTY.

if exists("g:sjump_loaded") && g:sjump_loaded
   finish
endif

if !exists("g:sjump_enable_keymap")
   let g:sjump_enable_keymap = 1
endif

if g:sjump_enable_keymap
   nmap gl :call sjump#JumpToLabel()<cr>
endif


" vim:set fileencoding=utf-8 sw=3 ts=8 et:vim
"
" Author: Marko Mahnič
" Created: October 2010
" License: GPL (http://www.gnu.org/copyleft/gpl.html)
" This program comes with ABSOLUTELY NO WARRANTY.

let s:marked_info = {}
let s:max_signs = 99
" TODO: find available id to start
let s:sign_id_start = 3019
let s:signs_initialized = 0

" TODO: (maybe) separate sets for first and second key
if !exists("g:sjump_label_chars") || len(g:sjump_label_chars) < 5
   let g:sjump_label_chars = "abcdefghijklmnopqrstuvwxyz"
endif

if !exists("g:sjump_step_size_pairs")
   let g:sjump_step_size_pairs = [ [1, 1], [2, 1], [3, 1], [1, 2], [2, 2], [3, 2] ]
   "let g:sjump_step_size_pairs = [ [1, 1], [1, 2], [2, 1], [2, 2], [3, 1], [3, 2] ]
endif

" decide on the sign format based on number of lines, jump_keys adn
" step_size_pairs:
"   - whether to use every line, 2nd line, ...
"   - use combinations of (up to 2) symbols
function! s:AnalyzeLines(lnStart, lnEnd, bufNumber)
   let nl = a:lnEnd - a:lnStart
   let nd = len(g:sjump_label_chars)
   let sz = 1
   let step = 1

   " Try predefined
   for [step, sz] in g:sjump_step_size_pairs
      if step * sz * nd >= nl
         break
      endif
   endfor

   " Fallback - find first that is big enough
   if step * sz * nd < nl
      let sz = 1
      let step = 1
      if nl > nd
         let sz = (nl + nd - 1) / nd
      endif
      if sz > 2
         let sz = 2
         while step * sz * nd < nl
            let step = step + 1
         endwhile
      endif
   endif
   return { "step": step, "size": sz, 'key_count': nd, 'bufnr': a:bufNumber, "line_count": nl }
endfunc

" Label size can only be 1 or 2 (sign limitation)
function! s:Index2Label(i, jumpinfo)
   let nd = len(g:sjump_label_chars)
   if a:jumpinfo['size'] == 1
      return g:sjump_label_chars[a:i % nd]
   else
      let c1 = a:i / nd
      let c2 = a:i % nd
      return g:sjump_label_chars[c1 % nd] . g:sjump_label_chars[c2 % nd]
   endif
endfunc

" returns -1 if no such label
function! s:LabelToIndex(label, jumpinfo)
   if len(a:label) != a:jumpinfo['size']
      return -1
   endif
   if a:jumpinfo['size'] == 1
      return stridx(g:sjump_label_chars, a:label[0])
   else
      let c1 = stridx(g:sjump_label_chars, a:label[0])
      let c2 = stridx(g:sjump_label_chars, a:label[1])
      if c1 < 0 || c2 < 0 
         return -1
      endif
      return c1 * nd + c2
   endif
endfunc

function! s:InitSigns()
   if s:signs_initialized | return | endif
   hi default HL_SignJump gui=none  ctermfg=gray ctermbg=black  guifg=white guibg=black
   let s:signs_initialized = 1
endfunc

function! s:ShowSigns()
   let wt = line("w0")
   let wb = line("w$")
   let bnr = bufnr("%")
   let jumpinfo = s:AnalyzeLines(wt, wb, bnr)
   let step = jumpinfo['step']
   let i = 0      " label id
   let iln = wt   " line number
   let idisp = 0  " count visible lines (skipping folds)
   while iln <= wb
      if i > s:max_signs
         break
      endif
      if foldclosed(iln) != -1
         let iln = foldclosedend(iln)+1
         continue
      endif
      if idisp % step == 0
         let name = "SJUMP_M" . i
         let id = s:sign_id_start + i
         let sign = s:Index2Label(i, jumpinfo)
         if sign == ""
            break
         endif
         exec 'sign define '.name.' text='.sign.' texthl=HL_SignJump'
         exec 'sign place '.id.' line='.iln.' name='.name.' buffer='.bnr
         let i = i + 1
      endif
      let idisp = idisp + 1
      let iln = iln + 1
   endwhile 
   let s:marked_info[bnr] = i
   return jumpinfo
endfun

function! s:HideSigns(bufNumber)
   if !has_key(s:marked_info, a:bufNumber) | return | endif
   let imax = s:marked_info[a:bufNumber]
   let i = 0
   let sbnr = ' buffer='.a:bufNumber
   while i < imax
      let id = s:sign_id_start + i
      exec 'sign unplace '.id.sbnr
      let i = i + 1
   endwhile
   unlet s:marked_info[a:bufNumber]
   return
endfunc

function! s:GetLabel(jumpinfo)
   let msg = "Type the label >>>"
   echo msg . a:jumpinfo['size']
   let label = ""
   let i = 0
   while i < a:jumpinfo['size']
      let cc = nr2char(getchar())
      if stridx(g:sjump_label_chars, cc) < 0
         let label = ""
         break
      endif
      let label = label . cc
      redraw | echo msg . label
      let i = i + 1
   endwhile
   redraw | echo ""
   return label
endfunc

function! s:JumpToLabel(label, jumpinfo)
   let id = s:sign_id_start + s:LabelToIndex(a:label, a:jumpinfo)
   exec 'sign jump ' . id . ' buffer=' . a:jumpinfo['bufnr']
endfunc

function! sjump#JumpToLabel()
   let bnr = bufnr("%")
   try
      call s:InitSigns()
      let jumpinfo = s:ShowSigns()
      let bnr = jumpinfo['bufnr']
      let label = s:GetLabel(jumpinfo)
      call s:JumpToLabel(label, jumpinfo)
   finally
      call s:HideSigns(bnr)
   endtry
endfunc


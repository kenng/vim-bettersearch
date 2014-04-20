" ============================================================================
" File:        betterSearch.vim
" Description: provide better search functionality in vim
" Maintainer:  Ng Khian Nam
" Email:       ngkhiannam@gmail.com
" Last Change: 4 Jan 2013
" License:     We grant permission to use, copy modify, distribute, and sell this
"              software for any purpose without fee, provided that the above copyright
"              notice and this text are not removed. We make no guarantee about the
"              suitability of this software for any purpose and we are not liable
"              for any damages resulting from its use. Further, we are under no
"              obligation to maintain or extend this software. It is provided on an
"              "as is" basis without any expressed or implied warranty.
" ============================================================================
let s:betterSearch_version = '0.0.7'

" todo: consider to use vimgrep and getqflist() to compare the performance of
" using global to search for the result.
"
" note: append(line, list) takes in list, unless the search content is formatted
" into a list, the put! is preferred in this way

" initialization {{{

if v:version < 700
    echoerr "Need Vim version >= 7 "
    finish
endif

if exists('loaded_BetterSearch')
    finish
endif
let loaded_BetterSearch = 1
let s:next_buf_number = 1
let s:content_window_nr = 0
"bufnr of bettersearch buffer
let s:bettersearch_window_nr = 0
let s:content_window_path = ""
let s:isHighlightOn = 1
let s:isCopyToClipboard = 0
let s:syn_case = &ignorecase ? " ignore " : " match "
let s:search_token_copy = []

hi def BetterSearchH0  guifg=Yellow  guibg=black     gui=bold  ctermfg=14    ctermbg=0     cterm=bold
hi def BetterSearchH1  guifg=#FF8000 guibg=black     gui=bold  ctermfg=NONE  ctermbg=NONE  cterm=NONE
hi def BetterSearchH2  guifg=#FF0000 guibg=black     gui=bold  ctermfg=NONE  ctermbg=NONE  cterm=NONE
hi def BetterSearchH3  guifg=#8F00FF guibg=black     gui=bold  ctermfg=NONE  ctermbg=NONE  cterm=NONE
hi def BetterSearchH4  guifg=#3E8131 guibg=black     gui=bold  ctermfg=NONE  ctermbg=NONE  cterm=NONE
hi def BetterSearchH5  guifg=#A42D7D guibg=black     gui=bold  ctermfg=NONE  ctermbg=NONE  cterm=NONE
hi def BetterSearchH6  guifg=#3E8187 guibg=black     gui=bold  ctermfg=NONE  ctermbg=NONE  cterm=NONE
hi def BetterSearchH7  guifg=black   guibg=#cae682   gui=bold  ctermfg=NONE  ctermbg=NONE  cterm=NONE
hi def BetterSearchH8  guifg=black   guibg=#FF6C60   gui=bold  ctermfg=NONE  ctermbg=NONE  cterm=NONE
hi def BetterSearchH9  guifg=black   guibg=#2E58BE   gui=bold  ctermfg=NONE  ctermbg=NONE  cterm=NONE
hi def BetterSearchH10 guifg=black   guibg=#631E89   gui=bold  ctermfg=NONE  ctermbg=NONE  cterm=NONE


let g:BetterSearchhighlight = [ 'BetterSearchH0', 'BetterSearchH1',
                      \ 'BetterSearchH2', 'BetterSearchH3', 'BetterSearchH4',
                      \ 'BetterSearchH5', 'BetterSearchH6', 'BetterSearchH7',
                      \ 'BetterSearchH8', 'BetterSearchH9', 'BetterSearchH10' ]


" content window and search window mapping, for the use of switching between
" window
let s:win_mapping = {}

" === command === "
command! -n=0 -bar BetterSearchPromptOn :call s:BetterSearchPrompt()
command! -n=0 -bar -range BetterSearchVisualSelect :call s:VisualSearch()
command! -n=0 -bar BetterSearchSwitchWin :call s:SwitchBetweenWin()
command! -n=1 -bar BetterSearchHighlightLimit :let g:BetterSearchTotalLine=<args>
command! -n=0 -bar BetterSearchHighlighToggle :let s:isHighlightOn=!s:isHighlightOn | echo "BetterSearchHighlight is now ".(s:isHighlightOn? "on" : "off")
command! -n=0 -bar BetterSearchCopyToClipBoard :let s:isCopyToClipboard=!s:isCopyToClipboard
command! -n=0 -bar BetterSearchCloseWin :call s:CloseBetterSearchWin()
command! -n=* -bar BetterSearchChangeHighlight :call s:SetHighlightName(<f-args>)

function s:SetDefaultVariable(name, default)
    if !exists(a:name)
        let {a:name} = a:default
    endif
endfunction

call s:SetDefaultVariable("g:BetterSearchMapHelp", "<F1>")
call s:SetDefaultVariable("g:BetterSearchMapHighlightSearch", "c")
call s:SetDefaultVariable("g:BetterSearchTotalLine", 5000)


" }}}

" function {{{
function s:CloseBetterSearchWin()
    if s:bettersearch_window_nr != 0
        exe s:bettersearch_window_nr."bwipeout"
    endif
endfunction

function s:VisualSearch() range
    execute "normal! gv""y"
    let l:temp = @"
    :silent! call s:BetterSearch(l:temp)
endfunction

function s:SetHighlightName(index, name)
    if a:index >= 0 && a:index < len(g:BetterSearchhighlight)
        let l:old_name = g:BetterSearchhighlight[a:index]
        let g:BetterSearchhighlight[a:index]=a:name
        echo "g:BetterSearchhighlight[".a:index."] change from ".l:old_name. " to ".a:name
    endif
endfunction

function s:SwitchBetweenWin()
    let s:current_buf_nr = bufnr("")
    if has_key(s:win_mapping, s:current_buf_nr)
        let l:jump_win = bufwinnr(s:win_mapping[s:current_buf_nr])
        exe l:jump_win."wincmd w"
    else
        echo "buffer ".s:current_buf_nr." not found"
    endif
endfunction

function s:GoToLine()
    let lineNum = matchstr(getline("."), '^ *[[:digit:]]\+')
    if lineNum != ""
        call s:SwitchBetweenWin()
        exe ":".lineNum
    endif
endfunction

function s:BetterSearchBindMapping()
    exec "nnoremap <silent> <buffer> <2-leftmouse> :call <SID>GoToLine()<cr>"
    exec "nnoremap <silent> <buffer> <cr> :call <SID>GoToLine()<cr>"
    exec "nnoremap <silent> <buffer> ". g:BetterSearchMapHelp ." :call <SID>displayHelp()<cr>"
    exec "nnoremap <silent> <buffer> ". g:BetterSearchMapHighlightSearch ." :call <SID>HighlightSearchWord()<cr>"
endfunction

" --- help description ---
function s:displayHelp()
    exe "80vnew"
    setlocal buftype=nofile
    setlocal bufhidden=wipe
    setlocal noswapfile
    setlocal nobuflisted
    exec "nnoremap <silent> <buffer> ". g:BetterSearchMapHelp ." :q<cr>"

    " get the name of the highlight syntax string
    let l:index = 0
    let l:pattern_name_text = ""
    while l:index < len(g:BetterSearchhighlight)
        let l:pattern_name_text = l:pattern_name_text.
                \ "g:BetterSearchhighlight".l:index." = "
                \ .g:BetterSearchhighlight[l:index]."\n"
        let l:index = l:index + 1
    endwhile


    let l:help_text = "Press ". g:BetterSearchMapHelp ." to close this help window\n\n"
    let l:help_text = l:help_text
        \ . "--- [ Navigation ] ---\n"
        \ . "Press <ENTER> on that particular line to jump to the content window.\n"
        \ . "\n\n"
        \ . ""
        \ . ""
        \ . "--- [ supported commanline ] ---\n"
        \ . "':BetterSearchSwitchWin'       \n"
        \ . "  - to switch between the 'Search Window' and the 'Content Window'\n"
        \ . "':BetterSearchVisualSelect'    \n"
        \ . "  - to search based on the visually selected word\n"
        \ . "':BetterSearchHighlighToggle'  \n"
        \ . "  - to toggle keyword highlight on off (default is on)\n"
        \ . "':BetterSearchHighlightLimit'  \n"
        \ . "  - to toggle line limit to switch off keyword highlight,\n"
        \ . "    for efficiency purpose, especially for large matched \n"
        \ . "  - default is 5000 line\n"
        \ . "':BetterSearchCopyToClipBoard' \n"
        \ . "  - to toggle whether to save to the search words to clipboard\n"
        \ . "  - default is off\n"
        \ . "':BetterSearchChangeHighlight' \n"
        \ . "  - to change the highlight of the search term (start from index zero '0')\n"
        \ . "  - e.g to change the highlight of first search term to 'Directory' highlight\n"
        \ . "    :let g:BetterSearchhighlight[0] = 'Directory' \n"
        \ . "  - e.g to change the highlight of second search term to 'BetterSearchHighlight10' highlight\n"
        \ . "    :let g:BetterSearchhighlight[1] = 'BetterSearchHighlight10' \n"
        \ . "  - default maximum definable highlight is 11 (That's really more than enough! ;)"
        \ . "':BetterSearchCloseWin' \n"
        \ . "  - to close the betterSearch window\n"
        \ . "\n\n"
        \ . ""
        \ . ""
        \ . "--- [ mapping ] ---\n"
        \ . "Suggest to map following in .vimrc, e.g: \n"
        \ . "nnoremap <A-S-F7> :BetterSearchPromptOn<CR>\n"
        \ . "vnoremap <A-S-F7> :BetterSearchVisualSelect<CR>\n"
        \ . "nnoremap <A-w>    :BetterSearchSwitchWin<CR>\n"
        \ . "nnoremap <A-S-q>  :BetterSearchCloseWin<CR>\n"
        \ . "\n\n"
        \ . ""
        \ . ""
    let l:help_text = l:help_text
        \ . "--- [ highlight ] syntax --- \n" . l:pattern_name_text
    let s:oldContent = @g
    let @g = l:help_text
    exe "1put! g"
    let @g = s:oldContent
    if s:isHighlightOn
        execute 'syn match BetterSearch #:BetterSearch\w\+#'
        execute "hi link BetterSearch String"
        let l:index = 0
        while index < len(g:BetterSearchhighlight)
            execute "syn match BetterSearchhighlight".index. " #". g:BetterSearchhighlight[index] ."#"
            execute "hi link BetterSearchhighlight".index. " ".g:BetterSearchhighlight[index]
            let l:index = l:index + 1
        endwhile

    endif
    setlocal nomodifiable
endfunction


" --- for search highlight toggle on/off ---
function s:HighlightSearchWord()
    "syn match search1
    let s:isHighlightOn = !s:isHighlightOn
    call s:BetterSearchSyntaxHighlight(s:search_token_copy)
endfunction

" --- for search highlight toggle
function s:BetterSearchSyntaxHighlight(search_token)
    execute "syn match helpText #Press ". g:BetterSearchMapHelp ." for help#"
    execute "hi link helpText Comment"
    execute "syn match line_number #^ *[0-9]\* #"
    execute "hi link line_number LineNr"

    let l:index = 0
    " --- if total line of search result is less than g:BetterSearchTotalLine
    if s:isHighlightOn && (line('$') < g:BetterSearchTotalLine)
        echo "search highlight on"
        while index < len(a:search_token)
            " --- if total search_token is less than what we can color
            if (index < len(g:BetterSearchhighlight))
                " --- define highlight pattern, e.g. syn match search_word[n] <pattern>
                execute "syn case ".s:syn_case
                execute "syn  match BetterSearchhighlight".index." #". a:search_token[index] ."#"
                execute "hi link BetterSearchhighlight".index. " ".g:BetterSearchhighlight[index]
                let l:index = l:index + 1
            endif
        endwhile
    elseif !s:isHighlightOn
        echo "search highlight off"
        while index < len(a:search_token)
            if (index < len(g:BetterSearchhighlight))
                "execute "syn match search_word".index. " #". a:search_token[index] ."#"
                execute "hi link BetterSearchhighlight".index. " Normal"
                let l:index = l:index + 1
            endif
        endwhile
    endif
endfunction

" --- main function of search ----
function s:BetterSearch(...)
	let list_len = a:0
	let str=""
	let cur_line = line(".")
	if list_len !=0
		" if argument list is not empty
        if ( match(a:1, "|"))
            let str = ""
            let ori_str = a:1
            let l:search_token = []
            for myword in split(a:1, '|')
                call add(l:search_token, myword)
                if (str!="")
                    " add the escape '|'
                    let str = str.'\|'.myword
                else
                    let str = myword
                endif
                "echom "str is ". str
            endfor
        else
		    let str=a:1
        endif

        if s:isCopyToClipboard
            let @+=a:1
        endif
        "echo "search term ".str
	else
		let str=expand("<cword>")
	endif

    " save the user expandtab value, then set to noexpandtab for search.
    " This is to prevent the case like original doc is tab-based,
    " while user setting is expandtab to space. This causes the 
    " GoToLine not able to find the corresponding match due to 
    " mismatch in space.
    let s:content_window_path = expand("%:p")
	" clear register g
    let s:oldContent = @g
    let s:oldnumber = &number
    let s:syn_case = &ignorecase ? " ignore " : " match "
    set number
	let @g="\"  Press ". g:BetterSearchMapHelp ." for help\n\n"
    let @g=@g."content path : ". s:content_window_path. "\n"
	let @g=@g."search term: \n". ori_str."\n\n"
    let @g=@g."================================================================================\n"
    let @g=@g."Line                         Result\n"
    let @g=@g."================================================================================"
	" redirect global search output to register g
	silent exe "redir @g>>"
	silent exe "g /". str
	silent exe "redir END"
    let &number=s:oldnumber
    if ( list_len == 2)
        call cursor(a:2, 1)
    else
        let s:content_window_nr = bufnr("")
        let s:next_buf_number += 1
        " open a new buffer
        exe "new BetterSearch". s:next_buf_number
        " set this buffer attribute
        setlocal buftype=nofile
        setlocal bufhidden=wipe
        setlocal noswapfile
        setlocal nobuflisted
        setlocal nonumber
        call s:BetterSearchBindMapping()
        let s:bettersearch_window_nr = bufnr("")
        let s:win_mapping[s:content_window_nr]=s:bettersearch_window_nr
        let s:win_mapping[s:bettersearch_window_nr]=s:content_window_nr

    endif
    " paste the content of register g before line 1
    exe "1put! g"
    let @g=s:oldContent
    " ---- syntax highlight ----
    call s:BetterSearchSyntaxHighlight(l:search_token)
    let s:search_token_copy = copy(l:search_token)
    setlocal nomodifiable
endfunction

" --- give the user a prmopt to key the search ----
" --- each search term can be separate by a bar '|' ----
" --- e.g.: search_term1|search_term2|search_term3 ----
function s:BetterSearchPrompt()
	let mm = inputdialog("search term", "", "cancel pressed")
    if mm != "" && mm != "cancel pressed"
        :exe 'silent call s:BetterSearch(mm)'
        if s:isCopyToClipboard
            :let @"=mm
        endif
    else
        "process if user press okay
        if mm != "cancel pressed"
            :exe 'silent call s:BetterSearch(expand("<cword>"))'
        endif
    endif
endfunction
" }}}

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" History of changes:
"
" [ version ] 0.0.9 ( 20 Apr 2014 )
"   - use custom define highlight
"   - highlighter now able to highlight according to option ignorecase
"
" [ version ] 0.0.8 ( 8 Apr 2014 )
"   - revert function gotoLine() as it is easy and accurate
"   - added highlight for line number in the result
"
" [ version ] 0.0.7 ( 29 Mar 2014 )
"   - fixed bug not able to jump to line when line number is switched on
"   - fixed bug not able to jump to line which contains certain regexp
"
" [ version ] 0.0.6 ( 02 Mar 2014 )
"   - escape characters which will cause gotoLine() not able to match string
"   - use search() instead of global / in gotoLine()
"
" [ version ] 0.0.5 ( 02 Mar 2014 )
"   - enable [Enter] to jump to particular line without line number switched on

" History of changes:
" [ version ] 0.0.4 ( 04 Jan 2013 )
"   - enhanced help description
"
" [ version ] 0.0.3 ( 04 Jan 2013 )
"   - showed the file path
"   - added function to close the bettersearch window from anywhere
"   - fixed visual select search
"
" [ version ] 0.0.2 ( 01 Oct 2012 )
"   - able to set highlight syntax
"   - change default shortcut for syntax=c, help=F1
"   - improve help description
"                                                                              "
" vim:foldmethod=marker:tabstop=4
"                                                                              "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


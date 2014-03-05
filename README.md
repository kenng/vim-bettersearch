vim-bettersearch
================

##Why
Having a large file and you need to search for a few keywords from it?

And wish that you can see all the search result in a "search result window"?

Best with highlight on the keyword?

And you would wish to jump to that particular line when you see something 
interesting?

Here is what for you!

Solution approach: works somewhat similarly to notepad++ search function, but of
course this is much better as it is in vim!

##Features offered
- This script is written to copy all the search result and put it to window 
  above the content.
- The search result is 'jumpable' to the content window by just enter on that 
  particular search line
- Search term highlight can be switched on and off
- Search keyword can be saved to clipboard

![demo](https://lh4.googleusercontent.com/-n0t1bG6Kg9c/Urdxwq-ETpI/AAAAAAAAERU/p14VNH7APNk/w943-h597-no/Screenshot+from+2013-12-23+07%253A06%253A58.png)

## Example Usage
There are a few way to use the function of this script.
###[ Usage 1 ]
User intended to type in the search words
```
:BetterSearchPromptOn
```
then ENTER.
A window will pop up for user input.
The user input can consists of more than one search term. For example: 
search_A|search_B|search_C...

###[ Usage 2 ]
User intended to use the word under the cursor as the search term
```
:BetterSearchPromptOn
```
then ENTER, and press ENTER again when the user input dialog box appear without 
type in any word

###[ Usage 3 ]
User intended to use the word highlighted in visual mode.

Hightlight the word, then type
```
:BetterSearchVisualSelect
```
then ENTER.

###[ Jump to line ]
A search window will be open up on top of the current window.
Press ENTER on that particular line to jump to the content window.

## Other Commands
Other command available by the script. (or press F1 when the focus/cursor is at 
the search window)

```
':BetterSearchSwitchWin'        - to switch between the 'Search Window' and the 'Content Window'
':BetterSearchVisualSelect'     - to search based on the visually selected word
':BetterSearchHighlighToggle'   - to toggle keyword highlight on off (default is on)
':BetterSearchHighlightLimit'   - to toggle line limit to switch off keyword highlight, for efficiency purpose, especially for large matched, default is 5000 line
':BetterSearchCopyToClipBoard'  - to toggle whether to save to the search words to clipboard, default is off
```

## Mapping
Suggest to map following in .vimrc, e.g:

```
nnoremap <A-S-F7> :BetterSearchPromptOn<CR>
vnoremap <A-S-F7> :BetterSearchVisualSelect<CR>
nnoremap <A-w>    :BetterSearchSwitchWin<CR>
nnoremap <A-S-q>  :BetterSearchCloseWin<CR>
```

## Installation

### Using Pathogon

```
mkdir -p ~/.vim/bundle
cd ~/.vim/bundle
git clone https://github.com/kenng/vim-bettersearch.git
```

### The OLD way
1. Paste the betterSearch.vim script into plugin folder.
   E.g. Vim\vim73\plugin.
2. Restart the Vim session

## Found a Bug
You may use the [issue tracker][tracker] to report the bug found.

## Contribution
Contribution is welcomed!

[tracker]: https://github.com/kenng/vim-bettersearch/issues


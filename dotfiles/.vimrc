" http://www.vim.org/htmldoc/options.html
" http://rayninfo.co.uk/vimtips.html
" https://github.com/gigamo/dotfiles/blob/master/.vimrc
" https://github.com/swaroopch/dotvim/blob/master/vimrc
"
" {{{   General Options
" -------------------------------------------------------------------------------
set nocompatible                " Use VIM defaults as a base
if v:version >= 700
    set cursorline              " Show a line over the cursor
"    set cursorcolumn            " Show a column over the cursor
    set list listchars=tab:»-,eol:¶,trail:·,nbsp:¬  " Show 'unwanted' chars
else
    set list listchars=tab:>-,trail:.,extends:>
endif
set paste                       " Don't indent pasted code
set pdev=HP_p3005_PCL_5E        " Our printer
set nobackup                    " Don't crearte *~ backup files
set noswapfile                  " Disable swapfiles
set ignorecase                  " Iggnore case while searching (using lowercase)
set smartcase                   " Case sensitive si se usan mayúsculas
set number                      " Show every line number
set encoding=utf-8              " Encoding
set termencoding=utf-8          " ^
set scrolloff=999               " Keep the cursor in the middle of the screen
set mouse=a                     " Selections won't include the line number
set expandtab                   " Don't use tabs, use spaces instead
set tabstop=4                   " 4 spaces tabs
set shiftwidth=4                " Allows the use of < and > for VISUAL indenting
set backspace=indent,eol,start  " Allow backspace over everything
set ttyfast                     " Enable features for fast ttys
set foldmethod=marker           " Manual folding with {{{ and }}}
set incsearch                   " Show results while searching
set hlsearch                    " Underline results while searching
set showcmd                     " Show uncomplete commands
set wildmenu                    " Show autoicompletion menu
set wildmode=list:longest       " Bash-like tab completion
set visualbell                  " Disable beep (but enables visualbell)
set t_vb=                       " Disable visualbell
set autoread                    " Reread externally modified files
" }}}
" {{{  Statusbar
" -------------------------------------------------------------------------------
set laststatus=2                             " Always show the statusbar
set statusline=                              " Statusbar creation
set statusline+=%2*%-3.3n%0*\                " Buffer number
set statusline+=%f\                          " Filename
set statusline+=%h%1*%m%r%w%0*               " Flags
set statusline+=\[%{strlen(&ft)?&ft:'none'}, " Filetype
set statusline+=%{&encoding},                " Encoding
set statusline+=%{&fileformat}]              " File format
set statusline+=%=                           " Right align
set statusline+=%2*0x%-8B\                   " Current char
set statusline+=%-14.(%l,%c%V%)\ %<%P        " Offset
" }}}
" {{{  Theming and Syntax Highlighting
" -------------------------------------------------------------------------------
if &t_Co > 2
    set background=dark " We'll use dark backgorunds
    syntax on           " We want fancy colors
endif
if has('gui_running')   " It will trigger with gVim
    colorscheme herald
    set gfn=Terminus                            " Font
"    set guioptions-=m                           " Disable Menu
    set guioptions-=T                           " Disable yoolbar
    set guioptions-=l                           " Disable scrollbars
    set guioptions-=L                           " ^
    set guioptions-=r                           " ^
    set guioptions-=R                           " ^
    if has("autocmd") && has("gui")
        autocmd GUIEnter * set t_vb=            " Disable visualbell
    endif
elseif (&term =~ 'rxvt-256color') || (&term =~ 'screen-256color')
    colorscheme inkpot
elseif (&term =~ 'xterm') || (&term =~ 'xterm-256color')
    colorscheme herald
else
    colorscheme blackbeauty
endif
" }}}
" {{{   Events
" -------------------------------------------------------------------------------
if has("autocmd")
    " Don't want vim to process txt files (syntax highlightning for example)
    autocmd BufRead *.txt set ft=
    " F6 bindings to compile/execute
    autocmd FileType sh       map <F6> :!bash %<CR>
    autocmd FileType php      map <F6> :!php & %<CR>
    autocmd FileType python   map <F6> :!python %<CR>
    autocmd FileType perl     map <F6> :!perl %<CR>
    autocmd FileType ruby     map <F6> :!ruby %<CR>
    autocmd FileType lua      map <F6> :!lua %<CR>
    autocmd FileType htm,html map <F6> :!firefox %<CR>
    " Reload vimrc when saving changes
    autocmd! BufWritePost .vimrc source %
    " Show redundant spaces with a red background
    highlight RedundantSpaces ctermbg=red guibg=red
    match RedundantSpaces /\s\+$\| \+\ze\t\|\t/

endif
" }}}
" {{{   Functions
" -------------------------------------------------------------------------------
if has("eval")
    " Say a message
    function! Say(msg)
        echohl IncSearch
        echo a:msg
        echohl None
    endfunction
    " Removing unwanted CR or LF characters
    function! Dos2Unix()
        %s/\r\+$//e
        %s/\r/ /gce
        call Say("Deleted ^M at $ and replaced with space everywhere else.")
    endfunction
    command! Dos2Unix call Dos2Unix()
    " Delete redundant spaces
    function! StripWhite()
        %s/[ \t]\+$//ge
        %s!^\( \+\)\t!\=StrRepeat("\t", 1 + strlen(submatch(1)) / 8)!ge
        call Say("Redundant spaces erased.")
    endfunction
    command! StripWhite call StripWhite()
    " Delete blank lines
    function! RemoveBlankLines()
        %s/^[\ \t]*\n//g
    endfunction
    command! RemoveBlankLines call RemoveBlankLines()
    " Copy full buffer into clipboard.
    function! CopyAll()
        normal mzggVG"+y'z
        call Say("Full buffer copied into clipboard.")
    endfunction
    command! CopyAll call CopyAll()
    " Delete buffer contents and Paste from OS clipboard.
    function! PasteFromClipboard()
        normal ggVGd"+p1G
        call Say("Buffer replaced with clipboard.")
    endfunction
    command! PasteFromClipboard call PasteFromClipboard()
endif
" }}}
" {{{   Plugins
" -------------------------------------------------------------------------------
" Buftabs http://www.vim.org/scripts/script.php?script_id=1664
let g:buftabs_only_basename  = 1
" TagList http://www.vim.org/scripts/script.php?script_id=273
let Tlist_Exit_OnlyWindow    = 1 " Exit if taglist is last window open
let Tlist_Show_One_File      = 1 " Only show tags for current buffer
let Tlist_Enable_Fold_Column = 0 " no fold column (only showing one file)
let Tlist_Use_Right_Window   = 1 " TagList on the Right
let Tlist_Compact_Format     = 1 " Won't show line numbers, etc...
let Tlist_Show_Menu          = 1 " Show a 'Tags' menu in gVim
map <F4> :Tlist<CR>
" NERDTree http://www.vim.org/scripts/script.php?script_id=1658
let NERDTreeMapActivateNode  = '<CR>'  " Enter will open nodes
map <F3> :NERDTreeToggle<CR>
" }}}
" {{{   Keybindings
" -------------------------------------------------------------------------------
" Disable the F1 help key
map  <F1> <Esc>
imap <F1> <Esc>
" NOTE "\" is the default Leader key.
nmap <leader>sw<left>  :topleft  vnew<CR>
nmap <leader>sw<right> :botright vnew<CR>
nmap <leader>sw<up>    :topleft  new<CR>
nmap <leader>sw<down>  :botright new<CR>
" New buffer shortcuts
nmap <leader>s<left>   :leftabove  vnew<CR>
nmap <leader>s<right>  :rightbelow vnew<CR>
nmap <leader>s<up>     :leftabove  new<CR>
nmap <leader>s<down>   :rightbelow new<CR>
" Tab shortcuts
map <leader>tn :tabnew<cr>
map <leader>te :tabedit
map <leader>tc :tabclose<cr>
map <leader>tm :tabmove
" Movement between windows
map <C-j> <C-W>j
map <C-k> <C-W>k
map <C-h> <C-W>h
map <C-l> <C-W>l
" Remove highlights and redraw screen
nnoremap <C-L> :nohls<CR>
" Switch buffers with F1 and F2, close Nerdtree if active
noremap <F1> :NERDTreeClose<CR> :bprev!<CR>
noremap <F2> :NERDTreeClose<CR> :bnext!<CR>
" }}}

" vim: filetype=vim

"http://www.vim.org/htmldoc/options.html
"http://rayninfo.co.uk/vimtips.html
"http://github.com/gigamo/
"-------------------------------------------------------------------------------
"{{{   General
"-------------------------------------------------------------------------------
set nocompatible                " Usa config por defecto de vim
syntax on                       " Muchos colores
set paste                       " No indentar codigo 'pasteado'
"set pdev=IRADV_C5035            " Impresora a usar
set pdev=HP_p3005_PCL_5E        " Impresora a usar
set nobackup                    " No crea ficheros de backup *~
set noswapfile                  " disable swapfiles
set ignorecase                  " ignorar case en búsquedas (usando minúsculas)
set smartcase                   " case sensitive si se usan mayúsculas
set number                      " muetra nº de lineas
set encoding=utf-8              " Encoding
set termencoding=utf-8          " ^
if v:version >= 700
    set cursorline              " Resalta la línea del cursor
"    set cursorcolumn            " Resalta la columna del cursor
    set list listchars=tab:»-,eol:¶,trail:·,nbsp:¬  " Muestra chars 'no deseados'
endif
set mouse=a                     " selecciones no incluyen el nº de lineas.
set tabstop=4                   " Tabs de 4 espacios
set expandtab                   " Inserta espacios en vez de tabs
set shiftwidth=4                " Allows the use of < and > for VISUAL indenting
set ttyfast                     " Mejoras para terminales rápidas
set foldmethod=marker           " folding manual con {{{ }}}
set hlsearch                    " Subraya las búsquedas
set showcmd                     " Muestra comandos incompletos
set wildmenu                    " Muestra menú con opciones de autocompletado
set wildmode=list:longest       " Tab completion 'bash-like'
set visualbell                  " Desactiva el beep (pero activa visualbell)
set t_vb=                       " Anulamos la propia visualbell
set backspace=indent,eol,start  " Permitir backspace sobre todo
""}}}
""{{{  Statusbar
""-------------------------------------------------------------------------------
set laststatus=2                             " Muestra siempre la statusbar
set statusline=                              " La creamos
set statusline+=%2*%-3.3n%0*\                " Número de buffer
set statusline+=%f\                          " Nombre del fichero
set statusline+=%h%1*%m%r%w%0*               " flags
set statusline+=\[%{strlen(&ft)?&ft:'none'}, " filetype
set statusline+=%{&encoding},                " encoding
set statusline+=%{&fileformat}]              " file format
set statusline+=%=                           " right align
set statusline+=%2*0x%-8B\                   " current char
set statusline+=%-14.(%l,%c%V%)\ %<%P        " offset
"}}}
"{{{   Temas
"-------------------------------------------------------------------------------
if has('gui_running')
    "colorscheme blackbeauty " Tema para gVim
    colorscheme understated " Tema para gVim
    set gfn=Terminus\ 12                        " Fuente
    let &guicursor = &guicursor . ",a:blinkon0" " Disable cursor blinking
"    set guioptions-=m                           " Fuera Menu
    set guioptions-=T                           " Fuera Barra de herramientas
    set guioptions-=l                           " Fuera Scrollbars
    set guioptions-=L                           " ^
    set guioptions-=r                           " ^
    set guioptions-=R                           " ^
    if has("autocmd") && has("gui")
        autocmd GUIEnter * set t_vb=            " Desactiva visualbell en GVim
    endif
elseif (&term =~ 'rxvt-256color') || (&term =~ 'screen-256color')
    colorscheme inkpot      " Tema para rxvt-256color y screen-256color
elseif (&term =~ 'xterm') || (&term =~ 'xterm-256color')
    colorscheme herald      " Tema para xterm*.
else
    colorscheme blackbeauty " Tema para el resto
endif
"}}}
"{{{   Eventos
"-------------------------------------------------------------------------------
if has("autocmd")
    " Mapeos a F6 para compilar/ejectuar.
    autocmd FileType sh       map <F6> :!bash %<CR>
    autocmd FileType php      map <F6> :!php & %<CR>
    autocmd FileType python   map <F6> :!python %<CR>
    autocmd FileType perl     map <F6> :!perl %<CR>
    autocmd FileType ruby     map <F6> :!ruby %<CR>
    autocmd FileType lua      map <F6> :!lua %<CR>
    autocmd FileType htm,html map <F6> :!firefox %<CR>
    " Releer vimrc al guardar cambios.
    autocmd! BufWritePost .vimrc source %
endif
"}}}
"{{{   Funciones
"-------------------------------------------------------------------------------
if has("eval")
    " Eliminar espacios redundantes.
    fun! StripWhite()
        %s/[ \t]\+$//ge
        %s!^\( \+\)\t!\=StrRepeat("\t", 1 + strlen(submatch(1)) / 8)!ge
    endfun
    " Eliminar líneas en blanco.
    fun! RemoveBlankLines()
        %s/^[\ \t]*\n//g
    endfun
    " Marca en rojo los espacios redundantes.
    highlight RedundantSpaces ctermbg=red guibg=red
    match RedundantSpaces /\s\+$\| \+\ze\t\|\t/
    " Una StatusBar molona para MiniBufExplorer
    fun! <SID>FixMiniBufExplorerTitle()
        if "-MiniBufExplorer-" == bufname("%")
            setlocal statusline=%2*%-3.3n%0*
            setlocal statusline+=\[Buffers\]
            setlocal statusline+=%=%2*\ %<%P
        endif
    endfun
    au BufWinEnter *
                \ let oldwinnr=winnr() |
                \ windo call <SID>FixMiniBufExplorerTitle() |
                \ exec oldwinnr . " wincmd w"
endif
"}}}
"{{{   Plugins
"-------------------------------------------------------------------------------
" MiniBufExplorer
let g:miniBufExplTabWrap        = 1 " make tabs show complete (no broken on two lines)
let g:miniBufExplModSelTarget   = 1 " If you use other explorers like TagList you can (As of 6.2.8) set it at 1:
let g:miniBufExplUseSingleClick = 1 " If you would like to single click on tabs rather than double clicking on them to goto the selected buffer.
" for buffers that have NOT CHANGED and are NOT VISIBLE.
highlight MBENormal guifg=LightBlue
" for buffers that HAVE CHANGED and are NOT VISIBLE
highlight MBEChanged guifg=Red
" buffers that have NOT CHANGED and are VISIBLE
highlight MBEVisibleNormal term=bold cterm=bold gui=bold guifg=Green
" buffers that have CHANGED and are VISIBLE
highlight MBEVisibleChanged term=bold cterm=bold gui=bold guifg=Green
" refresh minibuffeplorer
autocmd BufRead,BufNew,BufWrite :call UMiniBufExplorer
" TagList
let Tlist_Exit_OnlyWindow    = 1 " exit if taglist is last window open
let Tlist_Show_One_File      = 1 " Only show tags for current buffer
let Tlist_Enable_Fold_Column = 0 " no fold column (only showing one file)
let Tlist_Use_Right_Window   = 1 " TagList en la derecha
let Tlist_Compact_Format     = 1 " Modo compacto. No muestra nº de lineas, etc...
let Tlist_Show_Menu          = 1 " En GVim muestra un menu 'Tags'
map <F4> :Tlist<CR>
" NERDTreeMapActivateNodee
let NERDTreeMapActivateNode  = '<CR>'  " Enter abre nodos
map <F3> :NERDTreeToggle<CR>
"}}}
"{{{   Bindings y Extras
"-------------------------------------------------------------------------------
" Leader por defecto es "\"
nmap <leader>sw<left>  :topleft  vnew<CR>
nmap <leader>sw<right> :botright vnew<CR>
nmap <leader>sw<up>    :topleft  new<CR>
nmap <leader>sw<down>  :botright new<CR>
" Abrir nuevo buffer
nmap <leader>s<left>   :leftabove  vnew<CR>
nmap <leader>s<right>  :rightbelow vnew<CR>
nmap <leader>s<up>     :leftabove  new<CR>
nmap <leader>s<down>   :rightbelow new<CR>
" Ctrl-L quita highlights y redibuja la pantalla
nnoremap <C-L> :nohls<CR>
" Cambiamos buffers con F1 y F2 cerrando Nerdtree si está activo
noremap <F1> :NERDTreeClose<CR> :bprev!<CR>
noremap <F2> :NERDTreeClose<CR> :bnext!<CR>
" Smart way to move btw. windows
map <C-j> <C-W>j
map <C-k> <C-W>k
map <C-h> <C-W>h
map <C-l> <C-W>l
" Tab shortcuts
map <leader>tn :tabnew %<cr>
map <leader>te :tabedit
map <leader>tc :tabclose<cr>
map <leader>tm :tabmove
"}}}

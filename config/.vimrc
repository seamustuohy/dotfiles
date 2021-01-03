execute pathogen#infect()
syntax on
filetype plugin indent on

" ----- GENERAL SETTINGS -----
set noerrorbells                " No beeps
set nocompatible                " use vim defaults instead of vi


" Do not show stupid q: window
map q: :q

"----- File Settings -----
filetype off                  " required
filetype plugin indent on    " required
set encoding=utf-8              " always encode in utf
set ruler                       " Show the cursor position all the time
au FocusLost * :wa              " Set vim to save the file on focus out.
set autowrite                   " Automatically save before :next, :make etc.
set autoread                    " Automatically reread changed files without asking me anything
set fileformats=unix,dos,mac    " Prefer Unix over Windows over OS 9 formats


syntax enable
set background=dark
colorscheme solarized

"----- DISPLAY SETTINGS-------
set number                      " Show line numbers
set laststatus=2
set showcmd                     " Show me what I'm typing
set showmode                    " Show current mode.
let g:airline_powerline_fonts = 1
let g:airline_detect_paste=1
let g:airline#extensions#tabline#enabled = 1
let g:airline_theme='solarized'
set background=dark
let g:solarized_termcolors=256

" speed up syntax highlighting
set nocursorcolumn
set nocursorline

" do not hide markdown
set conceallevel=0


" Make Vim to handle long lines nicely.
set wrap
set textwidth=79
set formatoptions=qrn1

" mail line wrapping
au BufRead /tmp/mutt-* set tw=72


" ----- SEARCH SETTINGS -----
set incsearch                   " Shows the match while typing
set hlsearch                    " Highlight found searches
set ignorecase                  " Search case insensitive...
set smartcase                   " ... but not when search pattern contains upper case characters



" ----- MOVEMENT SETTINGS -----
" Move up and down on splitted lines (on small width screens)
map <Up> gk
map <Down> gj
map k gk
map j gj



" Support Settings
:set spell spelllang=en_us



"----- POWERBAR SETTINGS-------
set laststatus=2
let g:airline_powerline_fonts = 1
let g:airline_detect_paste=1
let g:airline#extensions#tabline#enabled = 1
let g:airline_theme='solarized'
set background=dark
let g:solarized_termcolors=256
colorscheme solarized


" ----- vim-better-whitespace -----
" auto strip whitespace except for file with extention blacklisted
let blacklist = ['markdown', 'md']
autocmd BufWritePre * if index(blacklist, &ft) < 0 | StripWhitespace

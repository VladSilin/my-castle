" Vlad's Spicy Vim Config
"
" To use it, copy it to
"     for Unix and OS/2:  ~/.vimrc
"	      for Amiga:  s:.vimrc
"  for MS-DOS and Win32:  $VIM\_vimrc
"	    for OpenVMS:  sys$login:.vimrc

" When started as "evim", evim.vim will already have done these settings.



if v:progname =~? "evim"
  finish
endif

" allow backspacing over everything in insert mode
set backspace=indent,eol,start

set history=50		" keep 50 lines of command line history
set ruler		" show the cursor position all the time
set incsearch		" do incremental searching

" For Win32 GUI: remove 't' flag from 'guioptions': no tearoff menu entries
" let &guioptions = substitute(&guioptions, "t", "", "g")

" Don't use Ex mode, use Q for formatting
map Q gq

" CTRL-U in insert mode deletes a lot.  Use CTRL-G u to first break undo,
" so that you can undo CTRL-U after inserting a line break.
inoremap <C-U> <C-G>u<C-U>

" In many terminal emulators the mouse works just fine, thus enable it.
if has('mouse')
  set mouse=a
endif

" Switch syntax highlighting on, when the terminal has colors
" Also switch on highlighting the last used search pattern.
if &t_Co > 2 || has("gui_running")
  syntax on
endif

" Only do this part when compiled with support for autocommands.
if has("autocmd")

  " Enable file type detection.
  " Use the default filetype settings, so that mail gets 'tw' set to 72,
  " 'cindent' is on in C files, etc.
  " Also load indent files, to automatically do language-dependent indenting.
  filetype plugin indent on

  " Put these in an autocmd group, so that we can delete them easily.
  augroup vimrcEx
  au!

  " For all text files set 'textwidth' to 78 characters.
  autocmd FileType text setlocal textwidth=78

  " When editing a file, always jump to the last known cursor position.
  " Don't do it when the position is invalid or when inside an event handler
  " (happens when dropping a file on gvim).
  " Also don't do it when the mark is in the first line, that is the default
  " position when opening a file.
  autocmd BufReadPost *
    \ if line("'\"") > 1 && line("'\"") <= line("$") |
    \   exe "normal! g`\"" |
    \ endif

  augroup END

else

  set autoindent		" always set autoindenting on

endif " has("autocmd")

" Convenient command to see the difference between the current buffer and the
" file it was loaded from, thus the changes you made.
" Only define it when not defined already.
if !exists(":DiffOrig")
  command DiffOrig vert new | set bt=nofile | r ++edit # | 0d_ | diffthis
		  \ | wincmd p | diffthis
endif




" ****** New Settings Start Here ******
" -------------------------------------

" Set up line numbering
set number


" Set up color scheme
set t_Co=256

" Set Vim-specific sequences for RGB colors
let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"

set background=dark
colorscheme edge


" Tab settings (defaults, vim-sleuth will override per-project)
set expandtab
set shiftwidth=4
set softtabstop=4


" Set advanced autocomplete
set wildmenu


" Set show list of buffers on command 'gb'
nnoremap gb :ls<cr>:b<space>
nnoremap gdb :ls<cr>:bd<space>
nnoremap gvb :ls<cr>:vert sb<space>

" Delete buffer without touching window split
if !exists(":Bd")
  command Bd bp\|bd \#
endif


" Search settings
set hlsearch
set ignorecase
set smartcase

" Show number of matches in search
set shortmess-=S

" Scroll context
set scrolloff=10


" Autosave Buffers
set autowriteall


" Keep buffer undo history
set hidden

" Persistent undo across sessions.
" Vim will not create undodir itself: if it's missing it just drops the undo
" history on exit, with no error and no file left behind, so `set undofile`
" silently does nothing. Create it here so a freshly cloned dotfiles checkout
" works without a manual mkdir. 0700 because undo files hold file contents.
set undofile
set undodir=~/tmp/undodir
if !isdirectory(expand(&undodir))
  call mkdir(expand(&undodir), 'p', 0700)
endif


" netrw (File Tree Browser) Config
let g:netrw_banner = 0
let g:netrw_liststyle = 3
let g:netrw_browse_split = 0


" Terminal Command Setup
set splitbelow
set splitright
nnoremap <leader>t :terminal<cr><C-w>:exe "resize " . (winheight(0) * 2/3)<CR>


" Swap File Location Setup
set swapfile
set dir=~/tmp


" Cursor Line in Edit Mode
" Cursor settings:
"  1 -> blinking block
"  2 -> solid block
"  3 -> blinking underscore
"  4 -> solid underscore
"  5 -> blinking vertical bar
"  6 -> solid vertical bar
" Mode Settings (macOS Default Terminal)
let &t_SI.="\e[5 q" "SI = INSERT mode
let &t_SR.="\e[4 q" "SR = REPLACE mode
let &t_EI.="\e[1 q" "EI = NORMAL mode (ELSE)


" Prevent lag when switching between modes
set timeoutlen=1000
set ttimeoutlen=5


" Proper Indentation on Paste
nnoremap <F2> :set invpaste paste?<CR>


" Save when focus lost
au FocusLost * silent! wa


" Sync clipboard between OS and Vim
set clipboard=unnamed



" Encoding
set encoding=UTF-8



" ****** Plug Plugin Manager Stuff Starts Here ******
" ---------------------------------------------------

call plug#begin('~/.vim/plugged')
" FZF
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" Language Analysis (coc.nvim)
" Install extensions with :CocInstall
"   coc-snippets coc-prettier coc-eslint coc-emmet
"   coc-tsserver coc-pyright coc-json coc-java coc-css
"   coc-html coc-tailwindcss coc-terraform
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" Quality of Life
Plug 'itchyny/lightline.vim'
Plug 'tpope/vim-sleuth'
Plug 'tpope/vim-surround'
Plug 'romainl/vim-cool'

" Git
Plug 'tpope/vim-fugitive'

" File Explorer (enhances built-in netrw)
Plug 'tpope/vim-vinegar'

" Markdown
" https://codeinthehole.com/tips/writing-markdown-in-vim/
Plug 'godlygeek/tabular'
Plug 'preservim/vim-markdown'
call plug#end()


" Lightline Config
set laststatus=2
set noshowmode


" FZF (File Finder) Config
nnoremap <C-p> :Files<CR>
nnoremap <Leader>b :Buffers<CR>
nnoremap <Leader>h :History<CR>


" Git Blame Config (via fugitive)
nnoremap <Leader>s :Git blame<CR>


" Copilot
imap <silent> <C-j> <Plug>(copilot-next)
imap <silent> <C-k> <Plug>(copilot-previous)
imap <silent> <C-\> <Plug>(copilot-dismiss)


" vim-markdown
" Enable folding.
let g:vim_markdown_folding_disabled = 0

" Fold heading in with the contents.
let g:vim_markdown_folding_style_pythonic = 1

" Don't use the shipped key bindings.
let g:vim_markdown_no_default_key_mappings = 1

" Autoshrink TOCs.
let g:vim_markdown_toc_autofit = 1

" Indentation for new lists. We don't insert bullets as it doesn't play
" nicely with `gq` formatting. It relies on a hack of treating bullets
" as comment characters.
" See https://github.com/plasticboy/vim-markdown/issues/232
let g:vim_markdown_new_list_item_indent = 0
let g:vim_markdown_auto_insert_bullets = 0

" Filetype names and aliases for fenced code blocks.
let g:vim_markdown_fenced_languages = ['php', 'py=python', 'js=javascript', 'bash=sh', 'viml=vim']

" Highlight front matter (useful for Hugo posts).
let g:vim_markdown_toml_frontmatter = 1
let g:vim_markdown_json_frontmatter = 1
let g:vim_markdown_frontmatter = 1

" Format strike-through text (wrapped in `~~`).
let g:vim_markdown_strikethrough = 1

" Associate .md with Markdown
au BufNewFile,BufFilePre,BufRead *.md set filetype=markdown

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

" Use Vim settings, rather than Vi settings (much better!).
" This must be first, because it changes other options as a side effect.
set nocompatible

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
"colorscheme jellybeans

" This one is NOT working
"set termguicolors

" Do this instead:
" Set Vim-specific sequences for RGB colors
let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"

set background=dark
colorscheme edge


" Tab settings
set expandtab
set shiftwidth=4
set softtabstop=4


" Set advanced autocomplete
set wildmenu


" Set show list of buffers on command 'gb'
nnoremap gb :ls<cr>:b<space>
nnoremap gdb :ls<cr>:bd<space>

" Delete buffer without touching window split
if !exists(":Bd")
  command Bd bp\|bd \#
endif


" Do not highlight searches
set nohlsearch


" Autosave Buffers
set autowriteall


" netrw (File Tree Browser) Config
let g:netrw_banner = 0
let g:netrw_liststyle = 3
let g:netrw_browse_split = 4
let g:netrw_altv = 1
let g:netrw_winsize = 20
"augroup ProjectDrawer
"    autocmd!
"    autocmd VimEnter * :Vexplore
"    autocmd VimEnter * wincmd l
"augroup END


" Terminal Command Setup
set splitbelow
set splitright
nnoremap <leader>t :terminal<cr><C-w>:exe "resize " . (winheight(0) * 1/3)<CR>


" Swap File Location Setup
set swapfile
" NOTE: This directory must be created manually
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


" Flavored Markdown
augroup Markdown
    au!
    au BufNewFile,BufRead *.md,*.markdown setlocal filetype=ghmarkdown
augroup END


" Proper Indentation on Paste
nnoremap <F2> :set invpaste paste?<CR>
set pastetoggle=<F2>


" Save when focus lost
au FocusLost * silent! wa


" Copy to clipboard easily
noremap <Leader>y "*y
noremap <Leader>p "*p
noremap <Leader>Y "+y
noremap <Leader>P "+p




" ****** Plug Plugin Manager Stuff Starts Here ******
" ---------------------------------------------------

" NOTE: To get the most out of these plugins:
"   - Install the plugins with the Plug plugin manager
"   - Look into setting up coc.nvim properly (to get any desired language server features)
"   (https://github.com/neoclide/coc.nvim)
"   - Get ripgrep and place 
"       export FZF_DEFAULT_COMMAND='rg --files --follow --hidden'
"     into the .bash_profile/.zshrc/etc. to use ripgrep for the fzf file search plugin

call plug#begin('~/.vim/plugged')
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'sheerun/vim-polyglot'
Plug 'dense-analysis/ale'
Plug 'yuttie/comfortable-motion.vim'
Plug 'itchyny/lightline.vim'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'zivyangll/git-blame.vim'
Plug 'preservim/nerdtree'
call plug#end()


" NerdTree Config
" Open NerdTree automatically if no files are specified
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif

" Do not open NerdTree on saved session
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") && v:this_session == "" | NERDTree | endif

" Open NerdTree if a directory is opened
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 1 && isdirectory(argv()[0]) && !exists("s:std_in") | exe 'NERDTree' argv()[0] | wincmd p | ene | exe 'cd '.argv()[0] | endif

" Map Ctrl-N to toggle NerdTree
map <C-n> :NERDTreeToggle<CR>

" Close NerdTree if the only window left is a NerdTree
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

" Set NerdTree size
let g:NERDTreeWinSize = 40


" Lightline Config
set laststatus=2
set noshowmode


" Comfortable Motion (Smooth Scrolling) Config
let g:comfortable_motion_scroll_down_key = "j"
let g:comfortable_motion_scroll_up_key = "k"


" FZP (File Finder) Config
nnoremap <C-p> :Files<CR>
nnoremap <Leader>b :Buffers<CR>
nnoremap <Leader>h :History<CR>


" ALE (Code Format) Config
" Fix files with prettier, and then ESLint.
let b:ale_fixers = ['prettier', 'eslint']
let g:ale_sign_error = '!'
let g:ale_sign_warning = '?'
nmap <F6> <Plug>(ale_fix)


" Git Blame Config
nnoremap <Leader>s :<C-u>call gitblame#echo()<CR>


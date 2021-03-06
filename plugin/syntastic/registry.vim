if exists("g:loaded_syntastic_registry")
    finish
endif
let g:loaded_syntastic_registry=1

let s:defaultCheckers = {
        \ 'c': ['gcc'],
        \ 'cpp': ['gcc'],
        \ 'java': ['javac'],
        \ 'objc': ['gcc'],
        \ 'php': ['php', 'phpcs', 'phpmd'],
        \ 'ruby': ['mri']
    \ }

let g:SyntasticRegistry = {}

" Public methods {{{1

function! g:SyntasticRegistry.Instance()
    if !exists('s:SyntasticRegistryInstance')
        let s:SyntasticRegistryInstance = copy(self)
        let s:SyntasticRegistryInstance._checkerMap = {}
    endif

    return s:SyntasticRegistryInstance
endfunction

function! g:SyntasticRegistry.CreateAndRegisterChecker(args)
    let checker = g:SyntasticChecker.New(a:args)
    let registry = g:SyntasticRegistry.Instance()
    call registry.registerChecker(checker)
endfunction

function! g:SyntasticRegistry.registerChecker(checker)
    let ft = a:checker.filetype()

    if !has_key(self._checkerMap, ft)
        let self._checkerMap[ft] = []
    endif

    call add(self._checkerMap[ft], a:checker)
endfunction

function! g:SyntasticRegistry.checkable(filetype)
    return !empty(self.getActiveCheckers(a:filetype))
endfunction

function! g:SyntasticRegistry.getActiveCheckers(filetype)
    let checkers = self.availableCheckersFor(a:filetype)

    if self._userHasFiletypeSettings(a:filetype)
        return self._filterCheckersByUserSettings(checkers, a:filetype)
    endif

    if has_key(s:defaultCheckers, a:filetype)
        let checkers = self._filterCheckersByDefaultSettings(checkers, a:filetype)

        if !empty(checkers)
            return checkers
        endif
    endif

    let checkers = self.availableCheckersFor(a:filetype)

    if !empty(checkers)
        return [checkers[0]]
    endif

    return []
endfunction

" Private methods {{{1

function! g:SyntasticRegistry.availableCheckersFor(filetype)
    let checkers = copy(self._allCheckersFor(a:filetype))
    return self._filterCheckersByAvailability(checkers)
endfunction

function! g:SyntasticRegistry._allCheckersFor(filetype)
    call self._loadCheckers(a:filetype)
    if empty(self._checkerMap[a:filetype])
        return []
    endif

    return self._checkerMap[a:filetype]
endfunction

function! g:SyntasticRegistry._filterCheckersByDefaultSettings(checkers, filetype)
    if has_key(s:defaultCheckers, a:filetype)
        let whitelist = s:defaultCheckers[a:filetype]
        return filter(a:checkers, "index(whitelist, v:val.name()) != -1")
    endif

    return a:checkers
endfunction

function! g:SyntasticRegistry._filterCheckersByUserSettings(checkers, filetype)
    let whitelist = g:syntastic_{a:filetype}_checkers
    return filter(a:checkers, "index(whitelist, v:val.name()) != -1")
endfunction

function! g:SyntasticRegistry._filterCheckersByAvailability(checkers)
    return filter(a:checkers, "v:val.isAvailable()")
endfunction

function! g:SyntasticRegistry._loadCheckers(filetype)
    if self._haveLoadedCheckers(a:filetype)
        return
    endif

    exec "runtime! syntax_checkers/" . a:filetype . "/*.vim"

    if !has_key(self._checkerMap, a:filetype)
        let self._checkerMap[a:filetype] = []
    endif
endfunction

function! g:SyntasticRegistry._haveLoadedCheckers(filetype)
    return has_key(self._checkerMap, a:filetype)
endfunction

function! g:SyntasticRegistry._userHasFiletypeSettings(filetype)
    return exists("g:syntastic_" . a:filetype . "_checkers")
endfunction

" vim: set sw=4 sts=4 et fdm=marker:

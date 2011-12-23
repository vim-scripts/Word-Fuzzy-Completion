" -*- coding: utf-8 -*-"
" author: jonatan alexis anauati (barakawins@gmail.com) "
" version: 0.5. "

if !has('python')
    finish
endif

function! PythonWordFuzzyCompletion(base)
python << EOF
import sys
import string
import vim

MAX_RESULTS=vim.eval('g:fuzzywordcompletion_maxresults')
transtable = vim.eval('g:fuzzywordcompletion_completiontable')
if not transtable:
    nosplitchars=string.letters+'_'
    deletechars =''.join((chr(c) for c in range(0,256) if chr(c) not in nosplitchars))
    transtable = string.maketrans(deletechars,' '*len(deletechars))

def levenshtein(a,b):
    #from http://hetland.org/coding/python/levenshtein.py
    "Calculates the Levenshtein distance between a and b."
    n, m = len(a), len(b)
    if n > m:
        # Make sure n <= m, to use O(min(n,m)) space
        a,b = b,a
        n,m = m,n
    current = range(n+1)
    for i in range(1,m+1):
        previous, current = current, [i]+[0]*n
        for j in range(1,n+1):
            add, delete = previous[j]+1, current[j-1]+1
            change = previous[j-1]
            if a[j-1] != b[i-1]:
                change = change + 1
            current[j] = min(add, delete, change)
    return current[n]

def completion(word):
    file('/tmp/fuzzy.txt','w').write(word)
    results=[]
    distances = None
    distances_1 = {}
    distances_2 = {}
    try:
        first_char=word[0].lower()
    except:
        first_char=''
    word_len=len(word)
    word_lower=word.lower()
    endwalk=False
    for line in vim.current.buffer:
        for w in line.translate(transtable).split():
            wl=w.lower()
            if wl.startswith(word_lower[0:len(word_lower)]):
                results.append(w)
                if len(results) >MAX_RESULTS:
                    endwalk=True
                    break
            else:
                if wl.startswith(first_char):
                    distances=distances_1
                    distances_2={}
                elif not distances_1:
                    distances=distances_2
                if distances!=None:
                    w_len=len(w)
                    if word_len < w_len:
                        #w_len=word_len+int((word_len-w_len)/2)
                        w_len=word_len
                    d = levenshtein(w[0:w_len],word)
                    try:
                        distancesList=distances[d]
                    except:
                        distancesList =[]
                        distances[d]=distancesList
                    distancesList.append(w)
                distances=None
        if endwalk:
            break
    if distances_1:
        distances=distances_1
    else:
        distances=distances_2
    results.sort(lambda a,b: (0 if len(a)==len(b) else {True:-1,False:1}[len(a) < len(b)]))
    keys=list(distances.keys())
    keys.sort()
    fuzzylen=int(MAX_RESULTS)-len(results)
    if fuzzylen >=0:
        for k in keys:
            distancesList=distances[k]
            results.extend(distancesList)
            del distances[k]
            if len(results) >= MAX_RESULTS:
                #TODO: implement a delete function with better performance.
                results=results[0:MAX_RESULTS]
                break
    return results

base=vim.eval('a:base')
vim.command('let g:fuzzyret='+str(completion(base)))
EOF
    return g:fuzzyret
endfunction

function! FuzzyWordCompletion(findstart, base)
    if a:findstart
        let line = getline('.')
        let start = col('.') - 1
        while start > 0 && line[start - 1] =~ '\a\|_'
            let start -= 1
        endwhile
        return start
    else
        return PythonWordFuzzyCompletion(a:base)
    endif
endfunction

if !exists("g:fuzzywordcompletion_maxresults")
    let g:fuzzywordcompletion_maxresults=10
endif

if !exists("g:fuzzywordcompletion_completiontable")
    let g:fuzzywordcompletion_completiontable=''
endif

set completefunc=FuzzyWordCompletion
imap <C-k> <C-x><C-u>

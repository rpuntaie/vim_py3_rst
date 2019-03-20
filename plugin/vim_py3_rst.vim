" encoding: utf-8 

py3 << EOF

import vim
import types
import os
import doctest 
from timeit import timeit
from pathlib import Path
from itertools import tee

#py3 related: 
#  eval current range or line in python, print to stdout or __pyout__ and remember in "*"
__name__ = "__vim__"
def file_to_name(fl):
    for x in reversed(fl.split(os.sep)[1:]):
        if x in sys.modules:
            break
    else:
        x = os.path.normpath(os.path.expanduser('~')).split(os.sep)[-1]
    try:
        rst = fl.split(os.sep+x+os.sep)[1][:-3]
        return (x+'.'+rst).replace(os.sep,'.').strip('.')
    except:
        return fl.split(os.sep)[-1][:-3]
def py3_get_pyout(): 
    pyout = [b for b in vim.buffers if b.name and b.name.find('__pyout__')!=-1]
    if pyout: 
        wnd=[(w,i) for i,w in enumerate(vim.windows) if w.buffer.name == pyout[0].name]
        if wnd:
            pyout = (pyout[0],wnd[0][0],wnd[0][1]+1)
    return pyout
def py3_print_result_in_vim(expr, result): 
    if isinstance(result,types.GeneratorType):
        res_str = str(list(tee(result)))
    else:
        res_str = str(result)
    try:
        vimc = u'setreg("*","{0}")'.format(
          res_str.replace('\\','\\\\').replace('"','\\"'))
        vim.eval(vimc)
    except: pass
    pyout=py3_get_pyout()
    if pyout:
        res_out=['>>> '+e for e in expr.splitlines()]+res_str.splitlines()+['']
        pyout[0].range(0,0).append(res_out)
        pyout[1].cursor = (1,0)
        vim.command('exe {0} . "wincmd w"'.format(pyout[2]))
        vim.command("normal gg")
        vim.command("wincmd p")
    else:
        print(res_str)
def vim_current_range(): 
    c_r=vim.current.range
    if not c_r:
        c_r=[vim.current.line]
    b = (0,0)
    e = (0,-1)
    if len(c_r)==1:
        b = vim.current.buffer.mark('<')   
        e = vim.current.buffer.mark('>')
    if b and e and getattr(
          c_r,'start',-2)+1 == b[0] and b[1] <= e[1] and e[1] < len(c_r[0]):
        if vim.eval('&selection')=='exclusive':
            from_to = b[1],e[1]
        else:
            from_to = b[1],e[1]+1
        rngstr = c_r[0][from_to[0]:from_to[1]]
        rngstr = rngstr
    else:
        from_to = None
        t = c_r[0]
        i = t.find(t.strip(' >#.%,\t'))
        rngstr = '\n'.join([ln[i:] for ln in c_r])
    return rngstr, from_to
def py3_eval(code):
    eval(compile(
        '__file__ = r"%s"'%vim.current.buffer.name.replace('\\','/')
        ,'<string>','exec'),globals()
        )
    eval(compile(code,'<string>','exec'),globals())
def py3_eval_current_range(): 
    rngstr,_ = vim_current_range()
    py3_eval(rngstr)
def py3_ready_for_eval(line):
    conditional=re.compile(
        r'(\s*def\s+|\s*if\s+|\s*elif\s+|\s*while\s+|\s*for\s+[\w,\s]+in\s+)(.*)(:.*)')
    cm = conditional.match(line)
    if cm:
        toeval =  cm.group(2)
    else:
        toeval =  line.replace('return ','').replace('yield ',''
          ).replace('continue','pass').replace('break','pass')
    return 'py_res ='+toeval
def make_py_res(rngstr):
    rl = rngstr.splitlines()
    if rl[-1][0] != ' ':
        rl[-1] = py3_ready_for_eval(rl[-1])
    else:
        rl[0] = py3_ready_for_eval(rl[0])
    return '\n'.join(rl)
def py3_print_current_range(): 
    rngstr,_ = vim_current_range()
    try: 
        py3_eval(make_py_res(rngstr))
        result = eval("py_res",globals())
    except: 
        py3_eval(rngstr)
        result = None
    py3_print_result_in_vim(rngstr,result)
def py3_doctest_current_range(): 
    rngstr,_ = vim_current_range()
    test = doctest.DocTestParser().get_doctest(rngstr,globals(), 'vimv', None, 0)
    runner = doctest.DocTestRunner(optionflags=doctest.ELLIPSIS|doctest.IGNORE_EXCEPTION_DETAIL)
    runner.run(test,out=sys.stdout.write)
    py3_print_result_in_vim(rngstr,runner.summarize())
def py3_timeit():
    rngstr,_ = vim_current_range()
    tim = timeit(rngstr,'\n'.join(vim.current.buffer),number=1000)
    py3_print_result_in_vim('timeit('+rngstr+')',tim)

#template using bottle SimpleTemplate (stpl)

import stpl

template_stdout = []
def py3_expand_stpl():
    rngstr,from_to = vim_current_range()

    d = os.path.dirname
    tpl = stpl.SimpleTemplate(source=rngstr
        ,lookup=[os.getcwd(),d(vim.current.buffer.name),d(d(vim.current.buffer.name))])
    env = {}
    env.update(globals())
    env['__file__']=vim.current.buffer.name
    del template_stdout[:]
    newenv = tpl.execute(template_stdout,env)
    fl = None
    try:
        fl = globals()['__file__']
    except: pass
    globals().update(newenv)
    if fl:
        globals()['__file__'] = fl

    t = ''.join(template_stdout)
    if from_to:
        res = vim.current.range[0][:from_to[0]]+t+vim.current.range[0][from_to[1]:]
        vim.current.range[:] = res.splitlines()
    else:
        vim.current.range[:] = t.splitlines()

#rst related
try:
    from rstdoc.retable import reformat_table, reflow_table, re_title, get_bounds, title_some
    from rstdoc.dcx import index_dir, convert_in_tempdir, startfile, rexkw, grep, yield_with_kw, rindices
    from rstdoc.listtable import gridtable
    from rstdoc.reflow import reflow
    from rstdoc.untable import untable
    from rstdoc.retable import retable
except ModuleNotFoundError:
    print('Do "pip install rstdoc" (version 1.7.0) to make this work')
    raise
def ReformatTable():
    row,col = vim.current.window.cursor
    reformat_table(vim.current.buffer,row-1,col-1,1)
def ReflowTable():
    row,col = vim.current.window.cursor
    reflow_table(vim.current.buffer,row-1,col-1)
def ReTitle(down=0):
    row,col = vim.current.window.cursor
    re_title(vim.current.buffer,row-1,col-1,down)
def _header(chr):
    #chr='='
    pos=vim.current.window.cursor[0]-1
    cline=vim.current.buffer[pos]
    rcline=cline.rstrip()
    scline=cline.strip()
    indent=' '*(len(rcline)-len(scline))
    return pos,rcline,indent+chr*len(scline)
def UnderLine(chr):
    pos,rcline,tline = _header(chr)
    vim.current.buffer[pos:pos+1] = [rcline,tline]
def TitleLine(chr):
    pos,rcline,tline = _header(chr)
    vim.current.buffer[pos:pos+1] = [tline,rcline,tline]
def RstIndex():
    index_dir()
    tags=','.join([str(x.absolute()) for x in Path('.').glob("**/.tags")])
    vim.eval('''execute("set tags=./.tags,.tags,'''+tags.replace('\\','/')+'")')
def ListTable(join):
    c_r=vim.current.range
    lt = list(gridtable(c_r[:],join))
    vim.current.buffer[c_r.start:c_r.end+1] = lt
def ReFlow(join,sentence):
    c_r=vim.current.range
    lt = list(reflow(c_r[:],join,sentence))
    vim.current.buffer[c_r.start:c_r.end+1] = lt
def UnTable():
    c_r=vim.current.range
    lt = list(untable(c_r[:]))
    vim.current.buffer[c_r.start:c_r.end+1] = lt
def ReTable():
    c_r=vim.current.range
    lt = list(retable(c_r[:]))
    vim.current.buffer[c_r.start:c_r.end+1] = lt
#find in tag lines of format .. {tag1, tag2,...}
def vim_query_kws (query,fn_ln_kw=None,ask=True):
    #query = 'a'
    #fn_ln_kw = [('a/b',1,'a b'),('c/d',1,'c d')]
    i_kws = list(yield_with_kw(query,fn_ln_kw))
    qf = [{'filename':e[0].replace('\\\\','\\'),'lnum':e[1]} for i,e in i_kws]
    vim.eval('setqflist({0})'.format(str(qf)))
    if ask:
        qflen=len(qf)
        if qflen == 0:
            return 0
        ch = 1
        if qflen > 1:
            for i,(_,e) in enumerate(i_kws):
                print("{0}. {1}".format(i+1,e[2].strip(' .')))
            choice = vim.eval('input("choose via index:")')
            try:
                ch = int(choice)
            except:
                return
        vim.command('cc %i'%ch)
def vim_local_arg_ask_kws(*args):
    fn = vim.eval('expand("%:p")')
    vim_query_kws(
        query = args and ','.join(args) or vim.current.line,
        fn_ln_kw = [(fn,l+1,vim.current.buffer[l]) for l in rindices(rexkw,vim.current.buffer)]
        )
def vim_rst_arg_ask_kws(*args):
    vim_query_kws(args and ','.join(args) or vim.current.line)

import webbrowser as wb
for brwsrname in [None,'firefox','chrome','chromium','safari']:
    try:
        browser = wb.get(brwsrname)
    except: 
        continue
    if browser:
        break
from time import sleep
from docutils.core import publish_string
from tempfile import mkdtemp,mkstemp
import os
__confdir = os.path.expanduser('~')
__tmpdir = os.path.join(__confdir,'tmp')
def Show(
    outinfo='rst_html' #docx, ... , rst_html, ...  eps, svg, ...
    ):
    rngstr,_ = vim_current_range()
    if '\n' not in rngstr:
        lns = vim.current.buffer
    else:
        lns = rngstr.splitlines()
    outfile = convert_in_tempdir(lns,outinfo=outinfo)
    if outfile.endswith('.html') and browser:
        browser.open(outfile)
    else:
        startfile(outfile)

#titles
vim.command("nnoremap <silent> <leader>h1 :T#<CR>")
vim.command("noremap <silent> <leader>h2 :T*<CR>")
for i,x in enumerate(title_some):
    vim.command("nnoremap <silent> <leader>h{} :U{}<CR>".format(3+i,x))

EOF

"Create a python output buffer
function! PyOut()
    let cwn = winnr()
    let id = '__pyout__'
    if bufwinnr(id) != -1
        exec 'noautocmd keepalt keepj' bufwinnr(id) 'wincmd w'
    else
        let bn = bufnr(id)
        let wpos = 'botright vertical'
        if bn != -1
            let wn = bufwinnr(bn)
            if wn != -1
                exec 'noautocmd keepalt keepj' (wn .'wincmd w')
            else
                let cmd = wpos.' sbuffer!'
                silent exec 'noautocmd keepalt keepj' cmd bn
            endif
        else
            let cmd = wpos.' split'
            silent exec 'noautocmd keepalt keepj' cmd id
        endif
        setlocal buftype=nofile
        setlocal noswapfile
        setlocal nobuflisted
        setlocal foldmethod=manual
        setlocal foldcolumn=0
        setlocal nospell
        setlocal modifiable
        setlocal noreadonly
    endif
    exec cwn.'wincmd w'
endf

command! -narg=0 PyOut call PyOut()
map <silent> <leader>jw :PyOut<CR>

if has("autocmd")
    autocmd BufEnter *.py :py3 __file__ = vim.current.buffer.name
    autocmd BufEnter *.py :py3 __name__ = file_to_name(vim.current.buffer.name)
    autocmd BufEnter *.py :map <leader>jt :py3 py3_timeit()<CR>
endif

vnoremap <silent> <leader>lh :py3 Show()<CR>
noremap <silent> <leader>lh :py3 Show()<CR>

map <silent> <leader>jj :py3 py3_print_current_range()<CR>
map <silent> <leader>jk :py3 py3_eval_current_range()<CR>
map <silent> <leader>je :py3 py3_expand_stpl()<CR>
map <silent> <leader>jd :py3 py3_doctest_current_range()<CR>

nnoremap <silent> <leader>etf :py3 ReformatTable()<CR>
nnoremap <silent> <leader>etr :py3 ReflowTable()<CR>
nnoremap <silent> <leader>ett :py3 ReTitle()<CR>
nnoremap <silent> <leader>etu :py3 ReTitle(-1)<CR>
nnoremap <silent> <leader>etd :py3 ReTitle(1)<CR>

command! -narg=1 U py3 UnderLine(<f-args>) 
command! -narg=1 T py3 TitleLine(<f-args>) 

":Ck ==> list keyword lines of current file, containing arg words
":CK ==> list keywords in all rst and py files under current dir
"use current line if without parameters
command! -narg=* Ck py3 vim_local_arg_ask_kws(<f-args>) 
command! -narg=* CK py3 vim_rst_arg_ask_kws(<f-args>)


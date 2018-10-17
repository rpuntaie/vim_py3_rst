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
    from rstdoc.dcx import main as dcx
    from rstdoc.listtable import gridtable
    from rstdoc.reflow import reflow
    from rstdoc.untable import untable
    from rstdoc.retable import retable
except ModuleNotFoundError:
    print('Do "pip install rstdoc" to make this work')
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
def RstDcxInit():
    dcx(root='.',verbose=False)
def RstDcx():
    dcx(root=None,verbose=False)
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

#preview rst in browser
import webbrowser as wb
for brwsrname in [None,'firefox','chrome','chromium','safari']:
    try:
        browser = wb.get(brwsrname)
    except: 
        continue
    if browser:
        break
#if not browser:
#    if 'win' in sys.platform:
#        wb.register('chrome',None,wb.BackgroundBrowser('C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe'))
#    else:
#        wb.register('chrome',None,wb.BackgroundBrowser('/usr/bin/chromium'))
#    browser = wb.get('chrome')
from time import sleep
from docutils.core import publish_string
from tempfile import mkdtemp,mkstemp
import os
__confdir = os.path.expanduser('~')
__tmpdir = os.path.join(__confdir,'tmp')
def ShowHtml(rst=None):
    rngstr,_ = vim_current_range()
    if '\n' not in rngstr:
        rngstr = '\n'.join(vim.current.buffer)
    if not rst:
        rst = '.. default-role:: math\n\n' + rngstr
    html = publish_string(rst,writer_name='html')
    fd, temp_path = mkstemp(suffix='.html',dir=__tmpdir)
    os.write(fd,html)
    os.close(fd)
    browser.open(temp_path)
    #sleep(0.5)
    #os.remove(temp_path)
    return html
def ShowSphinx(rst=None):
    """
    sphinx-build -b singlehtml -d _build/doctrees -c <path to conf.py> -D master_doc=<file w/o rst> . _build/html <file.rst>
    sphinx-build -b latex -d _build/doctrees -c <path to conf.py> -D master_doc=<file w/o rst> . _build/latex <file.rst>
    """
    from sphinx.application import Sphinx
    srcdir = mkdtemp(prefix='tmp_',dir=__tmpdir)
    try:
        os.makedirs(srcdir)
    except FileExistsError:
        pass
    fdrst, tmprst = mkstemp(suffix='.rst',prefix='tmp_',dir=srcdir)
    if rst is None:
        rst,_ = vim_current_range()
        if '\n' not in rst:
            rst = None
    if rst is None:
        vim.command('w! '+tmprst)
    else:
        os.write(fdrst,rst.encode())
    os.close(fdrst)
    outdir = os.path.join(srcdir,'_build','html')
    doctreedir = os.path.join(srcdir,'_build','doctrees')
    fn = os.path.split(tmprst)[1]
    fnnoext = os.path.splitext(fn)[0]
    confoverrides = {'master_doc':fnnoext}
    confdir = __confdir
    if os.path.exists('conf.py'):
        confdir = os.getcwd()
    app = Sphinx(srcdir, confdir, outdir, doctreedir,'html',
                 confoverrides, None, None, None,
                 None, [], 0, 1)
    app.build()
    browser.open(os.path.join(outdir,fnnoext+'.html'))

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

vnoremap <silent> <leader>lh :py3 ShowHtml()<CR>
noremap <silent> <leader>lh :py3 ShowHtml()<CR>
vnoremap <silent> <leader>lx :py3 ShowSphinx()<CR>
noremap <silent> <leader>lx :py3 ShowSphinx()<CR>

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



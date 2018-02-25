.. encoding: utf-8 

``vim_py3_rst`` provides shortcuts and utility functions 

- for Vim's ``:py3``

- to edit restructedText (.rst,.rest files)

``vim_py3_rst`` depends on the python package `rstdoc`_.

**rstdoc**

- ``:py3 RstDcxInit()``: sample ``rstdoc`` folder (same as ``rstdcx --init``)
- ``:py3 RstDcx()``: update link and tag files for '.rest' files in all subdirectories
  (same as ``rstdcx``).

**From cursor postion**:

- ``ReformatTable`` creates table from e.g. double space separated format
- ``ReflowTable`` adapts table to new first line
- ``ReTitle`` fixes the header underlines
- ``UnderLine`` and ``TitleLine`` add underline or title lines

Access these via e.g. these vimrc maps::

  " let mapleader = ","
  nnoremap <silent> <leader>etf :py3 ReformatTable()<CR>
  nnoremap <silent> <leader>etr :py3 ReflowTable()<CR>
  nnoremap <silent> <leader>ett :py3 ReTable()<CR>
  command! -narg=1 U py3 UnderLine(<f-args>) 
  command! -narg=1 T py3 TitleLine(<f-args>) 

Example::

      Column 1  Column 2
      Foo    Put two (or more) spaces as a field separator.
      |Bar|  Even very very long lines |like| these are fine, as long as you do not put in line endings here.
      Qux    This is the last line.

``,etf`` should reformat to::

      +----------+----------------------------------------------------------+
      | Column 1 | Column 2                                                 |
      +==========+==========================================================+
      | Foo      | Put two (or more) spaces as a field separator.           |
      +----------+----------------------------------------------------------+
      | |Bar|    | Even very very long lines |like| these are fine, as long |
      |          | as you do not put in line endings here.                  |
      +----------+----------------------------------------------------------+
      | Qux      | This is the last line.                                   |
      +----------+----------------------------------------------------------+

Change the number of "-" in the top line,
then ``,etr`` should adapt the rest to those widths.

**For a range** (you visually select, then do ``:'<,'> py3 Xxx(args)``):

- ``ListTable``: convert grid tables to list-table
- ``ReFlow``: reflow gridtables and paragraphs
- ``UnTable``: 2 or 3 column listtables to paragraphs (1st column is ID (no blanks))
- ``ReTable``: transform listtable to gridtable

.. _`rstdoc`: https:\\github.com\rpuntaie\rstdoc

.. encoding: utf-8 

vim_py3_rst
===========

``vim_py3_rst`` provides shortcuts and utility functions 

- for Vim's ``:py3``

- to edit ``reStructuredText`` (``.rest`` for main docs, ``.rst`` for included files)

``vim_py3_rst``'s purpose is to provide the functionality of the python package
`rstdoc`_. 

Python, .py3
------------

Since Vim has Python 3 embedded one can use all of Python directly
from within Vim. 
This allows to immediately run and thus test code you write.

These mappings apply either to the visual area (can also be within one line)
or the current line.

``<leader>jj``: evaluate and print 
  
  If there is a ``__pyout__`` buffer (``:PyOut`` or ``<leader>jw``),
  then printing goes to that buffer.

``<leader>jk``: only evaluate

``<leader>je``: expand bottle `SimpleTemplate`_

``<leader>jd``: evaluate the `doctest`_ in the visual range

``<leader>jt``: profile the selected code using ``timeit`` (within a ``.py`` file)

.. note::

  If the visual selection starts with a comment char, 
  the block is trimmed beyond the comment char before evaluation.

  This allows to evaluate commented code, but for
  mixed comments and code, the first line must not be a comment.
  It can be an empy line. 

  `` >#.%,\\t`` are comment chars.

  ``return``, ``yield``, ... are skipped, if evaluating only one line.

See details in `vim_py3_rst`_.

reStructuredText, RST
---------------------

The functions are implemented using Python, not ``vimscript``,
i.e. you do ``:'<,'> py3 Xxx(args)`` in Vim.

See `vim_py3_rst`_ for the mappings. 

Title
`````

Title underline within one ``.rest`` must be consistent, otherwise it does not matter.
``<leader>etx`` with ``x∈{1,..,f}`` helps keep the consistency.
The order is partly taken from `atom-rst-snippets`_.
All possibilities are in `ReTable`_.

Tables
``````

These use the cursor position, not the visual selection.

- ``ReformatTable`` creates table from e.g. double space separated format
- ``ReflowTable`` adapts table to new first line
- ``ReTitle`` fixes the header underlines
- ``UnderLine`` and ``TitleLine`` add underline or title lines

The implementation is in `ReTable`_.

Example::

      Column 1  Column 2
      Foo    Put two (or more) spaces as a field separator.
      |Bar|  Even very very long lines |like| these are fine, as long as you do not put in line endings here.
      Qux    This is the last line.

``,etf`` reformats it to::

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
then ``,etr`` adapts the rest to those widths.

Reformat a range of RST
```````````````````````

You visually select, then do ``:'<,'> py3 Xxx(args)``):

- `ListTable`_: convert grid tables to list table
- `ReFlow`_: re-flow grid tables and paragraphs
- `UnTable`_: convert 2- or 3-column.list tables to paragraphs (1st column is ID, i.e. no blanks)
- `ReTable`_: transform list table to grid table

Set of .rest documentation
``````````````````````````

These apply to the current directory, not a buffer.

- `RstDcxInit`_: Create a sample documentation folder. Same as ``rstdcx --init``.
- `RstDcx`_: Update `.tags` and link files for '.rest' files in all subdirectories.
  It also generates documentation from other files (see `dcx`_).
  Same as ``rstdcx``.

Preview
```````

Preview can be done either on the visual selection or on the whole document.

- `ShowHtml`_ uses `Docutils`_ (``<leader>lh``) 
- `ShowSphinx`_ uses `Sphinx`_   (``<leader>lx``) 

.. note:: This is still work in progress.

.. _`rstdoc`: https:\\github.com\rpuntaie\rstdoc
.. _`vim_py3_rst`: https://github.com/rpuntaie/vim_py3_rst/blob/master/plugin/vim_py3_rst.vim
.. _`ListTable`: https://github.com/rpuntaie/rstdoc/blob/master/rstdoc/listtable.py
.. _`ReFlow`: https://github.com/rpuntaie/rstdoc/blob/master/rstdoc/reflow.py
.. _`UnTable`: https://github.com/rpuntaie/rstdoc/blob/master/rstdoc/untable.py
.. _`ReTable`: https://github.com/rpuntaie/rstdoc/blob/master/rstdoc/retable.py
.. _`dcx`: https://github.com/rpuntaie/rstdoc/blob/master/rstdoc/dcx.py
.. _`RstDcxInit`: https://github.com/rpuntaie/rstdoc
.. _`RstDcx`: https://github.com/rpuntaie/rstdoc
.. _`ShowHtml`: https://github.com/rpuntaie/vim_py3_rst/blob/master/plugin/vim_py3_rst.vim
.. _`ShowSphinx`: https://github.com/rpuntaie/vim_py3_rst/blob/master/plugin/vim_py3_rst.vim

.. _`atom-rst-snippets`: https://github.com/jimklo/atom-rst-snippets
.. _`vimscript`: http://vimdoc.sourceforge.net/htmldoc/usr_41.html

.. _`Docutils`: http://docutils.sourceforge.net/
.. _`Sphinx`: http://www.sphinx-doc.org/en/stable/

.. _`doctest`: https://docs.python.org/3.6/library/doctest.html

.. _`SimpleTemplate`: https://bottlepy.org/docs/dev/stpl.html#simpletemplate-syntax


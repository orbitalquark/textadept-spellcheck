# Spellcheck

Spell checking for Textadept.

Install this module by copying it into your *~/.textadept/modules/* directory or Textadept's
*modules/* directory, and then putting the following in your *~/.textadept/init.lua*:

```lua
local spellcheck = require('spellcheck')
```

There will be a "Tools > Spelling" menu. Textadept automatically spell checks the buffer
each time it is saved, highlighting any misspelled words in plain text, comments, and
strings. These options can be configured via [`spellcheck.check_spelling_on_save`](#spellcheck.check_spelling_on_save) and
[`spellcheck.spellcheckable_styles`](#spellcheck.spellcheckable_styles), respectively. Left-clicking (not right-clicking) on
misspelled words shows suggestions.

By default, Textadept attempts to load a preexisting [Hunspell][] dictionary for the
detected locale. If none exists, or if the locale is not detected, Textadept falls back
on its own prepackaged US English dictionary. Textadept searches for dictionaries in
[`spellcheck.hunspell_paths`](#spellcheck.hunspell_paths). User dictionaries are located in the *~/.textadept/dictionaries/*
directory, and are loaded automatically.

Dictionary files are Hunspell dictionaries and follow the Hunspell format: the first line
in a dictionary file contains the number of entries contained within, and each subsequent
line contains a word.

[Hunspell]: https://hunspell.github.io/

## Compiling

Releases include binaries, so building this modules should not be necessary. If you want
to build manually, use CMake. For example:

```bash
cmake -S . -B build_dir
cmake --build build_dir
cmake --install build_dir
```

## Key Bindings

Windows and Linux | macOS | Terminal | Command
-|-|-|-
**Tools**| | |
Ctrl+: | ⌘: | M-: | Check spelling interactively
Ctrl+; | ⌘; | M-; | Mark misspelled words

<a id="spellcheck.INDIC_SPELLING"></a>
## `spellcheck.INDIC_SPELLING`

The spelling error indicator number.

<a id="_G.spell"></a>
## `_G.spell`(*aff*, *dic*[, *key*])

Returns a Hunspell spellchecker.

This is a low-level function. You probably want to use the higher-level [`spellcheck.load()`](#spellcheck.load).

Parameters:
- *aff*:  String path to the Hunspell affix file to use.
- *dic*:  String path to the Hunspell dictionary file to use.
- *key*:  String key for encrypted *dic*.

Usage:

```lua
spellchecker = spell('/usr/share/hunspell/en_US.aff', '/usr/share/hunspell/en_US.dic')
spellchecker:spell('foo') --> false
```

<a id="spellcheck.check_spelling"></a>
## `spellcheck.check_spelling`([*interactive*=false[, *wrapped*]])

Checks the buffer for any spelling errors and marks them.

Parameters:
- *interactive*:  Display suggestions for the next misspelled word.
- *wrapped*:  Utility flag that indicates whether or not the spellchecker has
	wrapped for displaying useful statusbar information. This flag is used and set internally,
	and should not be set otherwise.

<a id="spellcheck.check_spelling_on_save"></a>
## `spellcheck.check_spelling_on_save`

Check spelling after saving files.

The default value is `true`.

<a id="spellcheck.hunspell_paths"></a>
## `spellcheck.hunspell_paths`

List of paths to search for Hunspell dictionaries in.

<a id="spellcheck.load"></a>
## `spellcheck.load`(*lang*)

Loads a language into the spellchecker.

Parameters:
- *lang*:  String Hunspell language name to load.

Usage:

```lua
spellcheck.load('en_US')
```

<a id="spellcheck.misspelled_color_name"></a>
## `spellcheck.misspelled_color_name`

The name of the theme color used to mark misspelled words.

The default value is 'red'. If your theme does not define that color, set this field to your
theme's equivalent.

<a id="spellcheck.spellcheckable_styles"></a>
## `spellcheck.spellcheckable_styles`

Map of spellcheckable style names to `true`.

Text with any of these styles is eligible for spellchecking.

The default styles are `lexer.DEFAULT`, `lexer.COMMENT`, and `lexer.STRING`.

Usage:

```lua
spellcheck.spellcheckable_styles[lexer.HEADING] = true
```

<a id="spellcheck.spellchecker"></a>
## `spellcheck.spellchecker`

The Hunspell spellchecker object.

<a id="spellchecker.add_dic"></a>
## `spellchecker:add_dic`(*dic*)

Adds words from a dictionary file to the spellchecker.

Parameters:
- *dic*:  String path to the Hunspell dictionary file to load.

<a id="spellchecker.add_word"></a>
## `spellchecker:add_word`(*word*)

Adds a word to the spellchecker.

Note: this is not a permanent addition. It only persists for the life of this spellchecker
and applies only to this spellchecker.

Parameters:
- *word*:  String word to add.

<a id="spellchecker.get_dic_encoding"></a>
## `spellchecker:get_dic_encoding`()

Returns the dictionary's string encoding.

<a id="spellchecker.spell"></a>
## `spellchecker:spell`(*word*)

Returns whether or not a word is spelled correctly.

Parameters:
- *word*:  String word to check spelling of.

<a id="spellchecker.suggest"></a>
## `spellchecker:suggest`(*word*)

Returns a list of spelling suggestions for a word.

If that word is spelled correctly, the returned list will be empty.

Parameters:
- *word*:  String word to get spelling suggestions for.




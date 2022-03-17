# Spellcheck

Spell checking for Textadept.

Install this module by copying it into your *~/.textadept/modules/* directory or Textadept's
*modules/* directory, and then putting the following in your *~/.textadept/init.lua*:

    require('spellcheck')

There will be a "Tools > Spelling" menu. Textadept automatically spell checks the buffer
each time it is saved, highlighting any misspelled words in plain text, comments, and
strings. These options can be configured via [`spellcheck.check_spelling_on_save`](#spellcheck.check_spelling_on_save) and
[`spellcheck.spellcheckable_styles`](#spellcheck.spellcheckable_styles), respectively. Left-clicking (not right-clicking)
on misspelled words shows suggestions.

By default, Textadept attempts to load a preexisting [Hunspell][] dictionary for
the detected locale. If none exists, or if the locale is not detected, Textadept
falls back on its own prepackaged US English dictionary. Textadept searches for
dictionaries in [`spellcheck.hunspell_paths`](#spellcheck.hunspell_paths). User dictionaries are located in the
*~/.textadept/dictionaries/* directory, and are loaded automatically.

Dictionary files are Hunspell dictionaries and follow the Hunspell format: the first line
in a dictionary file contains the number of entries contained within, and each subsequent
line contains a word.

[Hunspell]: https://hunspell.github.io/

## Compiling

Releases include binaries, so building this modules should not be necessary. If you want
to build manually, run `make deps` followed by `make spell.so`. This assumes the module is
installed in Textadept's *modules/* directory. If it is not (e.g. it is in your `_USERHOME`),
run `make ta=/path/to/textadept spell.so`.

## Key Bindings

Windows, Linux, BSD | macOS | Terminal | Command
-|-|-|-
**Tools**| | |
F7 | F7 | F7 | Check spelling interactively
Shift+F7 | ⇧F7 | S-F7 | Mark misspelled words


## Fields defined by `spellcheck`

<a id="spellcheck.INDIC_SPELLING"></a>
### `spellcheck.INDIC_SPELLING` (number)

The spelling error indicator number.

<a id="spellcheck.check_spelling_on_save"></a>
### `spellcheck.check_spelling_on_save` (bool)

Check spelling after saving files.
  The default value is `true`.

<a id="spellcheck.spellchecker"></a>
### `spellcheck.spellchecker` (userdata)

The Hunspell spellchecker object.


## Functions defined by `spellcheck`

<a id="_G.spell"></a>
### `_G.spell`(*aff, dic, key*)

Returns a Hunspell spellchecker that utilizes affix file path *aff* and dictionary file
path *dic*.
This is a low-level function. You probably want to use the higher-level `spellcheck.load()`.

Parameters:

* *`aff`*: Path to the Hunspell affix file to use.
* *`dic`*: Path to the Hunspell dictionary file to use.
* *`key`*: Optional string key for encrypted *dic*.

Usage:

* `spellchecker = spell('/usr/share/hunspell/en_US.aff', '/usr/share/hunspell/en_US.dic')`
* `spellchecker:spell('foo') --> false`

Return:

* spellchecker

See also:

* [`spellcheck.load`](#spellcheck.load)

<a id="spellcheck.check_spelling"></a>
### `spellcheck.check_spelling`(*interactive, wrapped*)

Checks the buffer for spelling errors, marks misspelled words, and optionally shows suggestions
for the next misspelled word if *interactive* is `true`.

Parameters:

* *`interactive`*: Flag indicating whether or not to display suggestions for the next
  misspelled word. The default value is `false`.
* *`wrapped`*: Utility flag indicating whether or not the spellchecker has wrapped for
  displaying useful statusbar information. This flag is used and set internally, and should
  not be set otherwise.

<a id="spellcheck.load"></a>
### `spellcheck.load`(*lang*)

Loads string language *lang* into the spellchecker.

Parameters:

* *`lang`*: The hunspell language to load.

Usage:

* `spellcheck.load('en_US')`

See also:

* [`spellcheck.hunspell_paths`](#spellcheck.hunspell_paths)

<a id="spellchecker:add_dic"></a>
### `spellchecker:add_dic`(*dic*)

Adds words from dictionary file path *dic* to the spellchecker.

Parameters:

* *`dic`*: Path to the Hunspell dictionary file to load.

<a id="spellchecker:add_word"></a>
### `spellchecker:add_word`(*word*)

Adds string *word* to the spellchecker.
Note: this is not a permanent addition. It only persists for the life of this spellchecker
and applies only to this spellchecker.

Parameters:

* *`word`*: The word to add.

<a id="spellchecker:get_dic_encoding"></a>
### `spellchecker:get_dic_encoding`()

Returns the dictionary's encoding.

Return:

* string encoding

<a id="spellchecker:spell"></a>
### `spellchecker:spell`(*word*)

Returns `true` if string *word* is spelled correctly; `false` otherwise.

Parameters:

* *`word`*: The word to check spelling of.

Return:

* `true` or `false`

<a id="spellchecker:suggest"></a>
### `spellchecker:suggest`(*word*)

Returns a list of spelling suggestions for string *word*.
If *word* is spelled correctly, the returned list will be empty.

Parameters:

* *`word`*: The word to get spelling suggestions for.

Return:

* list of suggestions


## Tables defined by `spellcheck`

<a id="spellcheck.hunspell_paths"></a>
### `spellcheck.hunspell_paths`

Paths to search for Hunspell dictionaries in.

<a id="spellcheck.spellcheckable_styles"></a>
### `spellcheck.spellcheckable_styles`

Table of spellcheckable style names.
Text with either of these styles is eligible for spellchecking.
The style name keys are assigned non-`nil` values. The default styles are `default`,
`comment`, and `string`.

---

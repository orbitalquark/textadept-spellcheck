-- Copyright 2015-2020 Mitchell. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- Spell checking for Textadept.
--
-- Install this module by copying it into your *~/.textadept/modules/* directory
-- or Textadept's *modules/* directory, and then putting the following in your
-- *~/.textadept/init.lua*:
--
--     require('spellcheck')
--
-- By default, Textadept attempts to load a preexisting [Hunspell][] dictionary
-- for the detected locale. If none exists, or if the locale is not detected,
-- Textadept falls back on its own prepackaged US English dictionary. Textadept
-- searches for dictionaries in [`spellcheck.hunspell_paths`](). User
-- dictionaries are located in the *~/.textadept/dictionaries/* directory, and
-- are loaded automatically.
--
-- Dictionary files are Hunspell dictionaries and follow the Hunspell format:
-- the first line in a dictionary file contains the number of entries contained
-- within, and each subsequent line contains a word.
--
-- [Hunspell]: https://hunspell.github.io/
--
-- ### Key Bindings
--
-- Windows, Linux, BSD|macOS|Terminal|Command
-- -------------------|-----|--------|-------
-- **Tools**          |     |        |
-- F7                 |F7   |F7      |Check spelling interactively
-- Shift+F7           |⇧F7  |S-F7    |Mark misspelled words
--
-- @field check_spelling_on_save (bool)
--   Check spelling after saving files.
--   The default value is `true`.
-- @field INDIC_SPELLING (number)
--   The spelling error indicator number.
-- @field spellchecker (userdata)
--   The Hunspell spellchecker object.
module('spellcheck')]]

M.check_spelling_on_save = true
M.INDIC_SPELLING = _SCINTILLA.next_indic_number()

-- Localizations.
local _L = _L
if not rawget(_L, 'Spelling') then
  -- Menu.
  _L['Spelling'] = 'Spell_ing'
  _L['Check Spelling...'] = '_Check Spelling...'
  _L['Mark Misspelled Words'] = '_Mark Misspelled Words'
  _L['Load Dictionary...'] = '_Load Dictionary...'
  _L['Open User Dictionary'] = '_Open User Dictionary'
  -- Other.
  _L['Language not found'] = 'Language not found'
  _L['No Suggestions'] = 'No Suggestions'
  _L['Add'] = 'Add'
  _L['Ignore'] = 'Ignore'
  _L['No misspelled words.'] = 'No misspelled words.'
end

local lib = 'spellcheck.spell'
if OSX then
  lib = lib .. 'osx'
elseif WIN32 and CURSES then
  lib = lib .. '-curses'
end
M.spell = require(lib)

---
-- Paths to search for Hunspell dictionaries in.
-- @class table
-- @name hunspell_paths
M.hunspell_paths = {
  _USERHOME .. '/modules/spellcheck/', '/usr/local/share/hunspell/',
  '/usr/share/hunspell/', 'C:\\Program Files (x86)\\hunspell\\',
  'C:\\Program Files\\hunspell\\', _HOME .. '/modules/spellcheck/'
}

---
-- Table of spellcheckable style names.
-- Text with either of these styles is eligible for spellchecking.
-- The style name keys are assigned non-`nil` values. The default styles are
-- `default`, `comment`, and `string`.
-- @class table
-- @name spellcheckable_styles
M.spellcheckable_styles = {default = true, comment = true, string = true}

local SPELLING_ID = _SCINTILLA.next_user_list_type()
local user_dicts = _USERHOME .. (not WIN32 and '/' or '\\') .. 'dictionaries'

---
-- Loads string language *lang* into the spellchecker.
-- @param lang The hunspell language to load.
-- @usage spellcheck.load('en_US')
-- @see hunspell_paths
-- @name load
function M.load(lang)
  local aff, dic = lang .. '.aff', lang .. '.dic'
  for _, path in ipairs(M.hunspell_paths) do
    local aff_path, dic_path = path .. aff, path .. dic
    if lfs.attributes(aff_path) and lfs.attributes(dic_path) then
      M.spellchecker = M.spell(aff_path, dic_path)
      goto lang_found
    end
  end
  error(_L['Language not found'] .. ': ' .. lang)
  ::lang_found::
  if lfs.attributes(user_dicts) then
    for dic in lfs.dir(user_dicts) do
      if not dic:find('^%.%.?$') then
        M.spellchecker:add_dic(user_dicts .. (not WIN32 and '/' or '\\') .. dic)
      end
    end
  end
end
M.load((os.getenv('LANG') or ''):match('^[^.@]+') or 'en_US')
events.connect(events.RESET_BEFORE, function() M.spellchecker = nil end)

-- Shows suggestions for string *word* at the current position.
-- @param word The word to show suggestions for.
local function show_suggestions(word)
  local encoding = M.spellchecker:get_dic_encoding()
  local suggestions = M.spellchecker:suggest(word:iconv(encoding, 'UTF-8'))
  for i = 1, #suggestions do
    suggestions[i] = suggestions[i]:iconv('UTF-8', encoding)
  end
  if #suggestions == 0 then
    suggestions[1] = string.format('(%s)', _L['No Suggestions'])
  end
  suggestions[#suggestions + 1] = string.format('(%s)', _L['Add'])
  suggestions[#suggestions + 1] = string.format('(%s)', _L['Ignore'])
  local separator = buffer.auto_c_separator
  buffer.auto_c_separator = string.byte('\n')
  buffer:user_list_show(SPELLING_ID, table.concat(suggestions, '\n'))
  buffer.auto_c_separator = separator
end
-- Either correct the misspelled word, add it to the user's dictionary, or
-- ignore it (based on the selected item).
events.connect(events.USER_LIST_SELECTION, function(id, text, position)
  if id ~= SPELLING_ID then return end
  local s = buffer:indicator_start(M.INDIC_SPELLING, position)
  local e = buffer:indicator_end(M.INDIC_SPELLING, position)
  if not text:find('^%(') then
    local line = buffer:line_from_position(position)
    local column = buffer.column[position]
    buffer:set_target_range(s, e)
    buffer:replace_target(text)
    buffer:goto_pos(buffer:find_column(line, column))
  else
    local word = buffer:text_range(s, e)
    if text:find(_L['Add']) then
      if not lfs.attributes(user_dicts) then lfs.mkdir(user_dicts) end
      local user_dict = user_dicts .. '/user.dic'
      local words = {}
      if lfs.attributes(user_dict) then
        for word in io.lines(user_dict) do words[#words + 1] = word end
      end
      words[1] = #words + 1
      words[#words + 1] = word
      io.open(user_dict, 'wb'):write(table.concat(words, '\n')):close()
    end
    M.spellchecker:add_word(
      word:iconv(M.spellchecker:get_dic_encoding(), 'UTF-8'))
    M.check_spelling() -- clear highlighting for all occurrences
  end
end)

-- LPeg grammar that matches spellcheckable words.
local word_patt = {
  lpeg.Cp() * lpeg.C(lpeg.V('word')) * lpeg.Cp() + lpeg.V('skip') * lpeg.V(1),
  word_char = lpeg.R('AZ', 'az', '09', '\127\255') + '_',
  word_part = lpeg.R('az', '\127\255')^1 * -lpeg.V('word_char') +
    lpeg.R('AZ') * lpeg.R('az', '\127\255')^0 * -lpeg.V('word_char') +
    lpeg.R('AZ', '\127\255')^1 * -lpeg.V('word_char'),
  word = lpeg.V('word_part') * (lpeg.S("-'") * lpeg.V('word_part'))^-1 *
    -(lpeg.V('word_char') + lpeg.S("-'.") * lpeg.V('word_char')),
  skip = lpeg.V('word_char')^1 * (lpeg.S("-'.") * lpeg.V('word_char')^1)^0 +
    (1 - lpeg.V('word_char'))^1,
}

-- Returns a generator that acts like string.gmatch, but for LPeg patterns.
-- @param pattern LPeg pattern.
-- @param subject String subject.
local function lpeg_gmatch(pattern, subject)
  return function(subject, i)
    local s, word, e = lpeg.match(pattern, subject, i)
    if word then return e, s, word end
  end, subject, 1
end

---
-- Checks the buffer for spelling errors, marks misspelled words, and optionally
-- shows suggestions for the next misspelled word if *interactive* is `true`.
-- @param interactive Flag indicating whether or not to display suggestions for
--   the next misspelled word. The default value is `false`.
-- @param wrapped Utility flag indicating whether or not the spellchecker has
--   wrapped for displaying useful statusbar information. This flag is used and
--   set internally, and should not be set otherwise.
-- @name check_spelling
function M.check_spelling(interactive, wrapped)
  -- Show suggestions for the misspelled word under the caret if necessary.
  if interactive and buffer:indicator_all_on_for(buffer.current_pos) &
     1 << M.INDIC_SPELLING - 1 > 0 then
    local s = buffer:indicator_start(M.INDIC_SPELLING, buffer.current_pos)
    local e = buffer:indicator_end(M.INDIC_SPELLING, buffer.current_pos)
    show_suggestions(buffer:text_range(s, e))
    return
  end
  -- Clear existing spellcheck indicators.
  buffer.indicator_current = M.INDIC_SPELLING
  if not interactive then buffer:indicator_clear_range(1, buffer.length) end
  -- Iterate over spellcheckable text ranges, checking words in them, and
  -- marking misspellings.
  local spellcheckable_styles = {} -- cache
  local buffer, style_at = buffer, buffer.style_at
  local encoding = M.spellchecker:get_dic_encoding()
  local i = (not interactive or wrapped) and 1 or
    buffer:word_start_position(buffer.current_pos, false)
  while i <= buffer.length do
    -- Ensure at least the next page of text is styled since spellcheckable
    -- ranges depend on accurate styling.
    if i > buffer.end_styled then
      local next_page = buffer:line_from_position(i) + view.lines_on_screen
      buffer:colorize(buffer.end_styled, buffer.line_end_position[next_page])
    end
    local style = style_at[i]
    if spellcheckable_styles[style] == nil then
      -- Update the cache.
      local style_name = buffer:name_of_style(style)
      spellcheckable_styles[style] = M.spellcheckable_styles[style_name] == true
    end
    if spellcheckable_styles[style] then
      local j = i + 1
      while j <= buffer.length and style_at[j] == style do j = j + 1 end
      for e, s, word in lpeg_gmatch(word_patt, buffer:text_range(i, j)) do
        local ok, encoded_word = pcall(string.iconv, word, encoding, 'UTF-8')
        if not M.spellchecker:spell(ok and encoded_word or word) then
          buffer:indicator_fill_range(i + s - 1, e - s)
          if interactive then
            buffer:goto_pos(i + s - 1)
            show_suggestions(word)
            return
          end
        end
      end
      i = j
    else
      i = i + 1
    end
  end
  if interactive then
    if not wrapped then M.check_spelling(true, true) return end -- wrap
    ui.statusbar_text = _L['No misspelled words.']
  end
end
-- Check spelling upon saving files.
events.connect(events.FILE_AFTER_SAVE, function()
  if M.check_spelling_on_save then M.check_spelling() end
end)
-- Show spelling suggestions when clicking on misspelled words.
events.connect(events.INDICATOR_CLICK, function(position)
  if buffer:indicator_all_on_for(position) & 1 << M.INDIC_SPELLING - 1 > 0 then
    buffer:goto_pos(position)
    M.check_spelling(true)
  end
end)

-- Set up indicators, add a menu, and configure key bindings.
local function set_properties()
  view.indic_style[M.INDIC_SPELLING] = not CURSES and view.INDIC_DIAGONAL or
    view.INDIC_STRAIGHTBOX
  view.indic_fore[M.INDIC_SPELLING] = view.property_int['color.red']
end
events.connect(events.VIEW_NEW, set_properties)
events.connect(events.BUFFER_NEW, set_properties)

-- Add menu entries and configure key bindings.
-- (Insert 'Spelling' menu in alphabetical order.)
local m_tools = textadept.menu.menubar[_L['Tools']]
local found_area
local SEP = {''}
for i = 1, #m_tools - 1 do
  if not found_area and m_tools[i + 1].title == _L['Bookmarks'] then
    found_area = true
  elseif found_area then
    local label = m_tools[i].title or m_tools[i][1]
    if 'Spelling' < label:gsub('^_', '') or m_tools[i][1] == '' then
      table.insert(m_tools, i, {
        title = _L['Spelling'],
        {_L['Check Spelling...'], function() M.check_spelling(true) end},
        {_L['Mark Misspelled Words'], M.check_spelling},
        SEP,
        {_L['Load Dictionary...'], function()
          local dicts = {}
          for _, path in ipairs(M.hunspell_paths) do
            if not lfs.attributes(path, 'mode') then goto continue end
            for name in lfs.dir(path) do
              if name:find('%.dic$') then
                dicts[#dicts + 1] = name:match('(.+)%.dic$')
              end
            end
            ::continue::
          end
          local button, i = ui.dialogs.filteredlist{
            title = _L['Select Dictionary'], columns = _L['Name'], items = dicts
          }
          if button == 1 and i then M.load(dicts[i]) end
        end},
        SEP,
        {_L['Open User Dictionary'], function()
          if not lfs.attributes(user_dicts) then lfs.mkdir(user_dicts) end
          io.open_file(user_dicts .. (not WIN32 and '/' or '\\') .. 'user.dic')
        end}
      })
      break
    end
  end
end
keys.f7 = m_tools[_L['Spelling']][_L['Check Spelling...']][2]
keys['shift+f7'] = M.check_spelling

return M

--[[ The functions below are Lua C functions.

---
-- Returns a Hunspell spellchecker that utilizes affix file path *aff* and
-- dictionary file path *dic*.
-- This is a low-level function. You probably want to use the higher-level
-- `spellcheck.load()`.
-- @param aff Path to the Hunspell affix file to use.
-- @param dic Path to the Hunspell dictionary file to use.
-- @param key Optional string key for encrypted *dic*.
-- @return spellchecker
-- @usage spellchecker = spell('/usr/share/hunspell/en_US.aff',
--   '/usr/share/hunspell/en_US.dic')
-- @usage spellchecker:spell('foo') --> false
-- @see load
function _G.spell(aff, dic, key) end

---
-- Adds words from dictionary file path *dic* to the spellchecker.
-- @param dic Path to the Hunspell dictionary file to load.
function spellchecker:add_dic(dic) end

---
-- Returns `true` if string *word* is spelled correctly; `false` otherwise.
-- @param word The word to check spelling of.
-- @return `true` or `false`
function spellchecker:spell(word) end

---
-- Returns a list of spelling suggestions for string *word*.
-- If *word* is spelled correctly, the returned list will be empty.
-- @param word The word to get spelling suggestions for.
-- @return list of suggestions
function spellchecker:suggest(word) end

---
-- Returns the dictionary's encoding.
-- @return string encoding
function spellchecker:get_dic_encoding() end

---
-- Adds string *word* to the spellchecker.
-- Note: this is not a permanent addition. It only persists for the life of
-- this spellchecker and applies only to this spellchecker.
-- @param word The word to add.
function spellchecker:add_word(word) end
]]

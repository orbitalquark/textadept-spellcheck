-- Copyright 2020-2025 Mitchell. See LICENSE.

local spellcheck = require('spellcheck')

test('spellcheck.check_spelling should mark misspelled words', function()
	local misspelled = 'mispelled'
	local words = 'worrds'
	local _<close> = test.tmpfile(misspelled .. ' ' .. words, true)

	spellcheck.check_spelling()

	local misspelled_words = test.get_indicated_text(spellcheck.INDIC_SPELLING)
	test.assert_equal(misspelled_words, {misspelled, words})
end)

test('spellcheck.check_spelling respect spellcheck.spellcheckable_styles', function()
	local misspelled = 'mispelled'
	local _<close> = test.tmpfile('.lua', string.format('-- %s\n%s = "%s"', misspelled, misspelled,
		misspelled), true)

	spellcheck.check_spelling()

	local misspelled_words = test.get_indicated_text(spellcheck.INDIC_SPELLING)
	test.assert_equal(misspelled_words, {misspelled, misspelled})
end)

test('spellcheck.check_spelling(true) should prompt with suggestions', function()
	local _<close> = test.tmpfile('mispelled', true)
	local user_list_show = test.stub()
	local _<close> = test.mock(buffer, 'user_list_show', user_list_show)

	spellcheck.check_spelling()
	spellcheck.check_spelling(true)

	test.assert_equal(user_list_show.called, true)
	test.assert_equal(buffer.current_pos, 1)
	local suggestions = {}
	for item in user_list_show.args[3]:gmatch('%S+') do suggestions[#suggestions + 1] = item end
	test.assert_contains(suggestions, 'misspelled')
end)

test('spellcheck.check_spelling(true) should wrap if necessary', function()
	buffer:add_text('mispelled ')
	local user_list_show = test.stub()
	local _<close> = test.mock(buffer, 'user_list_show', user_list_show)

	spellcheck.check_spelling(true)

	test.assert_equal(user_list_show.called, true)
end)

test('selecting a suggestion should replace the misspelled word', function()
	local _<close> = test.tmpfile('mispelled', true)
	local user_list_show = test.stub()
	local _<close> = test.mock(buffer, 'user_list_show', user_list_show)
	spellcheck.check_spelling(true)
	local list_id = user_list_show.args[2]
	local suggested = 'misspelled'

	events.emit(events.USER_LIST_SELECTION, list_id, suggested, buffer.current_pos) -- simulate

	test.assert_equal(buffer:get_text(), suggested)
end)

test('ignoring a misspelled word should stop marking it misspelled', function()
	local misspelled = 'ignorethis'
	local _<close> = test.tmpfile(misspelled .. ' ' .. misspelled, true)
	local user_list_show = test.stub()
	local _<close> = test.mock(buffer, 'user_list_show', user_list_show)
	spellcheck.check_spelling(true)
	local list_id = user_list_show.args[2]

	events.emit(events.USER_LIST_SELECTION, list_id, '(' .. _L['Ignore'] .. ')', buffer.current_pos)

	local misspelled_words = test.get_indicated_text(spellcheck.INDIC_SPELLING)
	test.assert_equal(misspelled_words, {})
end)

test('adding a misspelled word should add it to the local dictionary', function()
	local misspelled = 'addthis'
	local _<close> = test.tmpfile(misspelled .. ' ' .. misspelled, true)
	local user_list_show = test.stub()
	local _<close> = test.mock(buffer, 'user_list_show', user_list_show)
	spellcheck.check_spelling(true)
	local list_id = user_list_show.args[2]

	events.emit(events.USER_LIST_SELECTION, list_id, '(' .. _L['Add'] .. ')', buffer.current_pos)

	local misspelled_words = test.get_indicated_text(spellcheck.INDIC_SPELLING)
	test.assert_equal(misspelled_words, {})
	local f<close> = io.open(_USERHOME .. '/dictionaries/user.dic')
	test.assert_contains(f:read('a'), misspelled)
end)

test('clicking a misspelled word should prompt for suggestions', function()
	local _<close> = test.tmpfile('mispelled', true)
	spellcheck.check_spelling()
	local user_list_show = test.stub()
	local _<close> = test.mock(buffer, 'user_list_show', user_list_show)

	events.emit(events.INDICATOR_CLICK, buffer.current_pos)

	test.assert_equal(user_list_show.called, true)
end)

-- Coverage tests.

test('spellcheck.check_spelling(true) should indicate if there are no misspellings', function()
	spellcheck.check_spelling(true)

	-- TODO: how to assert statusbar was written to? Cannot mock it.
end)

test('spellcheck should load user dictionaries', function()
	local misspelled = 'ignoreother'
	io.open(_USERHOME .. '/dictionaries/other.dic', 'wb'):write('1\n' .. misspelled)
	local _<close> = test.tmpfile(misspelled, true)

	local select_first_item = test.stub(1)
	local _<close> = test.mock(ui.dialogs, 'list', select_first_item)

	textadept.menu.menubar['Tools/Spelling/Load Dictionary...'][2]()
	spellcheck.check_spelling()

	test.assert_equal(select_first_item.called, true)
	local misspelled_words = test.get_indicated_text(spellcheck.INDIC_SPELLING)
	test.assert_equal(misspelled_words, {})
end)
expected_failure() -- TODO:

test('spellcheck should allow opening the user dictionary', function()
	textadept.menu.menubar['Tools/Spelling/Open User Dictionary'][2]()

	test.assert_contains(buffer.filename, 'user.dic')
end)

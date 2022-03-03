# Copyright 2015-2022 Mitchell. See LICENSE.

ta = ../..
ta_src = $(ta)/src
ta_lua = $(ta_src)/lua/src

CXX = g++
CXXFLAGS = -std=c++11 -pedantic -fPIC -Wall
LDFLAGS = -Wl,--retain-symbols-file -Wl,$(ta_src)/lua.sym
hunspell_flags = -DHUNSPELL_STATIC -Ihunspell

all: spell.so spell.dll spell-curses.dll spellosx.so
clean: ; rm -f *.o *.so *.dll

# Platform objects.

CROSS_WIN = x86_64-w64-mingw32-g++-posix
DLLTOOL = x86_64-w64-mingw32-dlltool
CROSS_OSX = x86_64-apple-darwin17-c++ -stdlib=libc++

hunspell_objs = affentry.o affixmgr.o csutil.o filemgr.o hashmgr.o hunspell.o hunzip.o phonet.o \
  replist.o suggestmgr.o
hunspell_win_objs = $(addsuffix -win.o, $(basename $(hunspell_objs)))
hunspell_osx_objs = $(addsuffix -osx.o, $(basename $(hunspell_objs)))

spell.so: spell.o $(hunspell_objs) ; $(CXX) -shared $(CXXFLAGS) -o $@ $^ $(LDFLAGS)
spell.dll: spell-win.o $(hunspell_win_objs) lua.la
	$(CROSS_WIN) -shared -static-libgcc -static-libstdc++ $(CXXFLAGS) -o $@ $^ $(LDFLAGS)
spell-curses.dll: spell-win.o $(hunspell_win_objs) lua-curses.la
	$(CROSS_WIN) -shared -static-libgcc -static-libstdc++ $(CXXFLAGS) -o $@ $^ $(LDFLAGS)
spellosx.so: spell-osx.o $(hunspell_osx_objs)
	$(CROSS_OSX) -shared $(CXXFLAGS) -undefined dynamic_lookup -o $@ $^

spell.o: spell.cxx
	$(CXX) -c $(CXXFLAGS) -I$(ta_lua) $(hunspell_flags) -o $@ $^
spell-win.o: spell.cxx
	$(CROSS_WIN) -c $(CXXFLAGS) -DLUA_BUILD_AS_DLL -DLUA_LIB -I$(ta_lua) $(hunspell_flags) -o $@ $^
spell-osx.o: spell.cxx ; $(CROSS_OSX) -c $(CXXFLAGS) -I$(ta_lua) $(hunspell_flags) -o $@ $^

$(hunspell_objs): %.o: hunspell/%.cxx
	$(CXX) -c $(CXXFLAGS) $(hunspell_flags) $< -o $@
$(hunspell_win_objs): %-win.o: hunspell/%.cxx
	$(CROSS_WIN) -c $(CXXFLAGS) $(hunspell_flags) $< -o $@
$(hunspell_osx_objs): %-osx.o: hunspell/%.cxx
	$(CROSS_OSX) -c $(CXXFLAGS) $(hunspell_flags) $< -o $@

lua.def: $(ta_src)/lua.sym
	echo LIBRARY \"textadept.exe\" > $@ && echo EXPORTS >> $@
	grep -v "^#" $< >> $@
lua.la: lua.def ; $(DLLTOOL) -d $< -l $@
lua-curses.def:
	echo LIBRARY \"textadept-curses.exe\" > $@ && echo EXPORTS >> $@
	grep -v "^#" $(ta_src)/lua.sym >> $@
lua-curses.la: lua-curses.def ; $(DLLTOOL) -d $< -l $@

# Documentation.

cwd = $(shell pwd)
docs: luadoc README.md
README.md: init.lua
	cd $(ta)/scripts && luadoc --doclet markdowndoc $(cwd)/$< > $(cwd)/$@
	sed -i -e '1,+4d' -e '6c# Spellcheck' -e '7d' -e 's/^##/#/;' $@
luadoc: init.lua
	cd $(ta)/modules && luadoc -d $(cwd) --doclet lua/tadoc $(cwd)/$< \
		--ta-home=$(shell readlink -f $(ta))
	sed -i 's/_HOME.\+\?_HOME/_HOME/;' tags

# External Hunspell and dictionary dependencies.

en_US = en_US.aff en_US.dic

deps: hunspell $(en_US)

hunspell_zip = v1.7.0.zip
$(hunspell_zip): ; wget https://github.com/hunspell/hunspell/archive/$@
hunspell: | $(hunspell_zip) ; unzip -d $@ -j $| "*/src/$@/*"
$(en_US):
	wget https://cgit.freedesktop.org/libreoffice/dictionaries/plain/en/en_US.aff
	wget https://cgit.freedesktop.org/libreoffice/dictionaries/plain/en/en_US.dic

# Releases.

ifneq (, $(shell hg summary 2>/dev/null))
  archive = hg archive -X ".hg*" $(1)
else
  archive = git archive HEAD --prefix $(1)/ | tar -xf -
endif

release: spellcheck | $(hunspell_zip) $(en_US)
	cp $| $<
	make -C $< deps && make -C $< -j ta="../../.."
	zip -r $<.zip $< -x "*.zip" "*.o" "*.def" "*.la" "$</.git*" "$</hunspell*" && rm -r $<
spellcheck: ; $(call archive,$@)

# Copyright 2022-2023 Mitchell. See LICENSE.

cmake_minimum_required(VERSION 3.16)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED true)
if(APPLE)
  set(CMAKE_OSX_DEPLOYMENT_TARGET 10.13 CACHE STRING "")
endif()

set(src ${CMAKE_SOURCE_DIR})

# Dependencies.
include(FetchContent)
set(FETCHCONTENT_QUIET OFF)
set(hunspell_zip v1.7.0.zip)
FetchContent_Declare(hunspell URL https://github.com/hunspell/hunspell/archive/${hunspell_zip})
FetchContent_MakeAvailable(hunspell)
if(NOT EXISTS ${src}/en_US.aff)
  file(DOWNLOAD https://cgit.freedesktop.org/libreoffice/dictionaries/plain/en/en_US.aff
      ${src}/en_US.aff
    SHOW_PROGRESS)
endif()
if(NOT EXISTS ${src}/en_US.dic)
  file(DOWNLOAD https://cgit.freedesktop.org/libreoffice/dictionaries/plain/en/en_US.dic
      ${src}/en_US.dic
    SHOW_PROGRESS)
endif()
set(lua_tgz lua-5.4.4.tar.gz)
set(lua_url file://${CMAKE_BINARY_DIR}/_deps/${lua_tgz})
if(NOT EXISTS ${CMAKE_BINARY_DIR}/_deps/${lua_tgz})
  set(lua_url https://www.lua.org/ftp/${lua_tgz})
endif()
FetchContent_Declare(lua URL ${lua_url})
FetchContent_MakeAvailable(lua)

# Build.
project(spell LANGUAGES CXX C)
file(GLOB hunspell_src ${hunspell_SOURCE_DIR}/src/hunspell/*.cxx)
if(WIN32)
  # On Windows, DLLs cannot do dynamic lookup. They need symbols to link to at build time.
  # Rather than fetching a Textadept build and creating separate DLLs linked to textadept.lib and
  # textadept-curses.lib, just embed a minimal copy of Lua in a single DLL.
  file(GLOB lua_src ${lua_SOURCE_DIR}/src/*.c)
  list(FILTER lua_src EXCLUDE REGEX "(lua|luac|[^x]lib|linit)\.c$") # of *lib.c, keep only lauxlib.c
endif()
add_library(spell SHARED spell.cxx ${hunspell_src} ${lua_src})
target_include_directories(spell PRIVATE ${hunspell_SOURCE_DIR}/src ${lua_SOURCE_DIR}/src)
if(WIN32)
  set(lua_compile_definitions LUA_BUILD_AS_DLL LUA_LIB)
endif()
target_compile_definitions(spell PRIVATE HUNSPELL_STATIC ${lua_compile_definitions})
if(APPLE)
  target_link_options(spell PRIVATE -undefined dynamic_lookup)
endif()

# Install.
install(TARGETS spell DESTINATION ${src})
if(NOT (WIN32 OR APPLE))
  install(CODE "file(RENAME ${src}/libspell.so ${src}/spell.so)")
elseif(APPLE)
  install(CODE "file(RENAME ${src}/libspell.dylib ${src}/spellosx.so)")
endif()
if(NOT (WIN32 OR APPLE))
  include(GNUInstallDirs)
  set(module_dir ${CMAKE_INSTALL_FULL_DATADIR}/textadept/modules/spellcheck)
  install(CODE "file(MAKE_DIRECTORY ${module_dir})")
  install(FILES init.lua en_US.aff en_US.dic spell.so DESTINATION ${module_dir})
endif()

# Documentation.
get_filename_component(ta_dir ${src}/../../ ABSOLUTE)
add_custom_target(docs DEPENDS README.md luadoc)
add_custom_command(OUTPUT ${src}/README.md
  COMMAND luadoc --doclet markdowndoc ${src}/init.lua > ${src}/README.md
  COMMAND sed -i -e "1,+4d" -e "6c# Spellcheck" -e "7d" -e "s/^##/#/;" ${src}/README.md
  DEPENDS init.lua
  WORKING_DIRECTORY ${ta_dir}/scripts
  VERBATIM)
add_custom_target(luadoc DEPENDS tags api)
add_custom_command(OUTPUT ${src}/tags ${src}/api
  COMMAND luadoc -d ${src} --doclet tadoc ${src}/init.lua --ta-home=${ta_dir}
  DEPENDS init.lua
  WORKING_DIRECTORY ${ta_dir}/modules/lua)

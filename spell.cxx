// Copyright 2015-2022 Mitchell. See LICENSE.

#include "hunspell/hunspell.hxx"

extern "C" {
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
}

/** spellchecker:add_dic() Lua function. */
static int hs_add_dic(lua_State *L) {
  auto hs = reinterpret_cast<Hunspell *>(luaL_checkudata(L, 1, "ta_spell"));
  return (hs->add_dic(luaL_checkstring(L, 2), luaL_optstring(L, 3, NULL)), 0);
}

/** spellchecker:spell() Lua function. */
static int hs_spell(lua_State *L) {
  auto hs = reinterpret_cast<Hunspell *>(luaL_checkudata(L, 1, "ta_spell"));
  std::string word = luaL_checkstring(L, 2);
  return (lua_pushboolean(L, hs->spell(word)), 1);
}

/** spellchecker:suggest() Lua function. */
static int hs_suggest(lua_State *L) {
  auto hs = reinterpret_cast<Hunspell *>(luaL_checkudata(L, 1, "ta_spell"));
  std::string word = luaL_checkstring(L, 2);
  std::vector<std::string> suggestions = hs->suggest(word);
  lua_createtable(L, suggestions.size(), 0);
  for (size_t i = 0; i < suggestions.size(); i++)
    lua_pushstring(L, suggestions[i].c_str()), lua_rawseti(L, -2, i + 1);
  return 1;
}

/** spellchecker:get_dic_encoding() Lua function. */
static int hs_get_dic_encoding(lua_State *L) {
  auto hs = reinterpret_cast<Hunspell *>(luaL_checkudata(L, 1, "ta_spell"));
  return (lua_pushstring(L, hs->get_dic_encoding()), 1);
}

/** spellchecker:add_word() Lua function. */
static int hs_add(lua_State *L) {
  auto hs = reinterpret_cast<Hunspell *>(luaL_checkudata(L, 1, "ta_spell"));
  std::string word = luaL_checkstring(L, 2);
  return (hs->add(word), 0);
}

/** spellchecker.__gc() metamethod. */
static int hs_gc(lua_State *L) {
  auto hs = reinterpret_cast<Hunspell *>(luaL_checkudata(L, 1, "ta_spell"));
  return (hs->~Hunspell(), 0);
}

/** spell() Lua function. */
static int spell(lua_State *L) {
  const char *aff_path = luaL_checkstring(L, 1);
  const char *dic_path = luaL_checkstring(L, 2);
  const char *key = luaL_optstring(L, 3, NULL);
  new (reinterpret_cast<Hunspell *>(lua_newuserdata(L, sizeof(Hunspell))))
    Hunspell(aff_path, dic_path, key);
  return (luaL_setmetatable(L, "ta_spell"), 1);
}

extern "C" {
// clang-format off
static const luaL_Reg lib[] = {
  {"add_dic", hs_add_dic},
  {"spell", hs_spell},
  {"suggest", hs_suggest},
  {"get_dic_encoding", hs_get_dic_encoding},
  {"add_word", hs_add},
  {NULL, NULL}
};
// clang-format on

int luaopen_spell(lua_State *L) {
  if (luaL_newmetatable(L, "ta_spell")) {
    luaL_newlib(L, lib), lua_setfield(L, -2, "__index");
    lua_pushcfunction(L, hs_gc), lua_setfield(L, -2, "__gc");
  }
  return (lua_pushcfunction(L, spell), 1);
}

// Platform-specific Lua library entry points.
LUALIB_API int luaopen_spellcheck_spell(lua_State *L) { return luaopen_spell(L); }
LUALIB_API int luaopen_spellcheck_spellosx(lua_State *L) { return luaopen_spell(L); }
}

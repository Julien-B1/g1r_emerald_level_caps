local engineRoot = os.getenv("GEN1RECOMP_ROOT") or "gen1recomp"
package.path = engineRoot .. "/?.lua;" .. engineRoot .. "/?/init.lua;" .. package.path

local T = require("tests.modkit")
local Runtime = require("src.mods.Runtime")
local GameVersion = require("src.core.GameVersion")
local Sdk = T.sdk

local oldVersion = GameVersion.get()
GameVersion.set("emerald")

local modPath = os.getenv("G1R_EMERALD_LEVEL_CAPS_MOD_PATH")
  or "mods/g1r_emerald_level_caps"
local run = Sdk.loadMod(modPath, {
  root = modPath:sub(1, 1) == "/" and "/" or nil,
  data = Sdk.gen3Data(),
  generation = 3,
})
T.eq(#run.errors, 0, "loads clean (" .. tostring(run.errors[1]) .. ")")
run.loader.modOptions.g1r_emerald_level_caps = { level_caps = true }

local exports = run.loader.exports.g1r_emerald_level_caps
local expectedIds = {
  520, 526, 523, 529, 535, 532, 265, 266,
  521, 527, 524, 530, 536, 533, 656, 267, 597, 602,
  268, 269, 32, 522, 528, 525, 531, 537, 534, 270, 732,
  601, 30, 271, 734, 514, 33, 34, 272, 519, 261, 262,
  263, 264, 335, 804,
}
local actualIds = {}
for _, boss in ipairs(exports.bosses) do
  for _, trainerId in ipairs(boss.ids) do actualIds[trainerId] = true end
end
T.eq(#exports.bosses, 28, "the boss table has all 28 progression encounters")
for _, trainerId in ipairs(expectedIds) do
  T.check(actualIds[trainerId], "the boss table includes trainer " .. trainerId)
  actualIds[trainerId] = nil
end
T.eq(next(actualIds), nil, "the boss table has no unlisted trainer IDs")
local summary = exports.summaryRows(function(boss)
  return boss.name == "Route 103 Rival"
end, false)
T.eq(summary[1].right, "Lv. 15", "the summary panel reports the current cap")
T.eq(summary[2].right, "OFF", "the summary panel reports whether caps are enforced")
T.eq(summary[3].right, "Roxanne", "the summary panel identifies the next milestone")

local beaten = {}
local function cap(options)
  return exports.capFromDefeated(function(boss) return beaten[boss.name] == true end, options)
end
local expectedCaps = {
  5, 15, 19, 20, 20, 24, 24, 25, 29, 31, 31, 31, 33, 33,
  39, 39, 42, 44, 44, 44, 46, 46, 49, 51, 53, 55, 58, 78,
}
for index, boss in ipairs(exports.bosses) do
  T.eq(boss.cap, expectedCaps[index], "boss row " .. index .. " has the planned effective cap")
  if boss.milestone then
    T.eq(cap({ enable_wally = true }), boss.cap,
      "progression reaches milestone cap " .. boss.cap)
  end
  beaten[boss.name] = true
end
T.eq(cap(), nil, "the cap clears after Steven")

T.eq(exports.capFromDefeated(function() return false end, { enable_rival = false }), 15,
  "disabling Rival skips its early cap milestones")
local beforeMaxie = function(boss)
  return boss.name == "Route 103 Rival" or boss.name == "Roxanne"
    or boss.name == "Brawly" or boss.name == "Route 110 Rival"
    or boss.name == "Wally Mauville" or boss.name == "Wattson"
  end
T.eq(exports.capFromDefeated(beforeMaxie), 25,
  "Aqua/Magma caps are enabled by default at Maxie on Mt. Chimney")
T.eq(exports.capFromDefeated(beforeMaxie, { enable_aqua_magma = false }), 29,
  "disabling Aqua/Magma skips Maxie and advances to Flannery's cap")
local aquaMagmaMilestones = {}
for _, boss in ipairs(exports.bosses) do
  if boss.group == "aqua_magma" then aquaMagmaMilestones[boss.name] = true end
end
T.check(aquaMagmaMilestones["Maxie Mt. Chimney"]
    and aquaMagmaMilestones["Maxie Magma Hideout"]
    and aquaMagmaMilestones["Mossdeep Space Center"],
  "the Aqua/Magma option groups the three team progression milestones")
local mauvilleProgress = function(boss)
  return boss.name == "Route 103 Rival" or boss.name == "Roxanne"
    or boss.name == "Brawly" or boss.name == "Route 110 Rival"
end
T.eq(exports.capFromDefeated(mauvilleProgress), 24,
  "Wally caps are off by default, so optional Mauville Wally cannot stall progression")
T.eq(exports.capFromDefeated(mauvilleProgress, { enable_wally = true }), 20,
  "enabling Wally makes the Mauville battle an optional cap checkpoint")
local mauvilleWallyBeaten = function(boss)
  return mauvilleProgress(boss) or boss.name == "Wally Mauville"
end
T.eq(exports.capFromDefeated(mauvilleWallyBeaten, { enable_wally = true }), 24,
  "beating Wally advances to Wattson when Wally caps are enabled")

local endgameProgress = function(boss) return boss.name ~= "Steven" end
T.eq(exports.capFromDefeated(endgameProgress), 78,
  "Steven and post-game caps are enabled by default")
T.eq(exports.capFromDefeated(endgameProgress, { enable_steven = false }), nil,
  "disabling Steven skips the post-game cap milestone")
T.eq(exports.capFromDefeated(endgameProgress, { enable_post = false }), nil,
  "disabling post-game caps suppresses the Steven cap")

local first = { hp = 10, level = 5 }
local second = { hp = 20, level = 7 }
local third = { hp = 30, level = 9 }
local firstOverlay = { { pp = 1 } }
local secondOverlay = { { pp = 2 } }
local thirdOverlay = { { pp = 3 } }
local party = { first, second, third }
local overlay = { firstOverlay, secondOverlay, thirdOverlay }
local session = { party = party, move_overlay = overlay }
local snapshot = exports.applyPartyOrder(session, { 3, 1 })
T.check(session.party[1] == third and session.party[2] == first,
  "selected lead and order preserve Pokémon references")
T.check(session.move_overlay[1] == thirdOverlay
    and session.move_overlay[2] == firstOverlay,
  "move overlay follows the selected party order")
third.level, third.hp = 10, 1
T.check(exports.restorePartySnapshot(snapshot), "party snapshot restores")
T.check(session.party == party and session.move_overlay == overlay,
  "restoration reinstates the original table identities")
T.check(session.party[3] == third and third.level == 10 and third.hp == 1,
  "battle changes survive restoration")

local savedLoaded = {}
local function stubModule(name, value)
  savedLoaded[name] = package.loaded[name]
  package.loaded[name] = value
end

local store = { flags = {} }
local flags = {
  trainerFlagId = function(trainerId) return 0x500 + trainerId end,
  getFlag = function(flagStore, _, flagId)
    return flagStore and flagStore.flags and flagStore.flags[flagId] == true
  end,
}
local sessionForHooks = {
  party = {
    { hp = 10, level = 4, exp = 450 },
    { hp = 20, level = 5, exp = 500 },
    { hp = 30, level = 8, exp = 800 },
  },
  move_overlay = { { { pp = 1 } }, { { pp = 2 } }, { { pp = 3 } } },
}
stubModule("src.core.game3.scripting.flags", flags)
stubModule("src.core.game3.scripting.space", { store = store })
stubModule("src.core.game3.scripting.trainers", {
  foeFromId = function() return { party = { {}, {}, {} } } end,
})
stubModule("src.mods.Runtime", {
  call = function(name, vanilla, trainerClass, trainerId, party)
    if name == "trainer.party" then return { party[1], party[2] } end
    return vanilla(trainerClass, trainerId, party)
  end,
})
stubModule("src.mods.Gen3Compat", {
  partyNames = function(party) return party end,
  partyNums = function(party) return party end,
})
stubModule("src.core.game3.link", { inLinkRoom = function() return false end })
local partyMenuOptions
stubModule("src.ui.game3.party_menu", {
  show = function(_, _, opts) partyMenuOptions = opts end,
})
stubModule("src.core.game3.battle.experience", { growthRate = function() return 0 end })
stubModule("src.core.game3.summary_data", {
  expForLevel = function(_, level) return level * 100 end,
})
stubModule("src.core.game3.runtime", {
  getSession = function() return sessionForHooks end,
})

Runtime.emit("map.entered", { mapId = "Route101" })
local pcMenuOptions
local pcFlow = {}
stubModule("src.ui.game3.pc_menu", {
  show = function(opts)
    pcMenuOptions = opts
    pcFlow[#pcFlow + 1] = "pc"
  end,
})
local startMenuClosed = false
stubModule("src.ui.game3.start_menu", {
  close = function(silent)
    startMenuClosed = silent == true
    pcFlow[#pcFlow + 1] = "start"
  end,
})
local openedBossRules
stubModule("src.ui.game3.stack", {
  push = function(id, screen) openedBossRules = { id = id, screen = screen } end,
  pop = function() end,
})
local forwardedBossRulesInput
stubModule("src.ui.game3.list_menu", {
  new = function(opts)
    return {
      update = function() end,
      draw = function() end,
      handleInput = function(_, input) forwardedBossRulesInput = input end,
    }
  end,
})
stubModule("src.ui.game3.window", {
  template = function(left, top, width, height)
    return { left = left, top = top, w = width, h = height }
  end,
  fill = function() end,
  fixedStdFrame = function() end,
  print = function(text, x, y)
    if text == "CAPS" then openedBossRules.title = { x = x, y = y } end
  end,
  printPx = function() end,
})
stubModule("src.core.game3.audio", { playSe = function() end })
stubModule("src.core.game3.se_ids", { resolve = function(id) return id end })
local startRows = Runtime.call("ui.start_menu.items", function(_, items)
  return items
end, { save = { position = { map = "Route101" } } }, {
  { id = "pokemon", label = "POKéMON" },
  { id = "save", label = "SAVE" },
})
T.eq(startRows[2].id, "boss_rules", "the CAPS panel is inserted before SAVE")
T.eq(startRows[3].id, "pc_anywhere", "PC storage is inserted before SAVE")
startRows[2].onSelect({}, sessionForHooks)
T.eq(openedBossRules and openedBossRules.id, "g1r_emerald_boss_rules",
  "the summary entry pushes a Gen 3 modal layer")
T.eq(openedBossRules and openedBossRules.screen.draw ~= nil, true,
  "the summary panel supplies a draw callback")
openedBossRules.screen.draw()
T.eq(openedBossRules.title and openedBossRules.title.y, 3,
  "the CAPS title is aligned to the top content row")
local panelInput = { wasPressed = function() return true end }
openedBossRules.screen.handleInput(panelInput)
T.check(forwardedBossRulesInput == panelInput,
  "the summary panel forwards the input passed by the Gen 3 dispatcher")
startRows[3].onSelect({}, sessionForHooks)
T.check(pcMenuOptions and pcMenuOptions.session == sessionForHooks,
  "PC menu action opens storage for the active session")
T.eq(pcMenuOptions and pcMenuOptions.startMode, "storage",
  "PC shortcut goes directly to Pokémon storage")
T.eq(pcMenuOptions and pcMenuOptions.closeOnExit, true,
  "B closes the direct storage shortcut instead of reopening the PC root")
T.check(startMenuClosed, "START is closed after the PC storage menu opens")
T.eq(table.concat(pcFlow, ","), "pc,start",
  "START is not closed before successful PC opening")
Runtime.emit("map.entered", { mapId = "EverGrandeCity_PokemonLeague_1F" })
local leagueRows = Runtime.call("ui.start_menu.items", function(_, items)
  return items
end, {}, { { id = "save", label = "SAVE" } })
T.eq(#leagueRows, 1, "PC is hidden in the League by default")

local vm = {
  store = store,
  ctx = {
    mode = "bytecode", status = "running",
    pc = { listKey = "test", index = 2 },
  },
}
local scriptContext = { runner = vm, save = { gen3 = sessionForHooks } }
local selectedPartyBefore = sessionForHooks.party
local selectedOverlayBefore = sessionForHooks.move_overlay
local vanillaCalls = 0
local pendingPoll = function() return false end
local deferred = Runtime.call("script.command", function()
  vanillaCalls = vanillaCalls + 1
  vm.ctx.nativePoll = pendingPoll
  return true
end, scriptContext, "trainerbattle", { trainer = 265, type = 0 })
T.eq(deferred, true, "boss command yields while the selection is open")
T.eq(vanillaCalls, 0, "vanilla command waits for a choice")
T.eq(vm.ctx.mode, "native", "the runner enters native wait mode")
T.eq(partyMenuOptions.count, 2, "trainer.party hook changes the selection maximum")
partyMenuOptions.onSelect({ 3, 1 })
T.eq(vm.ctx.nativePoll(), false, "resumed vanilla battle keeps its poll installed")
T.eq(vanillaCalls, 1, "vanilla boss command resumes once")
T.check(sessionForHooks.party[1].level == 8
    and sessionForHooks.party[2].level == 4,
  "selected order is installed before vanilla starts battle")
sessionForHooks.party[1].hp = 2
Runtime.emit("battle.ended", { result = "win" })
T.check(sessionForHooks.party == selectedPartyBefore
    and sessionForHooks.move_overlay == selectedOverlayBefore,
  "battle end restores party and overlay tables")
T.check(selectedPartyBefore[3].hp == 2,
  "battle HP changes remain on the original Pokémon")

local menuOpenCount = 0
package.loaded["src.ui.game3.party_menu"].show = function(_, _, opts)
  menuOpenCount = menuOpenCount + 1
  partyMenuOptions = opts
end
local ordinaryCalls = 0
Runtime.call("script.command", function() ordinaryCalls = ordinaryCalls + 1 end,
  scriptContext, "trainerbattle", { trainer = 999, type = 0 })
T.eq(ordinaryCalls, 1, "ordinary trainers pass through without a selection menu")
T.eq(menuOpenCount, 0, "ordinary trainers never open the party selector")

store.flags[flags.trainerFlagId(265)] = true
local rematchCalls = 0
Runtime.call("script.command", function() rematchCalls = rematchCalls + 1 end,
  scriptContext, "trainerbattle", { trainer = 265, type = 0 })
T.eq(rematchCalls, 1, "a previously defeated boss passes through")
T.eq(menuOpenCount, 0, "a previously defeated boss never opens the selector")
store.flags[flags.trainerFlagId(265)] = nil

local experience = Runtime.call("exp.gain", function() return 250 end, {
  mon = { level = 4, exp = 450, growthRate = 0 },
})
T.eq(experience, 50, "EXP is clamped to the exact first level-cap threshold")
local removeExpMultiplier = Runtime.hooks:wrap("exp.gain", function(next, ctx)
  return math.floor(next(ctx) * 100)
end, 0, "exp_qol")
local multipliedExperience = Runtime.call("exp.gain", function() return 250 end, {
  mon = { level = 4, exp = 450, growthRate = 0 },
  battle = { session = { options = { expQolMultiplier = 100 } } },
})
T.eq(multipliedExperience, 50,
  "an EXP QoL x100 multiplier cannot push a gain beyond the current cap")
removeExpMultiplier()
local blockedExperience = Runtime.call("exp.gain", function() return 250 end, {
  mon = { level = 5, exp = 500, growthRate = 0 },
})
T.eq(blockedExperience, 0, "EXP is blocked at the current cap")

local candyCalls = 0
local ok, kind = Runtime.call("item.use", function()
  candyCalls = candyCalls + 1
  return true, "used", "used"
end, {}, nil, 68, 2, {})
T.eq(ok, false, "Rare Candy is refused at the cap")
T.eq(kind, "noeffect", "Rare Candy refusal uses the no-effect result")
T.eq(candyCalls, 0, "blocked Rare Candy does not reach vanilla item use")

run.release()
for name, value in pairs(savedLoaded) do package.loaded[name] = value end
GameVersion.set(oldVersion)
T.finish("g1r_emerald_level_caps")
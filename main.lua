local LEAGUE_MAPS = {
  EverGrandeCity = true,
  EverGrandeCity_PokemonLeague_1F = true,
  EverGrandeCity_PokemonLeague_2F = true,
  EverGrandeCity_SidneysRoom = true,
  EverGrandeCity_PhoebesRoom = true,
  EverGrandeCity_GlaciasRoom = true,
  EverGrandeCity_DrakesRoom = true,
  EverGrandeCity_ChampionsRoom = true,
  EverGrandeCity_Hall1 = true,
  EverGrandeCity_Hall2 = true,
  EverGrandeCity_Hall3 = true,
  EverGrandeCity_Hall4 = true,
  EverGrandeCity_Hall5 = true,
  EverGrandeCity_HallOfFame = true,
}

local BOSSES = {
  { name = "Route 103 Rival", ids = { 520, 526, 523, 529, 535, 532 }, level = 5, cap = 5, milestone = true },
  { name = "Roxanne", ids = { 265 }, level = 15, cap = 15, milestone = true },
  { name = "Brawly", ids = { 266 }, level = 19, cap = 19, milestone = true },
  { name = "Route 110 Rival", ids = { 521, 527, 524, 530, 536, 533 }, level = 20, cap = 20, milestone = true },
  { name = "Wally Mauville", ids = { 656 }, level = 16, cap = 20 },
  { name = "Wattson", ids = { 267 }, level = 24, cap = 24, milestone = true },
  { name = "Tabitha Mt. Chimney", ids = { 597 }, level = 22, cap = 24 },
  { name = "Maxie Mt. Chimney", ids = { 602 }, level = 25, cap = 25, milestone = true },
  { name = "Flannery", ids = { 268 }, level = 29, cap = 29, milestone = true },
  { name = "Norman", ids = { 269 }, level = 31, cap = 31, milestone = true },
  { name = "Shelly Weather Institute", ids = { 32 }, level = 28, cap = 31 },
  { name = "Route 119 Rival", ids = { 522, 528, 525, 531, 537, 534 }, level = 31, cap = 31 },
  { name = "Winona", ids = { 270 }, level = 33, cap = 33, milestone = true },
  { name = "Tabitha Magma Hideout", ids = { 732 }, level = 33, cap = 33 },
  { name = "Maxie Magma Hideout", ids = { 601 }, level = 39, cap = 39, milestone = true },
  { name = "Matt", ids = { 30 }, level = 34, cap = 39 },
  { name = "Tate and Liza", ids = { 271 }, level = 42, cap = 42, milestone = true, double = true },
  { name = "Mossdeep Space Center", ids = { 734, 514 }, level = 44, cap = 44, milestone = true, multi = true },
  { name = "Shelly Seafloor Cavern", ids = { 33 }, level = 37, cap = 44 },
  { name = "Archie", ids = { 34 }, level = 43, cap = 44 },
  { name = "Juan", ids = { 272 }, level = 46, cap = 46, milestone = true },
  { name = "Wally Victory Road", ids = { 519 }, level = 45, cap = 46 },
  { name = "Sidney", ids = { 261 }, level = 49, cap = 49, milestone = true },
  { name = "Phoebe", ids = { 262 }, level = 51, cap = 51, milestone = true },
  { name = "Glacia", ids = { 263 }, level = 53, cap = 53, milestone = true },
  { name = "Drake", ids = { 264 }, level = 55, cap = 55, milestone = true },
  { name = "Wallace", ids = { 335 }, level = 58, cap = 58, milestone = true },
  { name = "Steven", ids = { 804 }, level = 78, cap = 78, milestone = true },
}

local BOSS_BY_ID = {}
local BOSS_RULES_LAYER = "g1r_emerald_boss_rules"
for _, boss in ipairs(BOSSES) do
  for _, trainerId in ipairs(boss.ids) do
    BOSS_BY_ID[trainerId] = boss
  end
end

local function capFromDefeated(isDefeated)
  for _, boss in ipairs(BOSSES) do
    if boss.milestone and not isDefeated(boss) then return boss.cap end
  end
  return nil
end

local function summaryRows(isDefeated, enabled)
  local nextBoss
  for _, boss in ipairs(BOSSES) do
    if boss.milestone and not isDefeated(boss) then
      nextBoss = boss
      break
    end
  end

  local rows = {
    { label = "CURRENT LEVEL CAP", right = nextBoss and ("Lv. " .. nextBoss.cap) or "NONE" },
    { label = "CAP ENFORCEMENT", right = enabled and "ON" or "OFF" },
    { label = "NEXT MILESTONE", right = nextBoss and nextBoss.name or "All milestones cleared" },
  }
  for _, boss in ipairs(BOSSES) do
    if boss.milestone then
      local state = isDefeated(boss) and "CLEARED"
        or (boss == nextBoss and "NEXT" or "LOCKED")
      rows[#rows + 1] = {
        label = boss.name .. " (Lv. " .. boss.cap .. ")",
        right = state,
      }
    end
  end
  return rows
end

local function applyPartyOrder(session, order)
  local snapshot = {
    session = session,
    party = session.party,
    overlay = session.move_overlay,
  }
  local selectedParty, selectedOverlay = {}, snapshot.overlay and {} or nil
  for index, slot in ipairs(order) do
    selectedParty[index] = snapshot.party[slot]
    if selectedOverlay then selectedOverlay[index] = snapshot.overlay[slot] end
  end
  session.party = selectedParty
  session.move_overlay = selectedOverlay
  return snapshot
end

local function restorePartySnapshot(snapshot)
  if not snapshot then return false end
  snapshot.session.party = snapshot.party
  snapshot.session.move_overlay = snapshot.overlay
  return true
end

return function(mod)
  mod.options:define({
    { key = "pc_anywhere", label = "PC ANYWHERE", type = "toggle", default = true },
    { key = "disable_pc_league", label = "DISABLE PC IN LEAGUE", type = "toggle", default = true },
    { key = "boss_selection", label = "BOSS PARTY SELECTION", type = "toggle", default = true },
    { key = "level_caps", label = "AUTOMATIC LEVEL CAPS", type = "toggle", default = false },
  })
  mod.exports.bosses = BOSSES
  mod.exports.capFromDefeated = capFromDefeated
  mod.exports.summaryRows = summaryRows
  mod.exports.applyPartyOrder = applyPartyOrder
  mod.exports.restorePartySnapshot = restorePartySnapshot

  local privateModules, warned = {}, {}
  local function privateModule(name, reason)
    local cached = privateModules[name]
    if cached ~= nil then return cached or nil end
    local ok, value = pcall(require, name)
    if not ok or type(value) ~= "table" then
      privateModules[name] = false
      if not warned[name] then
        warned[name] = true
        mod.log:warn("%s; %s", reason, tostring(value))
      end
      return nil
    end
    privateModules[name] = value
    return value
  end

  local openBossRules
  local currentMap
  mod.events:on("map.entered", function(ev)
    currentMap = ev and ev.mapId or nil
  end)

  mod.hooks:wrap("ui.start_menu.items", function(next, game, items)
    local out = next(game, items)
    if not mod.options:get("pc_anywhere") or type(out) ~= "table" then
      return out
    end
    for _, item in ipairs(out) do
      if item.id == "retire" or item.id == "retire_frontier"
          or item.id == "pyramid_bag" or item.id == "trainer_link" then
        return out
      end
    end
    -- Private require: the Gen 3 start-menu hook carries no session or menu kind;
    -- the existing link-room predicate is the available mode check (cf. src/ui/game3/start_menu.lua).
    local Link = privateModule("src.core.game3.link", "Link state is unavailable; hiding PC entry")
    local linkOk, inLinkRoom = false, true
    if Link and Link.inLinkRoom then linkOk, inLinkRoom = pcall(Link.inLinkRoom) end
    if not linkOk or inLinkRoom then return out end

    local mapId = currentMap
    if not mapId and game and game.save and game.save.position then
      mapId = game.save.position.map
    end
    if mod.options:get("disable_pc_league") and LEAGUE_MAPS[mapId] then
      return out
    end

    local saveIndex
    for index, item in ipairs(out) do
      if item.id == "save" then
        saveIndex = index
        break
      end
    end
    if not saveIndex then return out end

    table.insert(out, saveIndex, {
      id = "boss_rules",
      label = "CAPS",
      onSelect = function(selectedGame, selectedSession)
        if openBossRules then openBossRules(selectedGame or game) end
      end,
    })
    table.insert(out, saveIndex + 1, {
      id = "pc_anywhere",
      label = "PC",
      onSelect = function(selectedGame, selectedSession)
        -- Private require: the public BoxMenu facade always opens the root PC menu;
        -- startMode=storage is needed to keep the player's item PC inaccessible (cf. src/ui/game3/pc_menu.lua).
        local PcMenu = privateModule("src.ui.game3.pc_menu", "Storage PC is unavailable")
        if not PcMenu then return end
        local session = selectedSession
        if not session then
          -- Private require: a field menu should carry its session, but older starts may omit it.
          local Runtime = privateModule("src.core.game3.runtime", "Current save is unavailable")
          session = Runtime and Runtime.getSession and Runtime.getSession() or nil
        end
        if not session then
          mod.log:warn("Could not open PC storage because the active save is unavailable")
          return
        end
        -- Private require: opening the storage submenu directly bypasses Hud.openPc,
        -- which normally owns the PC-on sound (cf. src/ui/game3/hud.lua).
        pcall(function()
          require("src.core.game3.audio").playSe(
            require("src.core.game3.se_ids").resolve("SE_PC_ON"))
        end)
        local ok, err = pcall(PcMenu.show, { session = session, startMode = "storage" })
        if not ok then
          mod.log:error("Could not open PC storage: %s", tostring(err))
          return
        end
      end,
    })
    return out
  end)

  local pendingParty
  local function restoreParty(reason)
    if not pendingParty then return false end
    restorePartySnapshot(pendingParty)
    pendingParty = nil
    if reason ~= "battle.ended" then
      mod.log:warn("Restored the full party after an interrupted boss selection (%s)", reason)
    end
    return true
  end

  mod.events:on("battle.ended", function()
    restoreParty("battle.ended")
  end)
  mod.events:on("save.writing", function()
    restoreParty("save.writing")
  end)
  mod.events:on("map.entered", function()
    restoreParty("map.entered")
  end)

  local function usableCount(party)
    local count = 0
    for _, mon in ipairs(party or {}) do
      if mon and not mon.isEgg and (tonumber(mon.hp) or 0) > 0 then
        count = count + 1
      end
    end
    return count
  end

  local function isDefeated(boss, Flags, store, ctx)
    for _, trainerId in ipairs(boss.ids) do
      local flagId = Flags.trainerFlagId(trainerId)
      if Flags.getFlag(store, ctx, flagId) then return true end
    end
    return false
  end

  openBossRules = function(game)
    -- Private require: Gen 3 has no content.screens target; its modals are pushed on this stack.
    local Stack = privateModule("src.ui.game3.stack", "Boss summary screen is unavailable")
    -- Private require: mod.ui.ListMenu uses the Gen 1 layout, while Emerald needs its 240x160 list widget.
    local ListMenu = privateModule("src.ui.game3.list_menu", "Boss summary list is unavailable")
    -- Private require: the Gen 3 list widget uses the engine's FRLG window and font renderer.
    local Window = privateModule("src.ui.game3.window", "Boss summary frame is unavailable")
    local Flags = privateModule("src.core.game3.scripting.flags", "Boss progress is unavailable")
    local Space = privateModule("src.core.game3.scripting.space", "Boss progress is unavailable")
    if not (Stack and ListMenu and Window) then return end

    local rows
    if Flags and Space and Space.store then
      rows = summaryRows(function(boss)
        return isDefeated(boss, Flags, Space.store)
      end, mod.options:get("level_caps"))
    else
      rows = {
        { label = "CURRENT LEVEL CAP", right = "UNKNOWN" },
        { label = "BOSS PROGRESSION", right = "UNAVAILABLE" },
      }
    end
    for _, row in ipairs(rows) do
      local label, right = row.label, row.right
      row.print = function(item, x, y)
        Window.printPx(label, x, y, { maxWidth = 136 })
        Window.printPx(right, 170, y, { maxWidth = 56 })
      end
    end

    local list = ListMenu.new({
      template = Window.template(2, 7, 26, 12),
      frame = "none",
      items = rows,
      maxShowed = 6,
      itemX = 8,
      cursorX = 0,
      upTextY = 0,
      rowHeight = 16,
      scrollMultiple = "dpad",
      onSelect = function() end,
      onCancel = function() Stack.pop(BOSS_RULES_LAYER) end,
    })
    local screen = {
      update = function(dt) list:update(dt) end,
      handleInput = function(input) list:handleInput(input) end,
      draw = function()
        Window.fill(Window.template(0, 0, 30, 20), 0, 0, 0, 1)
        Window.fixedStdFrame(Window.template(2, 3, 26, 2))
        Window.print("CAPS", 4, 4)
        Window.fixedStdFrame(Window.template(2, 7, 26, 12))
        list:draw()
      end,
    }
    Stack.push(BOSS_RULES_LAYER, screen, { hideBelow = true, fullscreen = true })
  end

  local function currentLevelCap(Flags, store)
    return capFromDefeated(function(boss)
      return isDefeated(boss, Flags, store)
    end)
  end

  local function reorderedParty(session, order)
    pendingParty = applyPartyOrder(session, order)
  end

  local function chosenOrCurrent(order, party, maxCount)
    if type(order) == "table" then return order end
    local fallback = {}
    for slot, mon in ipairs(party or {}) do
      if mon and not mon.isEgg and (tonumber(mon.hp) or 0) > 0 then
        fallback[#fallback + 1] = slot
        if #fallback >= maxCount then break end
      end
    end
    return fallback
  end

  mod.hooks:wrap("script.command", function(next, ctx, op, row)
    if not mod.options:get("boss_selection") or op ~= "trainerbattle" then
      return next(ctx, op, row)
    end
    if type(row) ~= "table" then return next(ctx, op, row) end
    local trainerId = tonumber(row.trainer or row[1])
    local battleType = tonumber(row.type) or 0
    local boss = trainerId and BOSS_BY_ID[trainerId]
    if not boss or battleType == 5 or battleType == 7 then
      return next(ctx, op, row)
    end

    local vm = ctx and ctx.runner
    local vmCtx = vm and vm.ctx
    local session = ctx and ctx.save and ctx.save.gen3
    if not (vm and vmCtx and session and type(session.party) == "table") then
      return next(ctx, op, row)
    end

    -- Private require: trainer flags are checked by this opcode before battle setup;
    -- the hook context has no defeated-trainer query (cf. src/core/game3/scripting/ops_a.lua).
    local Flags = privateModule("src.core.game3.scripting.flags", "Boss flags are unavailable; skipping party selection")
    -- Private require: foeFromId is the engine's effective trainer-party builder;
    -- there is no public trainer runtime facade (cf. src/core/game3/scripting/trainers.lua).
    local Trainers = privateModule("src.core.game3.scripting.trainers", "Trainer teams are unavailable; skipping party selection")
    -- Private require: this is the same hook bus BattleBridge uses to apply trainer.party;
    -- the public hook API registers wrappers but does not expose a call method (cf. src/core/game3/battle_bridge.lua).
    local ModRuntime = privateModule("src.mods.Runtime", "Trainer party hooks are unavailable")
    -- Private require: battle bridge converts numeric foe data to named hook rows;
    -- use the same conversion so other mods see their documented hook payload (cf. src/mods/Gen3Compat.lua).
    local Gen3Compat = privateModule("src.mods.Gen3Compat", "Trainer party conversion is unavailable")
    -- Private require: this is the existing link-room state query used by the start menu;
    -- no mod-facing link-state query is exposed (cf. src/ui/game3/start_menu.lua).
    local Link = privateModule("src.core.game3.link", "Link state is unavailable; skipping party selection")
    -- Private require: the Gen 3 facade forces mode=list and cannot open choose_multi;
    -- choose_multi is implemented only by this screen (cf. src/mods/Gen3Compat.lua).
    local PartyMenu = privateModule("src.ui.game3.party_menu", "Multi-party selection UI is unavailable")
    if not (Flags and Trainers and ModRuntime and Gen3Compat and Link and PartyMenu) then
      return next(ctx, op, row)
    end
    if type(Link.inLinkRoom) ~= "function" then return next(ctx, op, row) end
    local linkOk, inLinkRoom = pcall(Link.inLinkRoom)
    if not linkOk or inLinkRoom then return next(ctx, op, row) end
    if isDefeated(boss, Flags, vm.store, vm.ctx) then return next(ctx, op, row) end

    local foe = Trainers.foeFromId(trainerId)
    local foeParty = foe and foe.party
    if type(foeParty) == "table" and #foeParty > 0 and ModRuntime.call then
      local named = Gen3Compat.partyNames(foeParty)
      local hooked = ModRuntime.call("trainer.party", function(_, _, party)
        return party
      end, foe.trainerClass, trainerId, named)
      if type(hooked) == "table" and #hooked > 0 then
        foeParty = Gen3Compat.partyNums(hooked)
      end
    end
    local foeCount = type(foeParty) == "table" and #foeParty or 0
    local partyCount = usableCount(session.party)
    local maxCount = math.min(foeCount, partyCount, 6)
    local minCount = (battleType == 4 or battleType == 6 or battleType == 7 or battleType == 8) and 2 or 1
    if boss.multi or partyCount <= 1 or maxCount < minCount then
      return next(ctx, op, row)
    end

    local selectionReady, selectionStarted = false, false
    local selectedOrder
    local selectionPoll
    local function openSelection()
      local ok, err = pcall(PartyMenu.show, session.party, session.move_overlay, {
        session = session,
        mode = "choose_multi",
        count = maxCount,
        eligible = function(_, mon)
          return mon and not mon.isEgg and (tonumber(mon.hp) or 0) > 0
        end,
        onSelect = function(order)
          order = chosenOrCurrent(order, session.party, maxCount)
          if #order < minCount then
            openSelection()
            return
          end
          selectedOrder = order
          selectionReady = true
        end,
      })
      if not ok then
        mod.log:warn("Could not open boss party selection: %s", tostring(err))
        return false
      end
      return true
    end

    vmCtx.mode = "native"
    vmCtx.status = "waiting"
    selectionPoll = function()
      if not selectionReady then return false end
      if selectionStarted then return false end
      selectionStarted = true
      reorderedParty(session, selectedOrder)
      local ok, err = pcall(next, ctx, op, row)
      if not ok then
        restoreParty("battle start failure")
        vmCtx.nativePoll = nil
        vmCtx.mode = "bytecode"
        vmCtx.status = "halted"
        mod.log:error("Could not resume boss battle: %s", tostring(err))
        return false
      end
      if vmCtx.nativePoll == selectionPoll then
        vmCtx.nativePoll = nil
        vmCtx.mode = "bytecode"
        vmCtx.status = "running"
        return true
      end
      return false
    end
    vmCtx.nativePoll = selectionPoll

    if not openSelection() then
      vmCtx.nativePoll = nil
      vmCtx.mode = "bytecode"
      vmCtx.status = "running"
      return next(ctx, op, row)
    end
    return true
  end)

  mod.hooks:wrap("exp.gain", function(next, ctx)
    if not mod.options:get("level_caps") then return next(ctx) end
    local mon = ctx and ctx.mon
    if not mon then return next(ctx) end

    -- Private require: level growth is implemented by the engine's experience model;
    -- no mod API exposes the per-species growth lookup (cf. src/core/game3/battle/experience.lua).
    local Experience = privateModule("src.core.game3.battle.experience", "Growth-rate lookup is unavailable; leaving EXP unchanged")
    -- Private require: the game's species growth tables provide exact level thresholds;
    -- recomputing their formulas in a mod would duplicate private game data (cf. src/core/game3/summary_data.lua).
    local SummaryData = privateModule("src.core.game3.summary_data", "EXP thresholds are unavailable; leaving EXP unchanged")
    -- Private require: this is the active story-flag store used by script opcodes;
    -- no public query exposes defeated trainer flags (cf. src/core/game3/scripting/space.lua).
    local Space = privateModule("src.core.game3.scripting.space", "Trainer progress is unavailable; leaving EXP unchanged")
    -- Private require: trainer milestone flags use the scripting flag helpers;
    -- no public trainer-progress facade exists (cf. src/core/game3/scripting/flags.lua).
    local Flags = privateModule("src.core.game3.scripting.flags", "Trainer progress is unavailable; leaving EXP unchanged")
    if not (Experience and SummaryData and Space and Flags and Space.store) then
      return next(ctx)
    end

    local cap = currentLevelCap(Flags, Space.store)
    if not cap then return next(ctx) end
    local level = tonumber(mon.level) or 1
    if level >= cap then return 0 end
    local amount = next(ctx)
    local growthRate = Experience.growthRate(mon)
    local targetExp = SummaryData.expForLevel(growthRate, cap)
    local remaining = math.max(0, targetExp - (tonumber(mon.exp) or 0))
    return math.min(math.max(0, tonumber(amount) or 0), remaining)
  end, 10000)

  mod.hooks:wrap("item.use", function(next, game, _unused, itemId, partySlot, bag)
    if not mod.options:get("level_caps") or tonumber(itemId) ~= 68 then
      return next(game, _unused, itemId, partySlot, bag)
    end

    -- Private require: field-item hooks carry the game but not its live session;
    -- Runtime is the engine's session owner (cf. src/core/game3/item_use.lua).
    local Runtime = privateModule("src.core.game3.runtime", "Current save is unavailable; allowing item use")
    -- Private require: caps are based on defeated trainer flags in the script store;
    -- no public trainer-progress facade exists (cf. src/core/game3/scripting/space.lua).
    local Space = privateModule("src.core.game3.scripting.space", "Trainer progress is unavailable; allowing item use")
    -- Private require: the game exposes trainer flags through its script helper;
    -- no public trainer-progress facade exists (cf. src/core/game3/scripting/flags.lua).
    local Flags = privateModule("src.core.game3.scripting.flags", "Trainer progress is unavailable; allowing item use")
    if not (Runtime and Runtime.getSession and Space and Space.store and Flags) then
      return next(game, _unused, itemId, partySlot, bag)
    end

    local session = Runtime.getSession()
    local mon = session and session.party and session.party[tonumber(partySlot) or 0]
    local cap = currentLevelCap(Flags, Space.store)
    if mon and cap and (tonumber(mon.level) or 1) >= cap then
      return false, "noeffect", "The current level cap prevents this Pokemon from growing."
    end
    return next(game, _unused, itemId, partySlot, bag)
  end)
end
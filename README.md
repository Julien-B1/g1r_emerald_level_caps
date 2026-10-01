# Emerald Boss Rules

This mod adds PC storage access, ordered party selection before major Emerald boss fights, an optional automatic level cap, and a START-menu progression summary. **Persona: the Challenge Tuner.**

## Development

This workspace keeps mods outside the game checkout. On Windows, create a link in the LÖVE save directory from a PowerShell opened at the workspace root:

```powershell
$modDir = Join-Path $env:APPDATA "love\pokemon-love2d\mods"
New-Item -ItemType Directory -Force -Path $modDir | Out-Null
New-Item -ItemType SymbolicLink -Path (Join-Path $modDir "g1r_emerald_level_caps") -Target (Resolve-Path ".\mods\g1r_emerald_level_caps")
```

Run the source checkout with `POKEPORT_DEV=1` to enable F5 hot reload. Do not make a copy of this mod inside `gen1recomp/`; the loader combines its source `mods/` folder with the LÖVE save-directory mods.

## Try it

From the workspace root, run:

```powershell
python gen1recomp/tools/modkit.py --repo gen1recomp validate mods/g1r_emerald_level_caps --base imported
python gen1recomp/tools/modkit.py --repo gen1recomp lint mods/g1r_emerald_level_caps
$env:GEN1RECOMP_ROOT = "gen1recomp"; $env:G1R_EMERALD_LEVEL_CAPS_MOD_PATH = "mods/g1r_emerald_level_caps"; luajit mods/g1r_emerald_level_caps/tests/g1r_emerald_level_caps_test.lua
```

Pull requests targeting `main` or `master` run the test, strict validation, lint, and package checks. Merging a pull request into `main` publishes a tagged GitHub Release with an installable ZIP. The first release uses `0.1.0`; later merged PRs automatically increment the patch version.

Enable **Emerald Boss Rules** in F10. Options are **PC ANYWHERE** (on), **DISABLE PC IN LEAGUE** (on), **BOSS PARTY SELECTION** (on), and **AUTOMATIC LEVEL CAPS** (off). **BOSS RULES** in START shows the current cap, enforcement status, and milestone progression. The PC shortcut opens directly to Pokémon storage; the player's item PC is intentionally unavailable. During selection, the first chosen Pokémon leads. B's cancel confirmation falls back to the current healthy party order, truncated to the opponent's party size. Double battles require two selected Pokémon. The Space Center multi battle keeps its vanilla party-selection flow.

## Manual checks

Use a copy of your own save. Check Roxanne with a partial party on both victory and defeat, Tate & Liza with two selected Pokémon, an ordinary trainer, and a previously defeated boss. Save immediately after a boss fight and confirm the full team is present. Confirm PC storage appears on the field, is hidden in the League by default, and never offers the player's item PC. With level caps on, test XP and Rare Candy at and below a cap.

The mod does not change the daycare, trades, or received Pokémon, so those can exceed a cap. Unselected held Exp. Share recipients receive no battle experience while the party is reduced. Space Center retains vanilla selection; this mod does not add a second selector there.
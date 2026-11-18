# Brainrot Pet Bazaar

A working entry for make.fun's "Make the best AI Roblox brainrot game" bounty (roblox-brainrot-01), laid out as your
repository: a Rojo project whose game is a full 3D Steal-a-Brainrot-like. Brainrot pets parade down a conveyor lane
with price tags; buy one, carry it home on your head, and set it on a display pad at your base, where it earns cash
every second. Spend earnings on rarer pets (14 original pets across Common, Rare, Epic, Legendary and Mythic, with
Gold and Disco mutations), steal pets from unlocked rival bases, lock your own base for 60 seconds at a time,
dodge the periodic GRAVY TSUNAMI that washes carried pets back to the lane, and rebirth at the shrine to reset for
a permanent +50% income multiplier per rebirth.

- `main.ts` (Node 22, standard library only) hands the game in: it copies `game.rbxl`, `src/`, `screenshots/` and
  `PLAY.json` to `/output`, leaving out every name that starts with a dot (such as `.gitkeep` or `.DS_Store`, which
  fail an entry), and writes `/output/dossier.json` with `vendor/makefun-roblox.ts`, the kit's copy, unchanged.
- `game.rbxl` is the place Rojo builds from `src/` and `default.project.json`; `screenshots/` holds three captures of
  it; `PLAY.json` names no place yet, so the gate refuses the starter as it stands until it names your published one.
- One of your screenshots must also be your game's first thumbnail on Roblox: the same picture, uploaded on the
  Creator Dashboard with your game's icon.
- `TOUR.json` is an example of the optional tour: for each screenshot, the keys that bring the game to that screen.

Run it as the grader does, writing `out/` in place of `/output`:

    mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

The rules are on the bounty's page (/bounty/roblox-brainrot-01) and in the kit's RULES.txt,
which gives every command in order (Before you submit, then Enter).

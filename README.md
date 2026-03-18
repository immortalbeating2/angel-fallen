# angel-fallen

Angel Fallen is a top-down 2D action roguelike built with Godot 4.

Current playable prototype includes:
- Main menu -> game scene transition
- Player movement, sprint, stamina
- Auto-attack combat against spawned enemies
- Room combat flow (clear room then press `E` for next)
- XP leveling with 3-choice level-up panel
- Shop room purchases and safe-camp forge/route choices
- Boss room milestones at Room 4/8/12/15 with chapter progression pacing
- Boss phase behavior (dash + pulse) driven by HP thresholds
- Chapter-based environment hazards (water/spore/lava/ice/void) with status gauges
- Hazard visual feedback (chapter tint + damage flash) and boss-room hazard amplification
- Meta progression save with run summary rewards
- Route-based victory ending unlock and achievement tracking
- Run result panel with ending/achievement unlock summary
- Main menu meta-upgrade shop (permanent run-start bonuses)
- Chapter transition narrative panel after boss rooms (route choice impacts alignment)
- Data-driven narrative content config (`data/balance/narrative_content.json`)
- Chapter intro panel (rooms 1/5/9/13) with hazard briefing and active blessing display
- Narrative event rooms (chapter event choices with resource/route consequences)
- Memory fragments unlocked from chapter bosses and tracked in meta save
- Blessing system now safely swaps (no unintended stacking from repeated choices)
- Run result panel includes a narrative-choice timeline summary
- Main menu memory archive can cycle unlocked fragment full text

## Run

```bash
godot --path . scenes/main_menu/main_menu.tscn
```

Controls:
- `WASD` / Arrows: Move
- `Shift`: Sprint
- `E`: Next room (non-combat rooms / cleared combat rooms)
- Shop room: `1/2/3/4` buy slot, `R` restock
- Safe camp: `F` damage forge (3 ore), `G` speed forge (5 ore)
- Safe camp route: `Q` holy route, `V` void route
- Chapter transition panel: `1/2` choose route, `E` confirm continue
- Narrative event panel: `1/2` choose event branch, `E` / `Esc` continue
- Chapter intro panel: `E` / `Esc` begin chapter
- Boss rooms: defeat 1 boss target to unlock doors and progress chapter
- Accessory drops: auto-equip up to 2 slots on pickup (extra converts to gold)
- Environment gauges: Frostbite/Void Corruption shown on HUD (builds in hazard rooms, decays in shop/camp)
- Accessories now include environment resistance bonuses (frost/void mitigation)
- `Esc`: Back to menu
- Run result panel: `E` / `Esc` to return menu
- Main menu memory archive: click `Review Next Memory Fragment` to cycle unlocked fragments

Chapter transition blessing effects:
- `holy_vow`: +armor, +frost resistance, immediate heal
- `void_oath`: +weapon damage, +crit chance, -armor tradeoff
- Blessings are mutually exclusive: selecting a new blessing replaces the previous one

Meta progression:
- Run ends on death / victory / retreat, shows result panel, then returns to menu
- Main menu shows meta currency, run stats, and last run reward
- Main menu also shows achievement/ending unlock progress and meta upgrades
- Main menu now lists unlocked memory fragments
- Save file path: `user://meta_save.json`

## Validate data

```bash
python scripts/validate_configs.py
python scripts/check_resources.py
```

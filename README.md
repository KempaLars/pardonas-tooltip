# Pardona's ToolTips

A tooltip addon for **World of Warcraft: Forever** (Interface 16001, Mainline client with the Midnight API).

> **Beta** – this addon is in an early stage. The current version covers the tooltip appearance, player and mob information (including spec), item level, gear comparison and disenchant/price information. Please report problems in the GitHub issues.

## Features (current state)

### Appearance

- **Position** for tooltips with the default anchor (for example units in the world):
  mouse cursor (default, follows the mouse with a small offset), top left, top right,
  bottom left, bottom right, screen center, or Blizzard default (unchanged).
  The corner positions use an adjustable edge distance (0–200 px, default 20).
  Tooltips of bag slots and buttons keep their usual place.
- **Scale** from 50 % to 200 % (steps of 5 %), applied to the tooltip and the comparison tooltips.
- **Font**: Friz Quadrata, Arial Narrow, Skurri or Morpheus. If another addon provides
  LibSharedMedia-3.0, its fonts are offered as well (the library is not included).
  Separate font sizes for the header line and the text; small lines are drawn two points
  smaller than the text.
- **Color sets** for background, background opacity, border and the colors of the
  addon's own lines:
  - *Blizzard* – the standard look
  - *Dark* – almost black background (about 90 %), thin gray border
  - *High contrast* – black background, white border, strong text colors
  - *Pardona* – deep night blue with a subtle golden border
- **Color border** (on by default): items in their quality color, players in their class
  color, NPCs in their reaction color (hostile, neutral, friendly).

### Players and mobs

Blizzard's lines are kept. Existing lines are only recolored; the addon's own lines are
added at the bottom. If the unit under the mouse is also your target, its values are read
through your target, which the game often reveals in more detail.

- **Players**: name in class color, guild line in the guild color of the color set, class
  name in class color.
- **Mobs**: classification appended to the level line – *(Elite)*, *(Rare)*,
  *(Rare Elite)* or *(Boss)*. Normal mobs get nothing.
- **Health text** on the health bar below the tooltip, for example `1,234 / 2,000 (62%)`
  (number format follows the client language). The game does not reveal the exact health
  of every unit (for example players outside your group); then only the percentage is
  shown, for example `62%`. If even the percentage is hidden from addons, the game may still
  let the addon pass it on for display; otherwise the text is left out.
- **Target** of the unit in class or reaction color, or `>> YOU <<` if it targets you.
- **Speed**: current movement speed in percent of normal run speed, updated live while the
  tooltip shows the unit.
- **Resource**: the unit's main resource with its name in your language, for example
  `Mana: 1,815 / 2,000`, `Energy: 100 / 100` or `Rage: 0 / 100`. If only the percentage is
  readable: `Mana: 80%`. Units without a resource (maximum 0) get no line, and neither do
  units whose values are hidden completely.
- **Item level** (players): average item level with one decimal. Your own character is
  calculated directly. Other players are inspected only out of combat, only when they can
  be inspected and are in range, at most one request every 1.5 seconds; results are kept
  for 10 minutes. If the result arrives while the tooltip still shows that player, the line
  is added. Inspect requests of other addons are not disturbed.
  The average covers the equipped slots except shirt and tabard (17 slots including the
  ranged slot); a two-handed weapon with an empty off-hand counts twice.
- **Spec** (players): the talent tree with the most points and the points of all trees, for
  example `Spec: Arms (31/20/0)`; on a tie both names, for example `Arms/Fury (20/20/11)`.
  No line without spent points. Your own character is read directly, other players with the
  same inspect request as the item level (same rules and cache). The line needs the game's
  talent tree functions; if the client does not offer them, it is not shown (`/ptt debug`
  tells whether they are available).

### Items

- **Item level** of equipment (weapons, armor, jewelry, shields, off-hand items), shown
  right-aligned in the title line as `iLvl 25`. If that place is already used, an own line
  `Item level: 25` is added instead. Consumables, materials, recipes and quest items get no
  item level. Works in the normal tooltip, chat link tooltips and Blizzard's comparison
  tooltips.
- **Always visible gear comparison** below the tooltip (normal tooltip and chat links) for
  equipment your character can wear (the character level is ignored). The numbers come from
  the same game function Blizzard uses for its "If you replace this item" section, so they
  match Blizzard's Shift comparison; stat names are the game's own, localized texts.
  - One block per equipped item: `Instead of <item>:` followed by the changed values
    (`+7 Armor` as gain, `-3 Stamina` as loss), or `no change`.
  - Rings and trinkets: one block for each equipped ring or trinket.
  - One-hand weapons: against the main hand, plus the off-hand if you can dual wield.
  - Two-hand weapons: one block against main and off-hand together.
  - Shields and off-hand items: against the off-hand, or against an equipped two-hand weapon.
  - Empty slot: `(empty slot)` with all values of the new item as gains.
  - No comparison for the item you are wearing and in the comparison tooltips.
  - Blizzard's own Shift comparison is not changed.
- **Hide the appearance collection hint** ("You haven't collected this appearance"); the line
  is removed before it is drawn, without leaving a gap.
- Lines of other addons (for example TradeSkillMaster or ArkInventory) are not changed.

### Prices and disenchanting

For disenchantable items – uncommon (green), rare (blue) and epic (purple) weapons and armor –
a block above the comparison shows:

- **Disenchant**: possible materials with chance and quantity, for example
  `75% Soul Dust (1–2) · 20% Greater Astral Essence (1–2) · 5% Large Glimmering Shard`.
  Long lists wrap onto indented lines. If you know Enchanting but your skill is too low,
  `(Enchanting 150 required)` is added. Material names come from the game in your language.
- **Disenchant value** (needs TradeSkillMaster): TSM's price source `Destroy`.
- **Recommendation** (needs TradeSkillMaster): *Vendor*, *Auction house* or *Disenchant*,
  whichever earns the most, for example `Recommendation: Disenchant (≈ 11s 52c)`.
  - Vendor: TSM `VendorSell` (or the game's sell price).
  - Auction house: TSM `DBMarket` (or `DBMinBuyout`) minus the auction house fee. Items with a
    low region sale rate (`DBRegionSaleRate`) or few sales per day (`DBRegionSoldPerDay`)
    count as slow sellers; their auction value is ignored and `(AH: slow seller)` is shown.
    Both figures are read with their decimals (for example a sale rate of 0.737), the same
    values TSM shows in its own tooltip.
  - Disenchant: TSM `Destroy` minus the auction house fee; only counted if you can disenchant
    the item yourself (Enchanting learned and skill high enough) or the item is not bound
    (you can send it to an alt).

When the block is shown: items that are not soulbound always get it; soulbound items only if
your character has learned Enchanting. Chat links and vendor items count as not bound unless
they bind when picked up.

The disenchanting table (Classic item levels) was built from the public tables on
[warcraft.wiki.gg: Disenchanting tables](https://warcraft.wiki.gg/wiki/Disenchanting_tables)
and [warcraft.wiki.gg: Disenchanting](https://warcraft.wiki.gg/wiki/Disenchanting)
(required skill), see `Data/Disenchant.lua`.

### General

- All changes take effect immediately, without `/reload`.
- English and German.

The addon respects the "secret values" of the Midnight API: values that the game hides from
addons are never compared or shown. A line whose values are hidden is simply left out, and
in combat or restricted content no inspect requests are made.

## Installation

1. Download the latest release from GitHub (or CurseForge, once available).
2. Extract the `PardonasToolTips` folder into
   `World of Warcraft\_forever_\Interface\AddOns\`.
3. Restart the game or type `/reload`.

## Optional addons

Pardona's ToolTips works on its own. These addons add features when they are installed:

| Addon | Adds |
| --- | --- |
| TradeSkillMaster | Prices, disenchant value and the sell recommendation |
| AtlasLoot Forever | Needed for the full item source feature (dungeon and raid boss loot, planned) |

Without them everything else works; only these parts are missing. The addon does not
include or change them, it only reads TradeSkillMaster's public API.

## Slash commands

| Command | Description |
| --- | --- |
| `/ptt` or `/pardonastooltips` | Open the options |
| `/ptt reset` | Reset all settings to their defaults |
| `/ptt debug` | Show what the game lets the addon read (see Troubleshooting) |
| `/ptt help` | List the commands |

If `/ptt` is used during combat, the options open as soon as combat ends.

## Troubleshooting

If a line is missing (for example the health text or the resource of another player), type
`/ptt debug`. The addon then prints to the chat what the game lets it read, for your character,
your mouseover unit, your target and – in a group – the first party member:

- whether the unit exists, its name and whether its GUID is readable (for the mouseover
  unit also whether it is the same unit as your target),
- health and maximum health, and the health percentage,
- the resource type with its name, current and maximum value, and the resource percentage,
- whether the game's functions for hidden values (`issecretvalue`, `C_Secrets`, percent
  functions) exist, and the `C_Secrets` checks for units,
- whether the talent tree functions exist and your own spec,
- which game events the addon skipped because this client does not know them.

Every value is shown as it is, as `secret` (the game hides it from addons) or as `nil`
(no value). Hover a unit with the mouse and type the command into the chat to include it.
Please add this output when you report a problem.

## Options

Open with `/ptt` or via *Options → AddOns → Pardona's ToolTips*.

**Appearance**

| Option | Default |
| --- | --- |
| Position | Mouse cursor |
| Edge distance (corners only) | 20 px |
| Scale | 100 % |
| Font | Friz Quadrata |
| Font size: header | 14 |
| Font size: text | 12 |
| Color set | Blizzard |
| Color border | On |

**Players & Mobs** (each can be switched off on its own)

| Option | Default |
| --- | --- |
| Name in class color | On |
| Guild color | On |
| Color class line | On |
| Health text | On |
| Target | On |
| Speed | On |
| Resource (mana, rage, energy …) | On |
| Item level (players) | On |
| Spec (players) | On |
| Classification (mobs) | On |

**Items**

| Option | Default |
| --- | --- |
| Item level on items | On |
| Show comparison | Always (choices: Always, Only with Shift, Off) |
| Hide appearance collection hint | On |

With *Only with Shift* the comparison appears and disappears as soon as Shift is pressed or
released.

**Prices & Disenchanting**

| Option | Default |
| --- | --- |
| Show disenchant chances | On |
| Show disenchant value | On |
| Show recommendation | On |
| Auction house fee | 5 % (0–20) |
| Slow seller: minimum sale rate | 0.10 (0.00–1.00) |
| Slow seller: minimum sold per day | 0.5 (0–20) |

If TradeSkillMaster is not loaded, the section says so; prices and the recommendation are
then disabled, the disenchant chances still work.

**General**

- *Reset settings* – restores all defaults.

## Planned

- Item sources (dungeon and raid boss loot with AtlasLoot Forever)
- Vendors and recipes

## License

Pardona's ToolTips is released under the [GNU General Public License v3.0](LICENSE).

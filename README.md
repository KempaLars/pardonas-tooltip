# Pardona's ToolTips

A tooltip addon for **World of Warcraft: Forever** (Interface 16001, Mainline client with the Midnight API).

> **Beta** – this addon is in an early stage. The current version covers the tooltip appearance, player and mob information, item level and gear comparison. Please report problems in the GitHub issues.

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
added at the bottom.

- **Players**: name in class color, guild line in the guild color of the color set, class
  name in class color.
- **Mobs**: classification appended to the level line – *(Elite)*, *(Rare)*,
  *(Rare Elite)* or *(Boss)*. Normal mobs get nothing.
- **Health text** on the health bar below the tooltip, for example `1,234 / 2,000 (62%)`
  (number format follows the client language).
- **Target** of the unit in class or reaction color, or `>> YOU <<` if it targets you.
- **Speed**: current movement speed in percent of normal run speed, updated live while the
  tooltip shows the unit.
- **Mana**: current and maximum mana when mana is the unit's main resource (no rage or energy).
- **Item level** (players): average item level with one decimal. Your own character is
  calculated directly. Other players are inspected only out of combat, only when they can
  be inspected and are in range, at most one request every 1.5 seconds; results are kept
  for 10 minutes. If the result arrives while the tooltip still shows that player, the line
  is added. Inspect requests of other addons are not disturbed.
  The average covers the equipped slots except shirt and tabard (17 slots including the
  ranged slot); a two-handed weapon with an empty off-hand counts twice.

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

## Slash commands

| Command | Description |
| --- | --- |
| `/ptt` or `/pardonastooltips` | Open the options |
| `/ptt reset` | Reset all settings to their defaults |
| `/ptt help` | List the commands |

If `/ptt` is used during combat, the options open as soon as combat ends.

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
| Mana | On |
| Item level (players) | On |
| Classification (mobs) | On |

**Items**

| Option | Default |
| --- | --- |
| Item level on items | On |
| Show comparison | Always (choices: Always, Only with Shift, Off) |
| Hide appearance collection hint | On |

With *Only with Shift* the comparison appears and disappears as soon as Shift is pressed or
released.

**General**

- *Reset settings* – restores all defaults.

## Planned

- Prices and disenchanting values with TradeSkillMaster
- Item sources
- Vendor recipes

## License

Pardona's ToolTips is released under the [GNU General Public License v3.0](LICENSE).

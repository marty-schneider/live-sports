# Sports Tracker for Omarchy

**v0.4.0** — auto-sport pill, event-name countdown, click-to-pin, quieter notifications. Clocks only when a feed actually has a time.

One bar pill and dashboard for three sports, with a switcher so more sports can be added later:

- **Counter-Strike** — Valve Majors and RMRs, BLAST Open / Premier / Bounty / Rivals, ESL Pro League, IEM
- **Grand Sumo** — honbasho, Makuuchi only
- **GT World Challenge** — SRO, all continents (Europe, America, Asia, Australia)

Shaped after [F1 Live](https://github.com/marconn01/live-f1): countdown pill, local-time schedule, pinned player *and* team, notifications, disk cache, live mode.

This plugin is unofficial and is not associated with Valve, BLAST, ESL, the Nihon Sumo Kyokai, or SRO Motorsports Group.

## Install

```sh
omarchy plugin add https://github.com/marty-schneider/sports-tracker.git --enable
omarchy bar move io.github.marty-schneider.sports-tracker --section left
```

From a local clone:

```sh
git clone https://github.com/marty-schneider/sports-tracker.git
cd sports-tracker
./install.sh --link
omarchy plugin enable io.github.marty-schneider.sports-tracker
```

## Use

The pill follows whatever is next (or on now) unless you lock a sport with AUTO / CS2 / SUMO / GT. It shows the event, not the sport: `EPL 26d`, `AKI 6d`, `ZAND 11d`.

Click a player, team, rikishi, or heya to pin it. Notifications fire for the sport on the pill, plus any sport you have a pin in.

Live mode only appears when there is something on — today’s unfinished CS maps, or a published Sumo card. No empty tower.

On GT, EU / AM / AS / AU filters the calendar. `0` auto, `1` `2` `3` lock a sport, `r` refreshes, Escape closes.

Right-click the pill to announce the next session. Middle-click forces a refresh.

## Settings

On the plugin’s `shell.json` entry:

```json
{
  "id": "io.github.marty-schneider.sports-tracker",
  "defaultSport": "cs",
  "csHighlightPlayer": "donk",
  "csHighlightTeam": "Spirit",
  "sumoHighlightPlayer": "Onosato",
  "sumoHighlightTeam": "Nishonoseki",
  "gtHighlightTeam": "Mercedes",
  "notifications": true,
  "notifyLeadMinutes": "30,15"
}
```

Selected sport is also remembered in `~/.local/state/omarchy/sports-tracker/ui.json`.

## Data sources

| Sport | Calendar / results | Live |
| --- | --- | --- |
| CS2 | [csapi.de](https://api.csapi.de) (VRS rankings, recent matches, player ratings) plus a shipped Tier 1 calendar | Optional [PandaScore](https://developers.pandascore.co) token |
| Sumo | [sumo-api.com](https://www.sumo-api.com) basho, Makuuchi banzuke, daily torikumi | Free — today’s card fills in as bouts complete |
| GT | Shipped 2026 SRO calendar (Europe Sprint + Endurance, America, Asia, Australia) | Optional SRO / Swiss Timing credentials |

Nothing is hardcoded as “who is winning”. Rankings and results come from the APIs. The GT calendar is the one place with shipped dates, because SRO does not publish a public JSON feed.

### Paid live (optional)

```sh
mkdir -p ~/.config/omarchy/sports-tracker
cat > ~/.config/omarchy/sports-tracker/credentials <<'EOF'
pandascore_token=
sro_timing=
EOF
chmod 600 ~/.config/omarchy/sports-tracker/credentials
```

Without those keys the live toggle still works: CS and GT explain that the feed needs credentials; Sumo shows the day’s torikumi.

## What it writes

| Path | Contents |
| --- | --- |
| `~/.config/omarchy/plugins/io.github.marty-schneider.sports-tracker` | plugin |
| `~/.cache/omarchy/sports-tracker` | cached API responses |
| `~/.local/state/omarchy/sports-tracker` | notifications + last selected sport |
| `~/.config/omarchy/sports-tracker/credentials` | optional live tokens, `0600` |

## Tests

```sh
node tests/run.js
node tests/run.js --refresh
```

## Licence

MIT. Architecture and cache pipeline follow the F1 Live plugin (MIT, marconn01).

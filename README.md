# Sports Tracker for Omarchy

**v0.3.0** — renamed Sports Tracker. Countdown pill, schedules, standings, and optional live feeds.

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

Click the pill. `1` / `2` / `3` (or the CS2 · SUMO · GT chips) switch sports. On GT, EU / AM / AS / AU filters the calendar. Enter toggles live mode, `r` refreshes, Escape closes.

The live view is sport-specific: CS map scores, Sumo East/West bouts, GT timing when a feed is configured. With nothing running it names the next session and the countdown, the same way F1 Live does.

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

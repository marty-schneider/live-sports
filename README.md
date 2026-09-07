# Live Sports for Omarchy

One bar pill and dashboard for three sports, with a switcher so more sports can be added later:

- **Counter-Strike** — Valve Majors and RMRs, BLAST Open / Premier / Bounty / Rivals, ESL Pro League, IEM
- **Grand Sumo** — honbasho, Makuuchi only
- **GT World Challenge** — SRO, all continents (Europe, America, Asia, Australia)

Shaped after [F1 Live](https://github.com/marconn01/live-f1): countdown pill, local-time schedule, pinned player *and* team, notifications, disk cache, live mode.

This plugin is unofficial and is not associated with Valve, BLAST, ESL, the Nihon Sumo Kyokai, or SRO Motorsports Group.

## Install

```sh
omarchy plugin add https://github.com/marty-schneider/live-sports.git --enable
omarchy bar move io.github.marty-schneider.live-sports --section left
```

From a local clone:

```sh
git clone https://github.com/marty-schneider/live-sports.git
cd live-sports
./install.sh --link
omarchy plugin enable io.github.marty-schneider.live-sports
```

## Use

Click the pill. `1` / `2` / `3` (or the CS2 · SUMO · GT chips) switch sports. Enter toggles live mode, `r` refreshes, Escape closes.

Right-click the pill to announce the next session. Middle-click forces a refresh.

## Settings

On the plugin’s `shell.json` entry:

```json
{
  "id": "io.github.marty-schneider.live-sports",
  "defaultSport": "cs",
  "csHighlightPlayer": "donk",
  "csHighlightTeam": "Spirit",
  "sumoHighlightPlayer": "Onosato",
  "sumoHighlightTeam": "Yokozuna",
  "gtHighlightTeam": "Mercedes",
  "notifications": true,
  "notifyLeadMinutes": "30,15"
}
```

Selected sport is also remembered in `~/.local/state/omarchy/live-sports/ui.json`.

## Data sources

| Sport | Calendar / results | Live |
| --- | --- | --- |
| CS2 | [csapi.de](https://api.csapi.de) (VRS rankings, recent matches, player ratings) plus a shipped Tier 1 calendar | Optional [PandaScore](https://developers.pandascore.co) token |
| Sumo | [sumo-api.com](https://www.sumo-api.com) basho, Makuuchi banzuke, daily torikumi | Free — today’s card fills in as bouts complete |
| GT | Shipped 2026 SRO calendar (Europe Sprint + Endurance, America, Asia, Australia) | Optional SRO / Swiss Timing credentials |

Nothing is hardcoded as “who is winning”. Rankings and results come from the APIs. The GT calendar is the one place with shipped dates, because SRO does not publish a public JSON feed.

### Paid live (optional)

```sh
mkdir -p ~/.config/omarchy/live-sports
cat > ~/.config/omarchy/live-sports/credentials <<'EOF'
pandascore_token=
sro_timing=
EOF
chmod 600 ~/.config/omarchy/live-sports/credentials
```

Without those keys the live toggle still works: CS and GT explain that the feed needs credentials; Sumo shows the day’s torikumi.

## What it writes

| Path | Contents |
| --- | --- |
| `~/.config/omarchy/plugins/io.github.marty-schneider.live-sports` | plugin |
| `~/.cache/omarchy/live-sports` | cached API responses |
| `~/.local/state/omarchy/live-sports` | notifications + last selected sport |
| `~/.config/omarchy/live-sports/credentials` | optional live tokens, `0600` |

## Tests

```sh
node tests/run.js
node tests/run.js --refresh
```

## Licence

MIT. Architecture and cache pipeline follow the F1 Live plugin (MIT, marconn01).

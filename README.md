# %styx - A Dead Man's Switch for Urbit

*"The ferryman waits for no one, but he is patient."*

Your ship is meant to last forever. You won't. **Styx** ensures that when you cross the river, your digital legacy crosses with you—delivered to the hands you choose.

Unlike Web2 dead man's switches that rely on centralized servers, Styx is peer-to-peer. Your cargo stays on your ship until the moment of release. Delivery happens over Ames, ship to ship.

## Installation

```hoon
|install ~dovfeb %styx
```

Or search for `~dovfeb` in **Get Urbit Apps** from your Landscape home screen.

## Quick Start

1. Visit `/styx` on your ship (or click the tile)
2. Click **Enable** to activate the switch
3. Add cargo (messages to deliver)
4. Use your ship normally - the timer auto-resets

## How It Works

```
PEACEFUL ──(60 days no activity)──> WARNING ──(72 hours)──> CROSSED
    ^                                    |
    └────────── any activity ────────────┘
```

**Activity that resets your timer:**
- Visiting the Styx web UI
- Clicking "I Yet Live"

**When the switch fires:** All your cargo is delivered to recipients via Ames.

**Important:** Recipients must also have Styx installed to receive deliveries.

## Web UI

Access at `/styx` on your ship. Features:
- Status display (Peaceful/Warning/Crossed/Disabled)
- One-click proof of life
- Add/view/delete cargo
- View received deliveries
- Configure timer settings
- Built-in help documentation

## Dojo Commands

```hoon
::  Enable/disable
:styx &styx-action [%enable ~]
:styx &styx-action [%disable ~]

::  Manual ping (proof of life)
:styx &styx-action [%ping ~]

::  Add message cargo
:styx &styx-action [%add-cargo ~recipient 'Subject' 'Message body']

::  Add file cargo
:styx &styx-action [%add-file ~recipient 'file.zip' 'application/zip' 0x...]

::  Health check
:styx &styx-action [%verify ~]

::  Test roundtrip delivery
:styx &styx-action [%test-roundtrip ~]

::  Configure timer (days/hours)
:styx &styx-action [%set-river-width ~d30]
:styx &styx-action [%set-grace-period ~h48]

::  Debug state
:styx +dbug
```

## Configuration

| Setting | Default | Description |
|---------|---------|-------------|
| Inactivity Period | 60 days | Time before warning phase |
| Grace Period | 72 hours | Warning duration before delivery |

Settings are global and apply to all cargo. When the switch fires, ALL cargo is delivered at once.

## Important: Always-On Hosting

**Your ship must be running for the timer to work.** If your ship is off, the timer doesn't advance.

## Features

- [x] Passive obols (auto-ping on page visit)
- [x] Web UI with settings
- [x] Message cargo
- [x] Health checks and diagnostics
- [x] Test delivery mode
- [x] Roundtrip self-test
- [ ] File cargo (backend ready, UI coming)
- [ ] Groups integration (coming soon)

## Architecture

```
styx/
├── app/styx.hoon    # Main Gall agent
├── sur/styx.hoon    # Type definitions
├── lib/styx.hoon    # Helper library
└── mar/styx/        # Mark files
    ├── action.hoon
    ├── delivery.hoon
    └── update.hoon
```

## Concepts

| Term | Meaning |
|------|---------|
| **Obol** | Proof of life. Resets the timer. |
| **Cargo** | Message or file to deliver when you cross. |
| **Crossing** | The trigger point—when your switch fires. |
| **River Width** | Inactivity period before warning (default: 60 days) |
| **Grace Period** | Warning duration before delivery (default: 72 hours) |

## License

MIT

*"For in that sleep of death what dreams may come..."*

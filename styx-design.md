# %styx — A Dead Man's Switch for Urbit

*"The ferryman waits for no one, but he is patient."*

---

## What It Is

Your ship is meant to last forever. You won't. %styx ensures that when you cross the river, your digital legacy crosses with you—delivered to the hands you choose.

Unlike Web2 dead man's switches that rely on centralized servers, %styx is peer-to-peer. Your cargo stays on your ship, encrypted, until the moment of release. Delivery happens over Ames, ship to ship.

---

## How It Works

```
  YOU                                              CROSSING
   │                                                   │
   │  ←── River Width (default 60 days) ──→           │
   │                                                   │
   ▼                                                   ▼
┌──────┐   no activity  ┌─────────┐  no activity ┌──────────┐
│ PEACE │ ──────────→   │ WARNING │ ─────────→   │ CROSSING │ → Deliver Cargo
└──────┘  (60 days)     └─────────┘  (3 days)    └──────────┘
   ▲                         │
   │                         │
   └───── any activity ──────┘
```

**Passive Obols:** Your Urbit activity automatically resets the timer:
- Using Groups (chat, posts, reactions)
- Visiting the styx web UI
- Or click "I Yet Live" as a manual backup

No need to remember to ping if you're actively using your ship.

1. **Peaceful** — Timer counting down. Any ping resets it.
2. **Warning** — Grace period. Ping to abort.
3. **Crossing** — Timer expired. All cargo delivered to recipients.

---

## Core Concepts

| Term | Meaning |
|------|---------|
| **Obol** | Proof of life. A ping that resets the timer. |
| **Cargo** | Message or file to deliver when you cross. |
| **Crossing** | The trigger point—when your switch fires. |
| **River Width** | How long before warning phase (default: 60 days) |
| **Grace Period** | Warning phase duration (default: 3 days) |

---

## Cargo Types

### Message
```hoon
[%message subject='For my sister' body='The password is...']
```

### File
```hoon
[%file name='keys.zip' mime='application/zip' data=0x...]
```

Cargo encryption with recipient's public key is planned for a future release.

---

## Usage

### Web UI
```
http://localhost:8080/styx
```

### Dojo
```hoon
::  Ping (proof of life)
:styx &styx-action [%ping ~]

::  Enable/disable
:styx &styx-action [%enable ~]
:styx &styx-action [%disable ~]

::  Add message cargo
:styx &styx-action [%add-cargo ~recipient 'Subject' 'Body']

::  Check status
:styx +dbug
```

---

## Configuration

| Setting | Default | Description |
|---------|---------|-------------|
| River Width | 60 days | Time before warning phase |
| Grace Period | 3 days | Warning phase before crossing |

---

## Architecture

One agent. Simple state.

```
styx-desk/
├── app/styx.hoon    # The agent
├── sur/styx.hoon    # Types
├── lib/styx.hoon    # Helpers
└── mar/styx/        # Marks
```

---

## Future Ideas

- **Witness network** — Trusted ships can vouch for you
- **Multiple conditions** — Combine triggers (silence + witness confirmation)
- **Scheduled release** — Deliver on a specific date
- **Cargo encryption** — Encrypt with recipient's public key

---

*"For in that sleep of death what dreams may come..."*

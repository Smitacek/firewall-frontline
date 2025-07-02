# Firewall Frontline – Game Design Document (v0.1)

*Last updated: 2025‑07‑02*

## 1. Game Overview

A neon‑retro lane‑defense game where players deploy cybersecurity "modules" to fend off escalating hacker attacks. Educational goal: subtly teach core security principles (defence‑in‑depth, least privilege, patch management) without technical jargon.

## 2. Core Gameplay Loop

```mermaid
flowchart LR
    A(Collect CPU Cycles) --> B(Place / Upgrade Modules)
    B --> C(Repel Attack Wave)
    C --> D(Gain XP & Research Tokens)
    D --> A
```

- Fail condition: any attacker reaches the **Core Server** on the left edge.
- Failsafe: **Air‑Gap Trigger** clears a lane once per level.

## 3. Resources & Economy

| Resource                  | Source                  | Spend On                 | Notes                       |
| ------------------------- | ----------------------- | ------------------------ | --------------------------- |
| **CPU Cycles**            | Power Nodes (every 5 s) | Deploy modules           | 25–200 per module           |
| **Research Tokens**       | Wave reward & bonuses   | Upgrades, new modules    | Persistent meta‑progression |
| **Bandwidth** *(stretch)* | Bonus pickups mid‑wave  | Temporary lane‑wide buff | e.g., double fire‑rate 10 s |

## 4. Defensive Modules (vSlice Set)

| ID      | Name                           | Cost (CPU) | Cool‑down | Role                                         | Attack Channel | Upgrade Path                                |
| ------- | ------------------------------ | ---------- | --------- | -------------------------------------------- | -------------- | ------------------------------------------- |
| **PWR** | **Power Node**                 | 50         | 10 s      | Generates 25 CPU/5 s                         | –              | ↑ Turbo Node (+50%)                         |
| **FWL** | **Firewall**                   | 100        | 8 s       | Basic single‑target projectile               | *Packet*       | ↑ Dual‑core (2× DPS) → Cluster (AoE splash) |
| **IDS** | **Intrusion Detection Sensor** | 125        | 10 s      | Reveals & slows Stealth attackers            | *Payload*      | ↑ Deep‑Packet Scan (bigger slow), +Damage   |
| **HPT** | **Honeypot**                   | 75         | 12 s      | Taunts attackers for 8 s then self‑destructs | *Social*       | ↑ Sticky Honey (longer taunt)               |
| **SBX** | **Sandbox**                    | 150        | 15 s      | Blocks one Zero‑Day; enemy paused 6 s        | *Zero‑Day*     | ↑ Auto‑Patch (reusable 2×)                  |
| **AVM** | **AntiVirus Module**           | 175        | 9 s       | Three‑shot burst, short range                | *Payload*      | ↑ Heuristic Engine (+pierce)                |

> *Vertical Slice uses PWR + FWL + HPT + Script Kiddie attacker to prove fun.*

## 5. Enemy Types (vSlice & Beyond)

| Tier     | Name                     | Speed  | Health    | Special                                             | Damage Channel | Countered By               |
| -------- | ------------------------ | ------ | --------- | --------------------------------------------------- | -------------- | -------------------------- |
| **T1**   | **Script Kiddie Packet** | Slow   | Low       | None                                                | *Packet*       | Any DPS (FWL)              |
| **T1**   | **Spam Bot**             | Medium | Low       | Spawns junk packets (clutter)                       | *Social*       | AVM splash                 |
| **T2**   | **Phishing Spear**       | Slow   | Medium    | Ignores first slow effect                           | *Social*       | IDS slow, HPT taunt        |
| **T2**   | **Botnet Swarm**         | Fast   | Low       | Arrives in group of 5                               | *Packet*       | AoE Firewall Cluster       |
| **T3**   | **Trojan Horse**         | Medium | High      | Disguised: invisible until hit                      | *Payload*      | IDS reveal, AVM burst      |
| **T4**   | **Zero‑Day Exploit**     | Medium | Very High | Immune to first 2 hits; disables module on contact  | *Zero‑Day*     | Sandbox                    |
| **Boss** | **APT “Black‑Hat AI”**   | Slow   | Massive   | Periodically spawns lower‑tier units, ranged attack | Mixed          | Combined defence, Failsafe |

## 6. Level Structure

- **Campaign** – 20 handcrafted scenarios, grouped in 4 "Chapters" (Office LAN, Cloud Edge, IoT Jungle, Critical Infrastructure).
- **Endless Mode** – infinite waves with scaling modifiers (speed, hp, special).
- **CTF Challenges** *(later)* – puzzle levels teaching specific concepts.

## 7. Progression & Unlocks

| Chapter Unlock | New Modules                        | New Attackers        |
| -------------- | ---------------------------------- | -------------------- |
| Start          | Power Node, Firewall, Honeypot     | Script Kiddie        |
| Office LAN     | IDS, AntiVirus                     | Phishing, Spam Bot   |
| Cloud Edge     | Sandbox                            | Botnet Swarm, Trojan |
| IoT Jungle     | Proxy Shield *(future)*            | Zero‑Day             |
| Critical Infra | Cluster Firewall, Air‑Gap Failsafe | Boss AI              |

## 8. UX / UI Wireframe (ASCII)

```
+----------------------------- CORE SERVER -----------------------------+
| Lane 1 |   ■   ■   ■   ■   ■   ■   ■   | <— Attacks
| Lane 2 |   ■   ■   ■   ■   ■   ■   ■   |
| Lane 3 |   ■   ■   ■   ■   ■   ■   ■   |
| Lane 4 |   ■   ■   ■   ■   ■   ■   ■   |
| Lane 5 |   ■   ■   ■   ■   ■   ■   ■   |
+------------------------------------------------------------------------
[CPU: 75]  [Tokens: 0]  [Toolbar: PWR | FWL | IDS | HPT | SBX | AVM]
```

## 9. Audio & Visual Style

- **Art:** 32×32 pixel‑art sprites, neon palette (#08F blue, #0F0 green, #F0F pink).
- **SFX:** retro modem beeps, synth explosions.
- **Music:** chiptune with cyberpunk bassline (90–110 BPM).

## 10. Technical Notes

- Godot 4.x – prefer Scenes as MVC components.
- Script language: GDScript (C# optional for pathfinding optimisations).
- Unit tests with WAT; mock single‑player wave for CI.

## 11. Risks & Mitigations

| Risk                              | Impact      | Mitigation                                    |
| --------------------------------- | ----------- | --------------------------------------------- |
| Scope creep on attacker abilities | Delay       | Lock design at Beta; extras go to DLC backlog |
| Balancing grind                   | Frustration | Play‑test weekly, adjust CPU drop rates       |
| Performance on low‑end PCs        | Bad UX      | Use Godot’s multimesh & occlusion             |

## 12. Next Milestone – Vertical Slice

- Implement lanes, CPU drop system.
- Add four modules (PWR, FWL, HPT, IDS) and Script Kiddie enemy.
- One tutorial level + Endless sandbox.
- Collect first external play‑test feedback.

---

*End of v0.1 GDD*


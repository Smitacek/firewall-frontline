# Firewall Frontline – Technical Design Document (TDD v0.1)

*Last updated: 2025‑07‑02*

---

## 1. Purpose

This document defines the **technology stack, project structure, coding standards, and CI/CD pipeline** for *Firewall Frontline*. It supplements the GDD by providing implementation‑level detail so any contributor can set up, build, test, and deploy the game consistently.

---

## 2. High‑Level Architecture

```
[Player Input] → [Godot SceneTree]
                        ↓        ↘
              [GUI Layer]      [Gameplay Domain]
                                ↓         ↘
                      [System Modules]  [Enemy AI Finite‑State]
                                ↓
                           [Data‑Driven Balance JSON]
```

- **Separation of Concerns:**
  - `gui/` – Control nodes, HUD, menus (pure View)
  - `domain/` – Core gameplay logic (Models); no Node‑based code → decoupled for unit testing
  - `scenes/` – Prefabs composed of GUI + Domain via Signals
  - `ai/` – State machines for attacker behaviour
  - `data/` – Balance tables (JSON/TSV) loaded at runtime

---

## 3. Technology Stack

| Layer                  | Technology                 | Version                       | Why                                  |
| ---------------------- | -------------------------- | ----------------------------- | ------------------------------------ |
| Game Engine            | **Godot**                  | 4.x LTS                       | Open‑source, lightweight, C# support |
| Scripting              | **GDScript**               | 2.0                           | Fast iteration, pythonic syntax      |
| Optional Perf Modules  | C# (Mono)                  | .NET 8                        | High‑perf pathfinding pieces         |
| Version Control        | **Git + GitHub**           | N/A                           | Collaboration, PR reviews            |
| Continuous Integration | **GitHub Actions**         | ubuntu‑latest, windows‑latest | Headless export, unit tests          |
| Testing                | **WAT** (godot‑unit)       | 4.x                           | In‑engine unit/integration testing   |
| Static Analysis        | **gdtoolkit linter**       | 4.x                           | Enforce style & best practices       |
| Packaging              | **Godot Export Templates** | 4.x LTS                       | Deterministic builds                 |
| Artifact Hosting       | **GitHub Releases**        | N/A                           | Binaries & source ZIPs               |

---

## 4. Project Directory Layout

```
/                    # repo root
├── .github/
│   └── workflows/   # CI YAML
├── addons/          # third‑party Godot addons (submodules)
├── assets/
│   ├── art/
│   ├── audio/
│   └── fonts/
├── data/            # balance tables, JSON, TSV
├── domain/          # pure‑logic scripts (no Node)
├── gui/             # Control scenes (HUD, menus)
├── scenes/          # Node‑based prefabs & levels
├── ai/              # enemy FSM scripts
├── tests/           # WAT unit/integration tests
├── docs/            # design docs (GDD, TDD, retros)
└── exports/         # output builds via CI
```

- **Rule:** Only `scenes/` contains `.tscn`. Pure logic stays under `domain/` to keep tests headless.

---

## 5. Data‑Driven Balance

- Stats for modules/enemies live in \`\` – allows hot‑reloading via in‑editor plugin.
- Sample snippet:

```json
{
  "modules": {
    "PWR": {"cost": 50, "cooldown": 10, "cpuGen": 25},
    "FWL": {"cost": 100, "dps": 20, "cooldown": 8}
  },
  "enemies": {
    "SKP": {"hp": 100, "speed": 40}
  }
}
```

---

## 6. Coding Standards

- **Style Guide:**
  - 4‑space indent, 100‑char line length
  - `snake_case` for functions & variables, `PascalCase` for classes
- **Signals over singletons** – decouple systems.
- **Dependency Injection** – pass interfaces into constructors for testability.
- **Unit‑Test First** for domain logic; aim ≥ 70 % coverage before Beta.

---

## 7. Continuous Integration / Delivery

```yaml
name: Godot CI
on: [push, pull_request]
jobs:
  build:
    strategy:
      matrix: { os: [ubuntu‑latest, windows‑latest] }
    runs‑on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4
      - uses: chickensoft‑games/goat‑action@v2
        with:
          godot‑version: 4.2.1
          use‑mono: true
      - name: Run Unit Tests
        run: godot --headless --run-tests
      - name: Export Game
        run: godot --headless --export-release "Windows Desktop" exports/Firewall.exe
      - uses: actions/upload‑artifact@v4
        with:
          name: Build‑${{ matrix.os }}
          path: exports/
  release:
    needs: build
    if: startsWith(github.ref, 'refs/tags/v')
    runs‑on: ubuntu‑latest
    steps:
      - uses: actions/download‑artifact@v4
      - uses: ncipollo/release‑action@v1
        with:
          artifacts: "exports/**"
```

- **Trigger:** on push & PR → compile, test, export.
- **Release Gate:** Tag `vX.Y.*` publishes artifacts to GitHub Releases.

---

## 8. Local Dev Environment

1. \*\*Clone → \*\*\`\` (addons).
2. Install Godot **4.x LTS** + matching export templates.
3. Run `godot --editor` – project opens at `scenes/Main.tscn`.
4. `pre‑commit` hook runs gd‑linter & unit tests locally.

---

## 9. Performance Guidelines

| Concern        | Guideline                                     |
| -------------- | --------------------------------------------- |
| Draw Calls     | Use MultiMesh for identical projectiles       |
| Physics        | Fixed timestep 60 Hz; avoid per‑frame polling |
| AI Pathfinding | A\* cache per lane                            |
| Memory         | Pool arrays for attacker instances            |

---

## 10. Open Technical Questions

| # | Question                               | Owner      | Due          |
| - | -------------------------------------- | ---------- | ------------ |
| 1 | Use ECS plugin vs classic Godot nodes? | Tech Lead  | Alpha freeze |
| 2 | C# for heavy AI w/ tasks?              | Perf squad | Beta         |
| 3 | Steam demo build pipeline?             | CI owner   | Gold         |

---

## 11. Roadmap Integration

- **Sprint 1:** CI skeleton + data loader + Power Node script unit‑tested.
- **Sprint 2:** Implement Domain ↔ GUI signal bridge, A\* lane path.
- **Sprint 3:** Optimize projectile pooling & add multimesh.

---

*End of TDD v0.1*


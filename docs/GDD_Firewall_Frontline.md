# Game Design Document: Firewall Frontline

## 1. Přehled hry

### Koncept
Firewall Frontline je vzdělávací tower defense hra s kybernetickou tematikou, kde hráči brání svůj systém před hackerskými útoky pomocí kybernetických obranných modulů. Hra učí základní principy kybernetické bezpečnosti zábavnou formou bez technického žargonu.

### Cílová skupina
- Primární: Hráči 12+ se zájmem o hry a technologie
- Sekundární: Studenti a učitelé hledající vzdělávací nástroj pro výuku kybernetické bezpečnosti

### Hlavní features
- 6 unikátních obranných modulů s upgrade systémem
- 4 typy útoků vyžadující různé obranné strategie
- Postupně se zvyšující obtížnost s boss útoky
- Pixel art vizuální styl s neonovou paletou
- Vzdělávací prvky integrované do gameplayi

## 2. Herní mechaniky

### 2.1 Lane Defense System
- **Počet lanes**: 5 horizontálních cest
- **Grid system**: 8x5 polí pro umístění modulů
- **Spawn points**: Pravá strana obrazovky
- **Cíl obrany**: Server/Core na levé straně

### 2.2 Obranné moduly

#### Power Node (PWR)
- **Cena**: 50 CPU
- **Funkce**: Generuje 25 CPU každých 5 sekund
- **Upgrade cesta**:
  - Level 2: +50% rychlost generování (100 CPU)
  - Level 3: +100% rychlost + AoE CPU boost (200 CPU)
- **Speciální**: Může stackovat efekt s ostatními Power Nodes

#### Firewall (FWL)
- **Cena**: 100 CPU
- **Funkce**: Blokuje Packet útoky (100 HP)
- **Damage**: 10 DPS proti Packet nepřátelům
- **Upgrade cesta**:
  - Level 2: +100% HP, +50% damage (150 CPU)
  - Level 3: Reflektuje 25% damage zpět (300 CPU)

#### IDS (Intrusion Detection System)
- **Cena**: 150 CPU
- **Funkce**: Odhaluje skryté hrozby, zpomaluje nepřátele o 50%
- **Range**: 3x3 pole
- **Upgrade cesta**:
  - Level 2: +1 range, 75% zpomalení (200 CPU)
  - Level 3: Instant kill na odhalené Script Kiddies (400 CPU)

#### Honeypot (HPT)
- **Cena**: 75 CPU
- **Funkce**: Láká nepřátele, 200 HP návnada
- **Speciální**: Při zničení exploduje (50 AoE damage)
- **Upgrade cesta**:
  - Level 2: +100% HP, větší exploze (125 CPU)
  - Level 3: Respawn po 10s (250 CPU)

#### Sandbox
- **Cena**: 200 CPU
- **Funkce**: Izoluje a analyzuje Payload útoky
- **Kapacita**: 3 nepřátelé současně
- **Upgrade cesta**:
  - Level 2: +2 kapacita, rychlejší analýza (300 CPU)
  - Level 3: Konvertuje nepřátele na Research Tokens (500 CPU)

#### AntiVirus
- **Cena**: 250 CPU
- **Funkce**: AoE damage proti všem typům (20 DPS)
- **Range**: 2x2 pole
- **Upgrade cesta**:
  - Level 2: +50% damage, +1 range (400 CPU)
  - Level 3: Chain reaction damage (600 CPU)

### 2.3 Typy nepřátel

#### Tier 1
- **Script Kiddie**
  - HP: 50
  - Speed: Normal
  - Damage type: Packet
  - Reward: 10 CPU

- **Spam Bot**
  - HP: 30
  - Speed: Fast
  - Damage type: Packet
  - Special: Spawns ve skupinách po 3

#### Tier 2
- **Phishing Spear**
  - HP: 100
  - Speed: Slow
  - Damage type: Social
  - Special: Ignoruje 50% Firewall obrany

- **Botnet Swarm**
  - HP: 200 (sdílené mezi 5 jednotkami)
  - Speed: Variable
  - Damage type: Packet
  - Special: Rozděluje se při zásahu

#### Tier 3
- **Trojan Horse**
  - HP: 300
  - Speed: Very Slow
  - Damage type: Payload
  - Special: Po zničení vypustí 3 Script Kiddies

#### Tier 4
- **Zero-Day Exploit**
  - HP: 500
  - Speed: Normal
  - Damage type: Zero-Day
  - Special: Imunní vůči prvnímu typu obrany, který ho zasáhne

#### Boss
- **APT "Black-Hat AI"**
  - HP: 2000
  - Speed: Slow
  - Damage type: Všechny
  - Special: Mění typ útoku každých 25% HP

### 2.4 Ekonomický systém

#### CPU Cycles
- Startovní množství: 150 CPU
- Pasivní generace: 5 CPU/10s
- Získávání: Power Nodes, poražení nepřátelé
- Využití: Nákup a upgrade modulů

#### Research Tokens
- Získávání: Dokončení vln, speciální nepřátelé
- Využití: Permanentní upgrady mezi levely
- Příklady upgradů:
  - Firewall Efficiency: -10% cena všech Firewalls
  - CPU Overclock: +20% generace ze všech zdrojů
  - Early Warning: Nepřátelé viditelní 2s před spawnem

### 2.5 Wave System
- **Tutorial waves** (1-3): Pouze Script Kiddies
- **Early waves** (4-10): Mix T1 nepřátel
- **Mid waves** (11-20): Introduce T2, občas T3
- **Late waves** (21-30): Všechny typy, více T3/T4
- **Boss waves**: Každá 10. vlna
- **Endless mode**: Po wave 30, exponenciální scaling

## 3. Level Design

### 3.1 Tutorial Level
- 3 lanes aktivní
- Guided placement prvních modulů
- Pouze Script Kiddie nepřátelé
- Tooltips vysvětlující mechaniky

### 3.2 Campaign Levels
1. **Network Perimeter** - Základní obrana, 3 lanes
2. **Data Center** - 4 lanes, introduce Honeypot
3. **Corporate Network** - 5 lanes, všechny moduly
4. **Critical Infrastructure** - 5 lanes, resource management focus
5. **Final Firewall** - Boss level s APT

### 3.3 Endless Sandbox
- Všech 5 lanes aktivních
- Postupně se odemykají nepřátelé
- Leaderboard systém
- Weekly challenges

## 4. Vizuální styl

### 4.1 Art Direction
- **Styl**: Pixel art, 32x32 sprites
- **Paleta**: Neonová - #08F (modrá), #0F0 (zelená), #F0F (růžová)
- **Pozadí**: Tmavé s grid overlay, Matrix-style efekty
- **UI**: Minimalistické, terminál-inspired

### 4.2 Vizuální feedback
- Damage numbers při zásahu
- Particle efekty pro schopnosti
- Screen shake při boss útocích
- Barevné indikátory typů útoků

### 4.3 Audio
- Retro synth soundtrack
- Modem/dial-up zvuky pro spawning
- Digitální glitch efekty pro damage
- Úspěšné hacky = chiptune fanfáry

## 5. Vzdělávací aspekty

### 5.1 Koncepty vyučované hrou
1. **Defense-in-Depth**: Více vrstev obrany = lepší ochrana
2. **Least Privilege**: Honeypots učí koncept omezených přístupů
3. **Patch Management**: Upgrade systém simuluje aktualizace
4. **Threat Detection**: IDS mechanika učí důležitost monitoringu
5. **Incident Response**: Sandbox isolation jako metafora

### 5.2 Loading Screen Tips
- "Skutečné firewally filtrují síťový provoz podobně jako ve hře!"
- "IDS systémy v reálném světě monitorují podezřelé aktivity 24/7"
- "Honeypots jsou skutečné nástroje používané k chytání hackerů"

### 5.3 Codex/Encyclopedia
- Odemykatelné popisy nepřátel s real-world protějšky
- Vysvětlení obranných technik
- Mini-quizy za Research Tokens

## 6. Technická implementace

### 6.1 Performance cíle
- 60 FPS na mid-range hardware
- Max 100 nepřátel současně na obrazovce
- Load time < 3 sekundy

### 6.2 Systémová architektura
```
Main
├── GameManager (singleton)
├── WaveManager
├── EconomyManager
├── LaneSystem
│   └── Lane (5x)
├── ModuleSystem
│   └── BaseModule
│       ├── PowerNode
│       ├── Firewall
│       └── ...
└── EnemySystem
    └── BaseEnemy
        ├── ScriptKiddie
        └── ...
```

### 6.3 Data-Driven Design
- Všechny balance hodnoty v JSON/CSV
- Hot-reload během development
- A/B testing ready struktura

## 7. Monetizace (Future)

### 7.1 Free-to-Play Core
- Tutorial + 3 campaign levels zdarma
- Endless mode s omezeními

### 7.2 Premium Unlock ($4.99)
- Všechny campaign levels
- Unlimited endless mode
- Cosmetic skins pro moduly
- Level editor (future update)

### 7.3 Educational License ($29.99)
- Classroom management tools
- Progress tracking
- Curriculum alignment docs
- Bulk activation codes

## 8. Post-Launch Content

### 8.1 Month 1-3
- Bug fixes a balance patches
- Weekly challenges
- Leaderboard seasons

### 8.2 Month 4-6
- New enemy types (Cryptominer, Ransomware)
- New module (VPN Gate)
- Level editor beta

### 8.3 Year 1
- Mobile port
- Educational partnerships
- Workshop/mod support
- Multiplayer co-op mode

## 9. Success Metrics

### 9.1 Launch Goals
- 10,000 downloads první měsíc
- 70% retention po tutorialu
- 4.0+ rating na Steam

### 9.2 Educational Goals
- 100 škol používajících hru do roka
- Partnership s kybernetickou bezpečnostní organizací
- Pozitivní feedback od učitelů (80%+)

## 10. Risk Analysis

### 10.1 Technical Risks
- **Performance na low-end**: Mitigace - quality settings
- **Browser compatibility**: Mitigace - native builds priorita

### 10.2 Design Risks
- **Příliš složité pro casual**: Mitigace - extensive tutoriál
- **Příliš jednoduché pro TD veterány**: Mitigace - difficulty modes

### 10.3 Market Risks
- **Saturovaný TD market**: Mitigace - unikátní edukační angle
- **Niche téma**: Mitigace - polish a game-first approach
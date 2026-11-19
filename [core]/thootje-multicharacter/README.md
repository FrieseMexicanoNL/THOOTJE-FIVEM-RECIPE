# THOOTJE-MULTICHARACTER 1.0.0

Een standalone multicharacter resource voor THOOTJE-CORE. Ontworpen met een donkere teal/groene city-RP interface, character slots, aanmaken/verwijderen, preview camera en spawnselectie.

## Vereisten
- FXServer met OneSync
- `oxmysql`
- `thootje-core` met de integratiepatch uit `integration/thootje-core.patch.txt`
- MySQL tabel uit `sql/thootje_multicharacter.sql`

Deze resource gebruikt geen ox_lib.

## Installatie
1. Plaats `thootje-multicharacter` in je resources map.
2. Importeer `sql/thootje_multicharacter.sql`.
3. Pas THOOTJE-CORE aan volgens `integration/thootje-core.patch.txt`.
4. In `server.cfg`, start in deze volgorde:
   ```cfg
   ensure oxmysql
   ensure thootje-core
   ensure thootje-multicharacter
   ```
5. Pas de preview- en spawncoördinaten aan in `config.lua`.
6. Start de server opnieuw.

## Features
- Maximaal 4 personages per Rockstar license (instelbaar)
- Character create: voornaam, achternaam, geboortedatum, geslacht, nationaliteit
- Eigen character database, slotnummer en ownership-checks
- Preview-scène met camera en ped
- Spawnkeuze met meerdere locaties
- Personages verwijderen (configureerbaar)
- Moderne NUI in Thootje City-stijl

## Core-integratie
De multicharacter resource moet voorkomen dat de core automatisch één spelerrecord per license laadt. De meegeleverde patch voegt een `Config.MulticharacterEnabled` schakelaar en een `LoadPlayer` export toe. Bij selectie gebruikt de core een unieke identifier per character.

## Appearance
Deze versie toont een basis freemode preview-ped. Koppeling met illenium-appearance of een ander uiterlijkssysteem moet nog worden geconfigureerd; zie `Config.Appearance`. De huidige MVP slaat nog geen skin/outfit op.

## Events voor andere resources
- `thootje-multicharacter:server:characterSelected` — server event na selectie.
- `thootje-multicharacter:client:spawned` — client event na spawn.

# THOOTJE-JOBS 1.0.0

Job- en rangensysteem voor FiveM, ontworpen voor THOOTJE-CORE.

## Inbegrepen banen

### Civiele banen (via vacaturecentrum)
- Taxi Centrale
- Garagebedrijf
- Reinigingsdienst
- Transportbedrijf
- Openbaar Vervoer
- Visserij
- Landbouwbedrijf

### Overheidsbanen (alleen toewijzen door staff/leiding)
- Politie
- Ambulancedienst
- Brandweer
- Gemeente
- Rechtspraak

Elke functie heeft eigen rangen en salarissen in `jobs.lua`.

## Installatie
1. Plaats `thootje-jobs` in je resources-map.
2. Importeer `sql/thootje_jobs.sql` in je database.
3. Controleer de character-ID-koppeling in `config.lua`.
4. Voeg toe aan `server.cfg`:
   ```
   ensure oxmysql
   ensure thootje-core
   ensure thootje-banking
   ensure thootje-jobs
   ```
   `thootje-banking` is optioneel, maar aanbevolen voor salarisbetalingen.
5. Herstart de server.

## Gebruik
- `/jobs` of F6: vacaturecentrum.
- Gebruik E op een vacaturecentrum locatie om het menu te openen.
- `/myjob`: huidige baan en rang tonen.
- `/dienst`: in- of uitklokken.
- Overheidsbanen zijn niet publiek solliciteerbaar.

## Staff commando's
Geef ACE-rechten:
```
add_ace group.admin thootje.jobs.admin allow
```
Commando's:
```
/setjob [server-id] [jobnaam] [rang]
/setgrade [server-id] [rang]
/firejob [server-id]
```
Voorbeeld:
```
/setjob 12 police 2
/setgrade 12 4
```
Jobnamen zijn de keys in `jobs.lua`, bijvoorbeeld `police`, `ambulance`, `fire`, `government`, `lawyer`.

## Exports
Server-side:
```lua
local job = exports['thootje-jobs']:GetJob(source)
-- job.name, job.label, job.grade, job.gradeLabel, job.salary, job.onduty, job.isBoss

exports['thootje-jobs']:SetJob(source, 'police', 1)
exports['thootje-jobs']:SetDuty(source, true)

local employees = exports['thootje-jobs']:GetPlayersByJob('police', true)
```

## THOOTJE-CORE koppeling
De resource probeert server-side de actieve character-data op te halen via:
`exports['thootje-core']:GetPlayerData(source)`

Standaard zoekt hij naar `citizenid`, `charid`, `characterId`, `identifier` of `id`.
Als jouw core een andere export of veldnaam gebruikt, pas `getIdentifier()` in `server/main.lua` of `Config.IdentifierFields` aan.

De jobdata wordt opgeslagen in `thootje_jobs_players` en daarnaast gepubliceerd via:
- `Player(source).state.thootjeJob`
- client event `thootje-jobs:client:setJob`
- server event `thootje-jobs:server:jobUpdated`

Dit is bewust een losse jobs-resource zodat hij niet gokt naar onbekende interne THOOTJE-CORE functies. Koppel je core via het genoemde event als je `job` ook rechtstreeks in je core playerdata wilt opnemen.

## Salarissen
Elke 15 minuten (instelbaar) wordt het salaris uitbetaald. Standaard alleen als speler ingeklokt is.
Als `thootje-banking` actief is, gebruikt hij `AddBankMoney`.
Zonder banking probeert hij het event `thootje-core:server:addBankMoney` aan te roepen. Pas dit event aan op jouw core of zet banking aan.
Salarissen in `jobs.lua` zijn bedragen per betaalperiode, niet per uur.

## Belangrijk
- Overheidsbanen zijn verborgen uit de publieke sollicitatielijst en kunnen alleen via staff/exports worden toegekend.
- Dit pakket bevat jobdata, rangen, dienststatus, vacaturecentrum en salarissen. Het bevat niet de daadwerkelijke politie-, ambulance-, brandweer-, taxi- of voertuigwerkmissies; daarvoor koppel je aparte jobresources aan `thootjeJob`.
- De standaard jobcenter-coördinaten zijn voorbeeldlocaties. Pas ze aan naar jouw map/MLO.
- Test eerst op een stagingserver. Controleer de character-ID-export en de banking-export voordat je live gaat.

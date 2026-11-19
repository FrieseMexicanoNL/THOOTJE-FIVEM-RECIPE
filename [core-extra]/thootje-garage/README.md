# THOOTJE-GARAGE 1.0.0

Modern voertuig- en garagesysteem voor THOOTJE-CORE.

## Functies
- Meerdere openbare garages met eigen uitrijpunten.
- Voertuigenoverzicht met zoeken en filters.
- Voertuigen uitrijden en terug parkeren.
- Brandstof, motorconditie, carrosserie, vuil en basis tuninggegevens opslaan.
- Meerdere garages: een voertuig blijft staan op de locatie waar het is geparkeerd.
- Inbeslagname met vrijgavekosten.
- Voertuigen hernoemen.
- MySQL-opslag en server-side eigendomscontrole.
- Admincommando's om voertuigen uit te geven of in beslag te nemen.
- Exports voor dealer-, job- en andere voertuigresources.

## Installatie
1. Plaats `thootje-garage` in je resources-map.
2. Importeer `sql/thootje_garage.sql` in je database.
3. Controleer `Config.Identifier` in `config.lua`. De functie moet dezelfde character identifier teruggeven als je core en andere resources.
4. Start in `server.cfg`:
   ```cfg
   ensure oxmysql
   ensure thootje-core
   ensure thootje-banking
   ensure thootje-garage
   ```
5. Geef admins rechten:
   ```cfg
   add_ace group.admin thootje.garage.admin allow
   ```
6. Open een garage met `/garage`, F6 of de marker.

## Admincommando's
```text
givevehicle [server-id] [model] [kenteken]
impoundvehicle [kenteken]
```
Voorbeeld:
```text
givevehicle 12 sultan  NW123ABC
impoundvehicle NW123ABC
```

## Exports
```lua
-- Een voertuig toevoegen vanuit een car dealer:
exports['thootje-garage']:AddVehicle(
    ownerIdentifier, 'sultan', 'NW123ABC', 'Karin Sultan', 'legion',
    { fuel = 100, engine = 1000, body = 1000, dirt = 0, props = {} }
)

-- Voertuigen ophalen:
local vehicles = exports['thootje-garage']:GetOwnedVehicles(ownerIdentifier)

-- Voertuig in beslag nemen:
exports['thootje-garage']:SetVehicleImpounded('NW123ABC', true)
```

## Garages aanpassen
Pas `garages.lua` aan. Elke garage heeft:
- `label`: naam in de UI.
- `type`: `public` of `impound`.
- `coords`: interactiepositie.
- `spawn`: voertuiguitrijpunt als `vector4(x, y, z, heading)`.
- `blip`: toon/verberg de kaartmarkering.

Voeg bij nieuwe garages ook rekening met veilige uitrijruimte en bereikbaarheid.

## Integratie met THOOTJE-CORE / THOOTJE-BANKING
- `Config.Identifier` gebruikt als mogelijke koppeling `exports['thootje-core']:GetPlayerData(source)` met velden `citizenid`, `charid`, `characterId` of `identifier`; anders valt het terug op `license:`. Stem dit af op de echte core-data.
- Inbeslagnamekosten gebruiken `exports['thootje-banking']:RemoveBankMoney(source, amount)`. Controleer of jouw banking-versie exact deze export en argumentvolgorde heeft.
- De melding gebruikt `thootje-core:client:notify`. Pas dit event aan wanneer jouw core een andere notificatie-API gebruikt.
- Deze resource is bedoeld als garage/voertuigopslag. Een complete dealership, sleutelsysteem, verzekering, voertuigbelasting, schade-/reparatiebedrijf, trunk/glovebox-inventory en geavanceerde voertuigmods zijn aparte modules.

## Technische aandachtspunten
- De server controleert eigendom op basis van kenteken + character identifier; geef voertuigen daarom altijd via de export of admincommand uit.
- Test op een stagingserver met OneSync ingeschakeld. Het verwijderen van een geparkeerd voertuig gebruikt het network entity-ID.
- Het basispropsysteem bewaart kleur, wheel type, tint, livery en mod-slots. Extra's, neon, xenon, custom wheels en volledige modkit kunnen later uitgebreid worden.
- De resource bevat voorbeeldcoördinaten voor GTA V. Pas die aan wanneer je eigen MLO's of aangepaste garages gebruikt.

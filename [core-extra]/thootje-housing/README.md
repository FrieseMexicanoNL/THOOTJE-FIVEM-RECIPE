# THOOTJE-HOUSING 1.0.0

Huizen- en appartementensysteem voor THOOTJE-CORE.

## Functies
- Woningoverzicht met moderne NUI.
- Huizen en appartementen instelbaar via `config.lua`.
- Woningen kopen of huren.
- Huurtermijn (standaard 7 dagen); verlopen huur wordt periodiek vrijgegeven.
- Woninginterieurs met aparte routing buckets.
- Eigenaar kan huissleutels delen met spelers in de server.
- Blips, markers en interactie met E.
- Commando's: `/huizen`, `/huis`, `/huisverlaten`, `/huissleutel [woning-id] [server-id]`.
- Exports: `HasAccess`, `GetPropertyOwner`, `AddPropertyKey`.

## Installatie
1. Plaats `thootje-housing` in je resources-map.
2. Importeer `sql/thootje_housing.sql` in je database.
3. Controleer `shared/bridge.lua` en koppel `TH.GetIdentifier`, `TH.RemoveMoney` en `TH.AddMoney` aan de daadwerkelijke THOOTJE-CORE API.
4. Pas de woninglocaties en interieurcoördinaten in `config.lua` aan.
5. Zet in `server.cfg`:

```cfg
ensure oxmysql
ensure thootje-core
ensure thootje-housing
```

ACE voor beheer:
```cfg
add_ace group.admin thootje.housing.admin allow
```

## Belangrijke integratiepunten
De interne API van jouw THOOTJE-CORE is niet meegeleverd in deze resource. De bridge gebruikt als voorbeeld:
- `exports['thootje-core']:GetPlayerData(source)`
- `exports['thootje-core']:RemoveMoney(source, account, amount, reason)`
- `exports['thootje-core']:AddMoney(source, account, amount, reason)`

Als jouw core andere exportnamen of argumentvolgorde gebruikt, pas dan alleen `shared/bridge.lua` aan. De voorbeeldwoningen en interieurcoördinaten zijn testlocaties; gebruik je eigen MLO/shell-interieurs voordat je live gaat.

## Bekende beperkingen in 1.0.0
- Huur wordt vooraf betaald voor de ingestelde huurperiode; automatische incasso/verlenging ontbreekt.
- Geen meubelplaatsing, stash/inventory, kledingkast, garagekoppeling, makelaarsjob, hypotheek, woningverkoop door speler of appartementsgebouw met meerdere units.
- Sleutelbeheer is via de eigenaar en de NUI; sleutelintrekkingen kunnen via server event/export verder uitgebreid worden.
- Test eerst op een stagingserver. Koppel de core bridge en controleer dat de identifier hetzelfde is als in andere THOOTJE-resources.

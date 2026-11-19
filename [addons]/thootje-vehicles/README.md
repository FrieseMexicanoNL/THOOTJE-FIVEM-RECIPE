# THOOTJE-VEHICLES 1.0.0

Voertuigbezit en autosleutels voor THOOTJE-CORE, gekoppeld aan `thootje-garage`.

## Functies
- Eigenaar wordt bepaald via het voertuig in `thootje_garage_vehicles`.
- Sleutels delen met een speler die dichtbij staat.
- Gedeelde sleutels permanent opslaan in MySQL.
- Eigenaar kan gedeelde sleutels intrekken.
- Sleutelhoudersoverzicht per kenteken.
- Voertuig vergrendelen en ontgrendelen met U (instelbaar).
- Modern NUI-overzicht via F7 of `/vehiclekeys`.
- Server-side controle van sleutelrecht, kenteken en afstand bij vergrendelen.
- Admincommando om een sleutel uit te geven.
- Exports voor andere scripts.

## Installatie
1. Installeer eerst `thootje-garage` en importeer diens SQL. Deze resource leest de voertuigeigenaar uit `thootje_garage_vehicles`.
2. Importeer `sql/thootje_vehicles.sql`.
3. Controleer dat `Config.Identifier` dezelfde character identifier teruggeeft als `thootje-garage`.
4. Voeg aan `server.cfg` toe:
   ```cfg
   ensure oxmysql
   ensure thootje-core
   ensure thootje-garage
   ensure thootje-vehicles
   ```
5. Geef admins rechten:
   ```cfg
   add_ace group.admin thootje.vehicles.admin allow
   ```

## Gebruik
- `F7` of `/vehiclekeys`: open autosleutelmenu.
- `U` of `/vehiclelock`: vergrendel/ontgrendel het dichtstbijzijnde voertuig waarvoor je een sleutel hebt.
- In het menu kan de eigenaar een sleutel delen met een speler in de buurt. Vul diens server-ID in.
- Eigenaar kan gedeelde sleutels beheren en intrekken.

## Admin
```text
givevehiclekey [server-id] [kenteken]
```
Voorbeeld:
```text
givevehiclekey 12 NW123ABC
```

## Exports
```lua
-- Heeft speler een sleutel?
local allowed = exports['thootje-vehicles']:HasVehicleKey(source, 'NW123ABC')

-- Sleutel uitgeven door een ander script (owner identifier moet voertuigeigenaar zijn)
local ok = exports['thootje-vehicles']:GiveVehicleKey(ownerIdentifier, targetIdentifier, 'NW123ABC', 'Spelernaam')

-- Sleutel intrekken
local removed = exports['thootje-vehicles']:RemoveVehicleKey(ownerIdentifier, targetIdentifier, 'NW123ABC')

-- Alle voertuigtoegang van speler ophalen
local keys = exports['thootje-vehicles']:GetVehicleKeys(source)
```

## Integratie
- De eigenaar komt uit `thootje-garage` tabel `thootje_garage_vehicles`. Een voertuig moet dus eerst via de garage-resource/dealer-export geregistreerd zijn.
- `Config.Identifier` is een voorbeeldkoppeling met `exports['thootje-core']:GetPlayerData(source)` en fallback naar `license:`. Stem dit af op de echte character identifier.
- Notificaties gebruiken standaard `thootje-core:client:notify`; wijzig `Config.Notifications.event` als jouw core een andere notificatie gebruikt.
- Deze resource bevat geen hotwire, lockpick, sleutelverlies, voertuigtracker, alarm of immobilizer. Dat zijn logische uitbreidingen.
- Test met OneSync op een testserver. Client lock visuals worden toegepast na serverautorisatie; voor volledige entity-state synchronisatie kan je core/vehicle-sync resource een statebag lockstatus beheren.

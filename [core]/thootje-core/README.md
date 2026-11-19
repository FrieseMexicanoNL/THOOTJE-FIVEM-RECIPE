# Thootje Core 1.0.0

Standalone basisframework voor een eigen FiveM-stad. Dit pakket gebruikt **geen ESX, QBCore of Qbox**.

## Benodigd
- FXServer / recente artifact
- OneSync ingeschakeld
- MariaDB of MySQL
- `oxmysql` gestart vóór `thootje-core`

## Installatie
1. Zet de map `thootje-core` in je server resources.
2. Importeer `sql/thootje_core.sql` in je database.
3. Zet in `server.cfg`:
   ```cfg
   ensure oxmysql
   ensure thootje-core
   ```
4. Stel je databaseverbinding in bij de configuratie van oxmysql.
5. Start de server en verbind. Een spelerrecord wordt bij de eerste join automatisch aangemaakt.

## Ingebouwde onderdelen
- Standalone player lifecycle en database-opslag
- Accounts: cash, bank en black_money
- Jobs en grades (basis)
- Custom inventory API met slots, gewicht, stack-items en metadata
- Client/server callbacks
- Exports voor andere resources
- Autosave elke 5 minuten en opslaan bij disconnect/resource-stop
- Basis NUI HUD en inventory-overzicht
- Admincommando's (groep `admin`/`owner`)

## Commando's
- `/cash` — toont cash en bank
- `/inv` of F2 — opent inventory
- `/giveitem [id] [item] [aantal]` — admin
- `/setjob [id] [job] [grade]` — admin
- `/setmoney [id] [cash|bank|black_money] [bedrag]` — admin
- `/thootjehud` — HUD tonen/verbergen

**Let op:** maak jezelf na installatie admin via SQL:
```sql
UPDATE thootje_players SET group_name = 'owner' WHERE identifier = 'license:JOUW_LICENSE';
```

## API voor andere resources
```lua
local Core = exports['thootje-core']:GetCoreObject()
local Player = Core.Functions.GetPlayer(source)

Core.Functions.AddMoney(source, 'cash', 250, 'test-betaling')
Core.Functions.RemoveMoney(source, 'bank', 100, 'winkel')
Core.Functions.SetJob(source, 'police', 'Politie', 1, 'Agent')
Core.Functions.AddItem(source, 'water', 2)
Core.Functions.RemoveItem(source, 'water', 1)
```

Of gebruik exports:
```lua
local player = exports['thootje-core']:GetPlayer(source)
exports['thootje-core']:AddMoney(source, 'cash', 100)
```

## Nieuwe items
Voeg items toe aan `Config.Items` in `config.lua`:
```lua
radio = { label = 'Portofoon', weight = 800, stack = false, usable = true }
```

## Belangrijke ontwikkelstatus
Dit is een werkende **core-basis / MVP**, niet een complete stadsklare framework-suite. Er is bewust nog geen volledige multicharacter, appearance/skin, vehicle ownership/garage, housing, society/bossmenu, facturatie, bank UI, weapon handling, item-use handlers, stash/trunk/glovebox, permissionsysteem per command of uitgebreide admin UI ingebouwd. Deze onderdelen moeten als afzonderlijke modules worden toegevoegd en getest voordat je de core op een publieke productieserver gebruikt.

## Veiligheidsnotities
- Geef adminrechten alleen via server/databasebeheer.
- Voeg server-side validatie toe aan iedere gameplay-resource; vertrouw nooit client-input.
- Maak databaseback-ups voordat je schema's wijzigt.
- Test updates eerst op een aparte testserver.

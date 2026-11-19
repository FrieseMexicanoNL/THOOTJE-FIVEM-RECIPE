# THOOTJE-INVENTORY 1.0.0

Custom inventory resource voor THOOTJE-CORE. De interface is gebouwd in HTML/CSS/JS en de server controleert alle belangrijke inventarisacties.

## Vereisten
- FXServer met OneSync
- `oxmysql`
- `thootje-core` (de eerder gebouwde standalone core)
- Dezelfde itemdefinities in `thootje-core/config.lua` en deze resource

## Installatie
1. Plaats `thootje-inventory` in je resourcesmap.
2. Voeg de items uit `integration/CORE_CONFIG_ITEMS.lua` toe aan `Config.Items` in `thootje-core/config.lua`. Laat bestaande items staan; voeg alleen toe of werk ze bij.
3. Controleer dat de `thootje_players` tabel uit THOOTJE-CORE bestaat. De inventory wordt opgeslagen in de JSON-kolom `thootje_players.inventory`; er is dus geen extra tabel nodig.
4. Start resources in deze volgorde:
   ```cfg
   ensure oxmysql
   ensure thootje-core
   ensure thootje-multicharacter
   ensure thootje-inventory
   ```
   Als je multicharacter niet gebruikt, kun je die regel weglaten.
5. Start de server opnieuw.

## Gebruik
- `TAB` of `/inventory` — open inventory
- Klik een item aan om details te bekijken
- Sleep een item naar een andere slot om te verplaatsen of te wisselen
- Gebruik de knop **Gebruiken** voor bruikbare items
- **Neerleggen** laat één item op de grond vallen
- **Geven** vraagt om de server-ID van de ontvanger
- `/pickup` — pak het dichtstbijzijnde neergelegde item op (binnen ingestelde afstand)
- Sneltoetsen 1 t/m 5 gebruiken items in de eerste vijf slots

## Configuratie
Pas `config.lua` aan:
- `Config.MaxWeight`: maximaal gewicht in gram
- `Config.Slots`: aantal slots
- `Config.HotbarSlots`: aantal quickslots
- `Config.AllowDrop`, `Config.AllowGive`, `Config.AllowSplit`
- `Config.Items`: itemnamen, labels, gewicht, stack, bruikbaarheid, omschrijving en effect

## API voor andere resources
```lua
-- Server-side
exports['thootje-inventory']:AddItem(source, 'water', 2)
exports['thootje-inventory']:RemoveItem(source, 'water', 1)
local inventory = exports['thootje-inventory']:GetInventory(source)

-- Registreer een eigen itemhandler (item moet in Config.Items staan)
exports['thootje-inventory']:RegisterUsableItem('radio', function(source, item)
    TriggerClientEvent('my-radio:client:toggle', source)
end)
```

Client event voor generiek gebruik:
```lua
AddEventHandler('thootje-inventory:client:useItem', function(itemName, metadata)
    -- Koppel hier je eigen telefoon, radio, reparatieset, etc.
end)
```

## Huidige ingebouwde items
`water`, `bread`, `sandwich`, `bandage`, `phone`, `radio`, `repairkit`, `money`.

Water, brood, sandwich en verband hebben eenvoudige voorbeeld-effecten. Voor telefoon, radio en reparatieset moet je de bijbehorende aparte resource koppelen via `RegisterUsableItem` of het client event.

## Belangrijke technische grenzen van deze eerste versie
Dit is een functionele eerste versie voor de THOOTJE-CORE MVP, maar nog geen complete productie-inventorysuite:
- Neergelegde items bestaan voorlopig alleen in servergeheugen en verdwijnen bij een serverrestart; ze hebben nog geen fysieke prop/marker.
- Er zijn nog geen voertuigkofferbakken, handschoenenkastjes, stash/huizen, shops, crafting of weapon attachments.
- Er is nog geen item-image asset pack; de UI gebruikt herkenbare iconen als fallback.
- De core moet per character een aparte identifier gebruiken wanneer je multicharacter gebruikt. De inventaris wordt aan dat core-playerrecord gekoppeld.
- Test alle itemhandlers en overdrachten op een aparte testserver voordat je publiek gaat.

Alle mutaties van items, gewicht, slots, geven en oppakken worden server-side gecontroleerd. De client mag niet als betrouwbare bron voor inventorygegevens worden beschouwd.

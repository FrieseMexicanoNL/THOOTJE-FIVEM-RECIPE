# THOOTJE-SHOPS 1.0.0

Winkels, bouwmarkten en verkooppunten voor THOOTJE-CORE.

## Functies
- Moderne NUI in donkerblauw/turquoise stijl.
- Meerdere winkels en verkooppunten via `config.lua`.
- Producten kopen en items verkopen.
- Productcategorieën, zoekveld en prijzen.
- Configurabele locaties, markers en blips.
- Server-side controles op winkelafstand, product, hoeveelheid en saldo.
- Contante betaling via een inventory-item (standaard `money`).
- Transactielogboek in MySQL.
- Exports: `GetShops()` en `OpenShop(source, shopId)`.

## Vereisten
- FiveM server met OneSync.
- `thootje-core`
- `thootje-inventory` met exports `GetInventory`, `AddItem` en `RemoveItem`.
- `oxmysql`

## Installatie
1. Plaats de map `thootje-shops` in je resources-map.
2. Importeer `sql/thootje_shops.sql` in je database.
3. Controleer in `config.lua` of het betaalitem `money` heet en of de itemnamen bestaan in jouw inventory.
4. Controleer in `shared/bridge.lua` of `GetPlayerData(source)` en de identifier overeenkomen met jouw core.
5. Voeg toe aan `server.cfg`:

```cfg
ensure oxmysql
ensure thootje-core
ensure thootje-inventory
ensure thootje-shops
```

6. Herstart de server.

## Gebruik
- Loop naar een winkelmarker en druk op E.
- `/shops` opent de dichtstbijzijnde winkel.
- F7 is standaard gekoppeld aan `/shops`.
- Voeg of wijzig winkels en producten in `config.lua`.

## Eigen winkel toevoegen
Kopieer een blok uit `Config.Shops` en geef het een unieke sleutel. Gebruik `buy` voor producten die spelers kunnen kopen en `sell` voor items die spelers kunnen inleveren. `coords` moet een `vector3(x, y, z)` zijn.

## Belangrijke integratiepunten
- Deze versie gebruikt `money` als contant geld-item. Pas `Config.Currency.item` aan als jouw economy een andere itemnaam gebruikt.
- De bridge verwacht `thootje-inventory` exports met deze signatuur:
  - `GetInventory(source)`
  - `AddItem(source, itemName, amount)`
  - `RemoveItem(source, itemName, amount)`
- `GetInventory` moet een tabel teruggeven met itemvelden `name` of `item` en aantallen `amount`, `count` of `quantity`. Pas `CountItem` aan als jouw inventory anders is opgebouwd.
- `thootje-core:GetPlayerData(source)` moet een tabel met `citizenid`, `charid`, `identifier` of `license` teruggeven voor transactielogging.
- Gebruik een testserver om de exacte exports en inventory-returnstructuur te controleren voordat je live gaat.
- `UseTarget` staat standaard uit. De resource gebruikt markers en E-interactie.
- Producten en prijzen zijn voorbeelddata. Controleer of de genoemde items bestaan in jouw inventory.

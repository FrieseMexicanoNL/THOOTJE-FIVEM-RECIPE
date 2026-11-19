# THOOTJE-DRUGS 1.0.0

Uitgebreid illegaal drugs-RP-systeem voor FiveM en THOOTJE-CORE. Alle productiehandelingen zijn abstracte game-mechanics; er worden geen echte bereidingsinstructies gebruikt.

## Functies
- Farmen/verzamelen op configureerbare locaties.
- Drogen, verwerken en verpakken als afzonderlijke stappen.
- 11 productlijnen: cannabis, cocaïne, heroïne, meth, paddo's, opium, MDMA, LSD, crack, lean en XTC. MDMA- en siroopgrondstoffen hebben eigen farmzones; crack gebruikt een tussenproduct uit de cocaïnelijn.
- Verkoop aan NPC's met G (of `/drugsell`).
- Weigering, NPC-roof, willekeurige prijs, cooldowns en NPC-hergebruikbeveiliging.
- Vaste illegale groothandel/verkooplocaties.
- Politie-alert met kansinstelling, cooldown en locatiepayload.
- Inventory-adapter voor THOOTJE-INVENTORY.
- Banking-adapter voor cashuitbetaling.
- MySQL auditlog voor farmen, verwerken, verkopen en politie-alerts.
- Server-side zone-, afstand-, item- en voertuigvalidatie.
- Configureerbare locaties, hoeveelheden, prijzen, risico's en progressieduur.

## Benodigd
- FiveM server met OneSync ingeschakeld.
- `oxmysql`
- `ox_lib`
- `thootje-core`
- `thootje-inventory`
- Optioneel: `thootje-jobs`, `thootje-banking`, `thootje-politiejob`

## Installatie
1. Plaats `thootje-drugs` in je resources-map.
2. Importeer `sql/thootje_drugs.sql` in je database.
3. Voeg de items uit `integration/items.lua` toe aan jouw item-definities in THOOTJE-INVENTORY.
4. Controleer de exportnamen in `config.lua` en `shared/bridge.lua`.
5. Voeg toe aan `server.cfg`:

```cfg
ensure oxmysql
ensure ox_lib
ensure thootje-core
ensure thootje-jobs
ensure thootje-inventory
ensure thootje-banking
ensure thootje-politiejob
ensure thootje-drugs

add_ace group.admin thootje.drugs.admin allow
```

## Gebruik
- Loop naar een marker en druk E.
- Farmzones geven ruwe grondstoffen.
- Droogzones zetten grondstoffen om naar gedroogde producten.
- Het lab verwerkt deze tot tussenproducten.
- Verpakkingslocaties maken verkoopbare pakketten.
- Druk G bij een NPC om een deal te proberen.
- Loop naar een illegaal verkooppunt en druk E voor bulkverkoop.
- `/druginfo` toont alle productlijnen.

## Belangrijke integratiepunten — controleer dit voor livegang
De exacte API's van jouw eigen THOOTJE-resources zijn niet automatisch bekend. Deze versie gebruikt als standaard:
- Inventory: `AddItem(source, item, amount)`, `RemoveItem(source, item, amount)`, `HasItem(source, item, amount)`, `GetInventory(source)`.
- Core: `GetPlayerData(source)` met `citizenid`, `charid`, `identifier` of `license`.
- Jobs: `GetJob(source)` met `name`, `grade` en `duty`.
- Banking: `AddCashMoney(source, amount, reason)`; fallback event `thootje-core:server:addMoney`.

Als jouw resources andere namen of argumentvolgordes gebruiken, pas `shared/bridge.lua` en de banking-call in `server/main.lua` aan. De inventory-exportsignaturen moeten exact overeenkomen.

## Politie-integratie
Het script stuurt een server-event `thootje-politiejob:server:drugAlert` en een fallback `thootje-politiejob:server:customDispatch` met een payload:
`code`, `title`, `description`, `coords`, `source`, `duration`.

De politiejob moet één van deze events afhandelen en een melding/blip versturen naar agenten die in dienst zijn. Als jouw politiejob nog geen event-handler heeft, voeg de voorbeeldhandler uit `integration/police_dispatch.lua` toe of koppel het aan je bestaande dispatch.

## Security-notities
- Verkoop en productie worden server-side gevalideerd op afstand en vereiste items.
- Verkoopprijzen en hoeveelheden worden server-side bepaald.
- NPC network-ID en afstand worden gecontroleerd.
- De scriptlog is bedoeld voor staffcontrole.
- Gebruik een staging-server en test de exports voordat je live gaat.

## Locaties
Alle locaties zijn voorbeelden en staan in `config.lua`. Verplaats ze naar jouw MLO's/interieurs. De farmzones zijn publiek zichtbaar in config; zet `Config.Blips.Enabled = false` om blips uit te laten.

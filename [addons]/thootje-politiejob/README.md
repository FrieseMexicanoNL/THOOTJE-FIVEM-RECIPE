# THOOTJE-POLITIEJOB 1.0.0

Uitgebreide politiejob voor THOOTJE-CORE, met animaties, MDT, dienstcommando's, boetes, rapportages, fouilleren, arrestaties, transport en gevangenisstraf.

## Functies
- MDT met dashboard, online politieoverzicht, personen zoeken, rapportages en boete-overzicht.
- Rapportages opslaan in MySQL.
- Handboeien / ontboeien met animaties en beperkte controls.
- Escorten van geboeide spelers.
- Fouilleeranimatie en server-side afstandscontrole.
- Boetes registreren met reden en bedrag.
- Spelers opsluiten en automatisch vrijlaten na de ingestelde tijd (runtime-timer).
- Dienstwapens uitgeven met rang- en dienstcontrole.
- Politievoertuigen uitgeven op basis van rang.
- Paniekmelding naar agenten die in dienst zijn.
- Instelbare rangen, permissies, locaties, voertuigen, wapens en animaties.
- MySQL logging van rapporten, boetes en celstraffen.

## Vereisten
- `oxmysql`
- `thootje-core`
- `thootje-jobs`
- De `thootje-jobs` export `GetJob(source)` moet jobnaam, grade en on-duty status teruggeven. Alternatief wordt `Player(source).state.thootjeJob` gelezen.
- Character identifier via `thootje-core:GetPlayerData(source)`.

## Installatie
1. Plaats `thootje-politiejob` in je resources-map.
2. Importeer `sql/thootje_politiejob.sql`.
3. Controleer de jobnaam en grade-indeling in `config.lua`. Standaard jobnaam is `police`.
4. Voeg aan `server.cfg` toe:

```cfg
ensure oxmysql
ensure thootje-core
ensure thootje-jobs
ensure thootje-politiejob
```

5. Start opnieuw en test met een politiepersonage op een testserver.

## Commando's
- `/politie` - politiecommando-overzicht.
- `/mdt` of F6 - politie-MDT.
- `/cuff` - boeien / ontboeien dichtstbijzijnde speler.
- `/escort` - escorteren van geboeide speler.
- `/search` - fouilleeractie en animatie.
- `/fine [server-id] [bedrag] [reden]` - boete registreren.
- `/jail [server-id] [minuten]` - speler opsluiten.
- `/unjail [server-id]` - speler vrijlaten.
- `/panic` - paniekmelding naar agenten in dienst.
- `/pdarmory` en `/pdweapon [nummer]` - dienstwapen uitgeven.
- `/pdgarage` en `/pdvehicle [nummer]` - dienstvoertuig uitgeven.

## Rang- en dienstvereisten
De grade nummers in `Config.Ranks` en `Config.Permissions` moeten overeenkomen met de politiegrades in `thootje-jobs`. Alle serveracties controleren job, dienststatus, rang en waar relevant de afstand tot het doelwit.

## Animaties
- Boeien: `mp_arrest_paired` / `mp_arresting`.
- Fouilleren: `anim@gangops@facility@servers@bodysearch@`.
- MDT bevat CSS-overgangen, hover-effecten en een pulserende online-indicator.

## Belangrijke grenzen van 1.0.0
- De fouilleerfunctie speelt de animatie af, maar leest of verplaatst nog geen inventory-items. Daarvoor moet de exacte API van jouw `thootje-inventory` worden gekoppeld.
- Boetes worden geregistreerd in de politie-database; automatische facturatie via `thootje-billing` is nog niet gekoppeld.
- Wapens worden in deze basisversie via GTA weapon natives uitgegeven, niet als persistent inventory-items.
- Gevangenisstraf-timers draaien in runtime en worden bij een serverrestart niet hervat. Persistent jail/reconnect handling is een logische volgende uitbreiding.
- De dienstgarage spawnt voertuigen bij de speler; er is nog geen parkeer-/impoundsysteem of voertuig-key bridge.
- Dienst aan/uit wordt niet vanuit dit resource-menu omgezet; dit gebruikt de dienststatus van `thootje-jobs`.
- De exacte exports van jouw eigen THOOTJE-CORE en THOOTJE-JOBS kunnen afwijken. Controleer `shared/bridge.lua` en test op een stagingserver.

## Aanbevolen uitbreidingen voor v2
Persistent gevangenissysteem, inventory-fouilleren met itemoverdracht, facturen via THOOTJE-BILLING, politie-radio/dispatch, voertuigregistratie en kentekenopzoeking, bewijsbeheer, wapenkast met loadouts, kledingmenu en bossmenu.


## Koppelingen v1.1.0: inventory en billing

### Fouilleren / items innemen
In MDT → Personen zoeken → zoek een speler → **FOUILLEER**. De inventaris wordt server-side opgehaald via `thootje-inventory`. Kies **NEEM IN** bij een item en vul het aantal in. De verdachte moet geboeid zijn en binnen `Config.SearchDistance` staan. Verwijderen gaat via de officiële `RemoveItem`-export; daarna wordt de lijst opnieuw geladen.

### Politieboetes
Nieuwe politieboetes worden als normale facturen opgeslagen in `thootje_billing_invoices`. De burger betaalt via THOOTJE-BILLING; de politie ziet ze terug in het MDT-tabblad **Boetes**. Er wordt geen extra factuurtoeslag gerekend. De omschrijving begint met `Politieboete:`.

### Startvolgorde
```cfg
ensure oxmysql
ensure thootje-core
ensure thootje-jobs
ensure thootje-inventory
ensure thootje-banking
ensure thootje-billing
ensure thootje-politiejob
```
Gebruik THOOTJE-BILLING 1.1.0 of hoger (server-export `CreateInvoice`) en importeer de bestaande billing SQL. Er is geen extra SQL nodig voor de inventorykoppeling. Zorg dat alle resources dezelfde character identifier gebruiken.

**Financiële afhandeling:** politieboetes worden als factuur geregistreerd, maar worden niet als persoonlijk inkomen aan de agent uitbetaald. Voor een latere gemeentekas/society-uitbetaling is een aparte society-koppeling nodig.

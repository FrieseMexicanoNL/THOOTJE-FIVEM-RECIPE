# THOOTJE-AMBULANCEJOB 1.0.0

Uitgebreide standalone ambulancedienst voor **THOOTJE-CORE**, gekoppeld aan:
- `thootje-jobs` voor functie, rangen en dienststatus.
- `thootje-inventory` voor medische benodigdheden.
- `thootje-billing` voor patiëntfacturen.
- `oxmysql` voor 112-meldingen en behandelregistraties.

## Inbegrepen functies

### Ambulance MDT (F7 of `/ems`)
- Operationeel dashboard met medewerkers, dienststatus en open meldingen.
- 112-dispatch met meldingen accepteren, waypoint zetten en afronden.
- Nabije spelerslijst met afstand en health-indicatie.
- Medische acties vanuit de patiëntenlijst.
- Recente behandelregistraties.
- Facturatie via THOOTJE-BILLING.
- Dienstgarage met ranggebonden voertuigen.
- Paniekknop die alle ambulancecollega's in dienst waarschuwt.

### Medische handelingen
| Actie | Item dat de medewerker verbruikt | Effect |
|---|---|---|
| Reanimeren | `medikit` x1 | Brengt een neergehaalde speler terug met 150 health |
| Verband aanleggen | `bandage` x1 | Herstelt 45 health |
| Stabiliseren | `firstaidkit` x1 | Brengt een levende patiënt minimaal naar 110 health |

Alle behandelacties worden server-side gecontroleerd op ambulancefunctie, dienststatus, rang, afstand en beschikbare items. Het item wordt verwijderd via `exports['thootje-inventory']:RemoveItem`. Elke actie wordt in `thootje_ems_treatments` geregistreerd.

### 112-meldingen
- Iedere speler kan `/112 [omschrijving]` gebruiken.
- De melding wordt in MySQL opgeslagen met coördinaten.
- Ambulancepersoneel dat in dienst is krijgt een melding.
- Een medewerker kan de melding accepteren; er wordt automatisch een waypoint gezet.
- Alleen de toegewezen medewerker kan de melding afronden.
- Bij disconnect van de toegewezen medewerker wordt de melding opnieuw opengezet.

### Facturatie
- Via MDT → Facturatie kan een medewerker een factuur maken voor een speler.
- De factuur wordt als normale factuur aangemaakt via `thootje-billing` (`CreateInvoice`).
- De patiënt ziet de rekening in THOOTJE-BILLING en kan die via de bestaande betaalflow voldoen.
- Er wordt geen factuurtoeslag berekend en geen persoonlijk inkomen aan de medewerker uitgekeerd (`noFee=true`, `noPayout=true`).
- De factuur gebruikt de afzendernaam **Ambulancedienst**.

### Rangen en rechten
De resource gebruikt `ambulance` uit `thootje-jobs`. De standaard rangen zijn:
0. Ambulancechauffeur in opleiding
1. Ambulancechauffeur
2. Ambulanceverpleegkundige
3. Senior Verpleegkundige
4. Trauma-arts
5. Ambulancecommandant

De minimale rang per actie staat in `config.lua` onder `Config.Permissions`.

## Installatie

1. Plaats de map `thootje-ambulancejob` in je resources-map.
2. Importeer `sql/thootje_ambulancejob.sql`.
3. Voeg de medische items toe aan de itemdefinities:
   - Voeg `integration/CORE_CONFIG_ITEMS.lua` toe aan `Config.Items` in `thootje-core/config.lua`.
   - Voeg `integration/INVENTORY_CONFIG_ITEMS.lua` toe aan `Config.Items` in `thootje-inventory/config.lua`.
   - `bandage` bestaat al in de standaard THOOTJE-CORE itemset; controleer wel dat deze ook in de inventory itemdefinities staat.
4. Controleer dat THOOTJE-BILLING 1.1.0 of hoger draait, met de server-export `CreateInvoice` en de kolom `no_payout`.
5. Zet in `server.cfg`:

```cfg
ensure oxmysql
ensure thootje-core
ensure thootje-jobs
ensure thootje-inventory
ensure thootje-banking
ensure thootje-billing
ensure thootje-ambulancejob
```

`thootje-banking` moet gestart zijn voor betalingen via THOOTJE-BILLING. Pas de volgorde aan als je eigen dependencies anders zijn.

## Functie toewijzen
Via console of staff:
```text
/setjob [server-id] ambulance [rang]
```
Voorbeeld:
```text
/setjob 12 ambulance 2
```
De medewerker kan daarna bij een ambulancepost of met `/emsduty` in- en uitklokken. Het algemene `/dienst`-commando van THOOTJE-JOBS blijft ook werken.

## Commando's
- `/ems` — open ambulance MDT.
- `F7` — open ambulance MDT.
- `/emsduty` — in/uit dienst.
- `/112 [omschrijving]` — stuur een noodmelding.
- `/emsrevive [server-id]` — reanimeer dichtstbijzijnde patiënt of opgegeven speler.
- `/emsheal [server-id]` — verband aanleggen.
- `/emsstabilize [server-id]` — stabiliseren.
- `/emsgarage [postnummer]` — toon garagevoertuigen.
- `/emspanic` — paniekmelding.

## Configuratie
- `Config.Stations`: coördinaten van Pillbox, Sandy Shores en Paleto.
- `Config.Vehicles`: voertuigmodellen en minimale rang.
- `Config.MedicalItems`: itemnamen en aantallen.
- `Config.Treatment`: health-effecten.
- `Config.Permissions`: rangvereisten.
- `Config.Security`: afstanden, cooldowns en factuurlimieten.

## Exports
Server-side:
```lua
exports['thootje-ambulancejob']:GetOnDutyMedics()
exports['thootje-ambulancejob']:IsOnDutyMedic(source)
```

## Belangrijke integratie-opmerkingen
- De koppeling is geschreven voor de API's uit de meegeleverde THOOTJE-resources: `thootje-jobs:GetJob/SetDuty`, `thootje-inventory:GetInventory/RemoveItem` en `thootje-billing:CreateInvoice`.
- De billing-koppeling gebruikt dezelfde character identifier als THOOTJE-CORE (standaard license identifier in de huidige core MVP).
- De standaard itemdefinities moeten zowel in de core als in de inventory aanwezig zijn. Als een item niet in beide staat, kan het niet betrouwbaar worden toegevoegd of gebruikt.
- De reanimatie gebruikt de GTA/FiveM `NetworkResurrectLocalPlayer`-native op de patiëntclient. Als je server al een aparte death/laststand-resource gebruikt, koppel dan diens revive-event in `client/main.lua` bij `applyTreatment` in plaats van de native direct.
- De resource is een uitgebreide basisversie; er zit nog geen bed-/ziekenhuisopname, ambulance stretcher-prop, ziekenhuisrekening op automatische respawn, of society-kasboek in.
- Test op een stagingserver met twee spelers. Controleer vooral of je death-script de revive-native toestaat en of je billingversie de `CreateInvoice` export aanbiedt.

### Validatie en voertuiggarage
- Reanimatie wordt alleen uitgevoerd wanneer de server de patiënt als neergehaald ziet (health ≤ 101). Verband/stabilisatie kan alleen bij een levende patiënt.
- Het tabblad Dienstgarage vraagt de voertuiglijst op. Het voertuig zelf kan alleen worden gespawned wanneer de medewerker bij de garagecoördinaten van de geselecteerde post staat.

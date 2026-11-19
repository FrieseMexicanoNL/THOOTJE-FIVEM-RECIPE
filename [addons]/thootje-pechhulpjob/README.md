# THOOTJE-PECHHULPJOB 1.0.0

Pechhulpdienst-resource voor THOOTJE-CORE met tablet, meldingen, voertuigkeuring, onderhoudshistorie, abonnementen, werkplaats-crafting en facturen.

## Installatie
1. Zet `thootje-pechhulpjob` in je resources map.
2. Importeer `sql/thootje_pechhulpjob.sql` in je database.
3. Voeg items uit `integration/items.lua` toe aan de itemlijst van `thootje-inventory`.
4. Controleer `shared/bridge.lua` en pas exports aan op jouw exacte THOOTJE-CORE / THOOTJE-JOBS / THOOTJE-INVENTORY.
5. Voeg aan `server.cfg` toe:
```
ensure oxmysql
ensure ox_lib
ensure thootje-core
ensure thootje-jobs
ensure thootje-inventory
ensure thootje-banking
ensure thootje-pechhulpjob
```
6. Maak job `pechhulp` aan in THOOTJE-JOBS. Medewerkers moeten in dienst staan.

## Commands
- `/pechhulp` - burger meldt pech.
- `/pechhulptablet` of F6 - tablet voor medewerkers.
- `/pechhulpabonnement` - abonnement kopen.

## Functionaliteit in deze versie
- Pechmeldingen met probleem, kenteken, telefoon en locatiegegevens.
- Tablet met actieve meldingen, aannemen en afsluiten.
- Voertuigregistratie, kilometerstand, onderhoudshistorie, APK-vervaldatum en rijwaardig/afgekeurd-status.
- Kleine beurt-interval en APK-interval instelbaar in `config.lua`.
- Accu-, brandstof-, reparatie- en sleepdienstservice registreren.
- Basic en Plus-abonnementen met instelbare kortingen.
- Werkplaats-crafting voor repairkits, accu's en brandstofkannen; alleen actieve pechhulpmedewerkers.
- Facturen aan online klanten versturen via tablet.
- Afgekeurde voertuigen blokkeren als ze in de eigen client in gebruik zijn.
- Sloopactie bij ingestelde autosloperij; onderdelen worden als inventory-items uitgekeerd.

## Belangrijke integratiepunten / beperkingen
Dit is een basisresource met echte server-side opslag, maar de exacte exports van jouw THOOTJE-resources zijn niet in deze chat geverifieerd. De bridge gaat uit van:
- `exports['thootje-core']:GetPlayerData(source)`
- `exports['thootje-jobs']:GetJob(source)`
- `exports['thootje-inventory']:AddItem/RemoveItem/HasItem(source,item,amount)`
- `exports['thootje-banking']:RemoveBankMoney(source,amount,reason)`

Pas deze aan als jouw exports anders heten. De abonnementsbetaling is fail-closed als de banking-export niet bestaat. De facturen worden in deze resource opgeslagen en als melding naar de klant gestuurd; automatische inning via `thootje-billing` moet aan de API daarvan gekoppeld worden.

**Nog niet volledig aangesloten:** voertuigkilometers automatisch uitlezen/optellen, APK-maandelijkse automatische blokkade van alle spelers/overheidsvoertuigen, voertuigbeperkingen server-side voor alle clients, echte OBD-diagnose, dispatch GPS-routing, fysieke repairkit-reparatie, sleepwagen/flatbed gameplay, betaling/afhandeling via THOOTJE-BILLING, automatisch slopen van owned-vehicle record uit jouw garage database en abonnementsaanvraag via fysieke balie. De sloopfunctie vereist medewerker in voertuig bij de sloperij en keuringstatus afgekeurd; parts-aantal wordt server-side begrensd.

## Configuratie
- Jobnaam, prijzen, kortingen, service- en APK-intervallen.
- Workshop locaties en autosloperij-coördinaten.
- Crafting-recepten en itemnamen.
- Inventory/banking-integratie.

Test eerst op een ontwikkelserver. Verifieer de jobnaam en character identifier, want die moeten identiek zijn aan de rest van je THOOTJE-resources.

## Versie 1.1.0 - uitbreidingen
- Automatische kilometerregistratie tijdens rijden (interval instelbaar); server controleert bestuurder, kenteken en plausibele afstand.
- Onderhoudswaarschuwing zodra het ingestelde service-interval is bereikt.
- APK-vervaldatum wordt automatisch gecontroleerd; verlopen APK zet het voertuig op afgekeurd.
- Rijblokkade bij instappen/rijden voor voertuigen die in deze resource geregistreerd staan als afgekeurd, gesloopt of met verlopen APK. Dit geldt ook voor politie-, ambulance-, brandweer- en andere overheidsvoertuigen zodra ze worden gereden/geregistreerd.
- OBD-achtige voertuigscan: motor, carrosserie, brandstof en lekke banden; advies of reparatie op locatie haalbaar lijkt of een sleepdienst nodig is.
- Kleine beurt registreren via de tablet en onderhoudsinterval opnieuw instellen.
- Factuuradapter richting THOOTJE-BILLING toegevoegd. De code probeert standaard de configureerbare export `CreateInvoice` aan te roepen. De exacte invoice-export van jouw THOOTJE-BILLING-build is niet in deze projectbestanden aanwezig; controleer `Config.Billing.CreateInvoiceExport` en pas de argumentvolgorde in `sendBillingInvoice` aan op jouw echte export. Event fallback staat standaard uit om dubbele/onbedoelde facturen te voorkomen.
- Voer voor bestaande installaties `sql/upgrade_1.1.0.sql` uit. Nieuwe installaties gebruiken `sql/thootje_pechhulpjob.sql`.

### Kilometerregistratie en voertuigimport
De automatische kilometerstand begint te tellen vanaf het moment dat de resource actief is en het voertuig wordt bestuurd. Bestaande voertuigen kunnen vooraf in `thootje_pch_vehicles` worden geïmporteerd met hun actuele kenteken, kilometerstand, APK-vervaldatum en eigenaar. Overheidsvoertuigen worden niet uitgezonderd; ze moeten wel een record hebben of eerst door een bestuurder worden geregistreerd. Niet-geregistreerde voertuigen worden nog niet automatisch afgekeurd.

### Diagnose en sleepdienst
De diagnose gebruikt GTA-voertuigstatuswaarden als simulatie van een uitleesapparaat; het is geen echte mod-specifieke OBD-data. De diagnose geeft een indicatie. De daadwerkelijke flatbed/sleepwagen-aanhaakmechaniek is nog niet toegevoegd; de medewerker kan op basis van de diagnose een sleepdienst registreren en factureren.

### Billing-koppeling
De vorige bekende THOOTJE-BILLING-functies omvatten bankbalans en bankgeldmutaties; een exacte factuur-aanmaakexport is niet bevestigd. Daarom blijft de lokale factuur altijd opgeslagen en wordt de externe factuur alleen aangemaakt als de geconfigureerde export daadwerkelijk bestaat en slaagt. Pas de bridge aan op de precieze API van jouw billing-resource.

# THOOTJE-CLOTHING 2.0

Modern kleding-, kapsalon-, tattoo-, gezichts- en uniformresource voor THOOTJE-CORE.

## Inbegrepen
- Moderne kledingwinkel en persoonlijke kledingkast met live GTA-ped preview.
- Outfits opslaan, aantrekken en verwijderen (MySQL).
- Kapsalon: kapselmodel en haarkleur/highlights.
- Gezichtsstudio: 20 GTA face features.
- Tattoo studio: configureerbare tattoo collection/hash presets en tattoos wissen.
- Jobuniformen voor politie en ambulance (voorbeeldconfiguraties).
- Betaalfunctionaliteit voor kleding, kapsel, gezicht en tattoos via configureerbare banking-export.
- Meerdere winkels, kapsalons en tattoo locaties.

## Installatie
1. Plaats `thootje-clothing` in je resources map.
2. Importeer `sql/thootje_clothing.sql` (bij een bestaande installatie is de outfit-tabel hetzelfde).
3. Controleer de export in `config.lua`:
   `exports['thootje-banking']:RemoveCashMoney(source, amount, reason)`
   Pas `Resource` en `RemoveCashExport` aan op de werkelijke API van jouw banking-resource.
4. Voeg toe aan `server.cfg`, in deze volgorde:
   ```
   ensure oxmysql
   ensure ox_lib
   ensure thootje-core
   ensure thootje-jobs
   ensure thootje-banking
   ensure thootje-clothing
   ```
5. Start de server en test eerst op een testserver.

## Commands
- `/clothing` of F5: kledingwinkel-editor.
- `/wardrobe`: kledingkast-editor.
- `/joboutfit`: uniform van je huidige baan aantrekken.
- `/kapsalon`: kapsel en haarkleur aanpassen.
- `/gezicht`: gezichtsinstellingen aanpassen.
- `/tattoos`: tattoo studio openen.

## Belangrijke configuratie
- `Config.Wardrobes` staat bewust leeg. Voeg je eigen kledingkastlocaties toe.
- `Config.JobUniforms` bevat voorbeeld drawable/texture IDs. Pas deze aan op jouw kledingpakket; IDs verschillen per kledingpack.
- `Config.Tattoos` bevat voorbeeldnamen. Gebruik alleen geldige GTA tattoo collection/hash combinaties die in jouw game/DLC beschikbaar zijn.
- Alleen `mp_m_freemode_01` en `mp_f_freemode_01` worden ondersteund.
- De banking-export is niet universeel. De standaardnaam is een configureerbaar voorbeeld; controleer de daadwerkelijke export en parameters van jouw `thootje-banking`.
- De job bridge probeert `thootje-jobs:GetJob(serverId)` en daarna `LocalPlayer.state.thootjeJob`. Als jouw core/jobs andere velden gebruiken, pas `openJobUniforms()` aan.
- De voorbeelduniformen zijn niet afgestemd op een specifiek EUP/kledingpakket.
- Tattoo- en face-native wijzigingen worden op de ped toegepast. Deze versie slaat gezichts- en tattoo-instellingen nog niet afzonderlijk persistent op; sla een outfit op voor de kledingcomponenten.
- Betaalbedragen worden server-side gecontroleerd. De uiteindelijke geldafschrijving hangt af van de correcte banking-export.

## SQL
`sql/thootje_clothing.sql` maakt de outfit-tabel aan. Bij upgrade van 1.0.0 hoef je de bestaande outfit-tabel niet te verwijderen of opnieuw aan te maken.

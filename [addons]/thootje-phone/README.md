# THOOTJE-PHONE 1.0.0

Een smartphone resource voor FiveM / THOOTJE-CORE met moderne NUI.

## Inbegrepen apps
- Telefoon: toetsenblok, uitgaande gesprekken, inkomende gesprekken en snel bellen via contacten.
- Berichten: SMS verzenden en ontvangen, gesprekken bewaren in MySQL.
- Contacten: toevoegen, bekijken, verwijderen en SMS starten.
- Notities: persoonlijke notities maken, wijzigen en verwijderen.
- Instellingen: eigen nummer bekijken en achtergrond kiezen.
- Uniek telefoonnummer per character.
- Gespreksignalisatie met optionele pma-voice call channel.
- Rate limit voor SMS en server-side validatie.

## Installatie
1. Plaats `thootje-phone` in je resources-map.
2. Importeer `sql/thootje_phone.sql`.
3. Controleer `shared/bridge.lua`: `GetPlayerData(source)` moet de juiste character identifier teruggeven.
4. Zet in `server.cfg`:

```cfg
ensure oxmysql
ensure thootje-core
ensure pma-voice # alleen nodig voor voice tijdens telefoongesprekken
ensure thootje-phone
```

5. Open met `/phone` of F1.

## THOOTJE-CORE bridge
De resource probeert:
`exports['thootje-core']:GetPlayerData(source)` en leest `citizenid`, `identifier` of `charid`.

Als jouw core een andere export of identifier gebruikt, pas `THPhone.GetIdentifier` in `shared/bridge.lua` aan. Dit moet dezelfde character identifier opleveren als je andere THOOTJE-resources.

## Voice calls
- `Config.CallVoiceMode = 'pma-voice'` gebruikt `pma-voice:setCallChannel` aan beide kanten.
- Voor andere voice resources zet je dit op `none` en maak je de voice-koppeling in `client/main.lua`.
- De call-signalisatie werkt los van audio. Zonder ondersteunde voice-koppeling kunnen spelers wel een gesprek starten/accepteren, maar horen ze elkaar niet via de telefoon.

## Configuratie
- Nummerprefix en lengte in `config.lua`.
- Contactlimiet, SMS-limiet en rate limit.
- Opencommando en toets.
- Achtergronden en apps.
- `Config.PhoneItemRequired` staat standaard uit. Voor inventory-itemcontrole moet jouw inventory API worden gekoppeld.

## Beperkingen van 1.0.0
- Geen WhatsApp/social media, bankieren, camera, GPS/navigation, mail, facturen, advertenties of dispatch app.
- Geen fysieke telefoon-item integratie out-of-the-box; inventory bridge moet worden aangesloten.
- SMS is persistente tekst, maar geen groepschat of media.
- Contacten en berichten zijn gekoppeld aan de character identifier.
- Voor productie: test op staging, configureer de juiste identifier en voice-resource.

## Exports
- `exports['thootje-phone']:GetPhoneNumber(source)` - telefoonnummer van speler.
- `exports['thootje-phone']:SendMessage(senderSource, targetNumber, message)` - verstuurt een SMS vanuit een online speler.

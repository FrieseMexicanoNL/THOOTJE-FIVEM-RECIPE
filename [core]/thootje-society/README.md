# THOOTJE-SOCIETY 1.0.0

Bedrijven, overheidsorganisaties, bedrijfsrekeningen en medewerkersbeheer voor THOOTJE-CORE.

## Inbegrepen
- Bedrijfsrekeningen met unieke rekeningnummers en MySQL-opslag.
- Storten vanaf de persoonlijke bankrekening.
- Opnemen en overboeken tussen bedrijfsrekeningen (alleen directie/bedrijfsleiding).
- Transactiegeschiedenis.
- Medewerkers aannemen, ontslaan en rang aanpassen.
- Publieke bedrijven en overheidsorganisaties in `societies.lua`.
- Exports voor andere scripts om bedrijfsinkomsten/-uitgaven te boeken.
- Moderne Nederlandstalige NUI.

## Installatie
1. Zet `thootje-society` in je resources-map.
2. Importeer `sql/thootje_society.sql` in je database.
3. Controleer de exports in `config.lua` en pas de identifier/playerdata-koppeling aan op jouw THOOTJE-CORE.
4. Start resources in deze volgorde:
   ```cfg
   ensure oxmysql
   ensure thootje-core
   ensure thootje-banking
   ensure thootje-society
   ```
5. Geef serverbeheerders toegang:
   ```cfg
   add_ace group.admin thootje.society.admin allow
   ```
6. Stel medewerkers in via console of admin:
   ```text
   societysetjob [server-id] [bedrijf] [rang]
   ```
   Voorbeeld: `societysetjob 12 mechanic 4`

Open het menu met `/society` of F7.

## Standaard bedrijven
- `mechanic` — Garagebedrijf
- `taxi` — Taxi Centrale

## Overheidsorganisaties
- `police` — Politie
- `ambulance` — Ambulancedienst
- `government` — Gemeente

Rangen en boss-rangen staan in `societies.lua`. Coördinaten en labels kun je daar aanpassen.

## Exports
```lua
local account = exports['thootje-society']:GetSocietyAccount('mechanic')
exports['thootje-society']:AddSocietyMoney('mechanic', 2500, 'Reparatiefactuur #104')
local success = exports['thootje-society']:RemoveSocietyMoney('mechanic', 500, 'Onderdelen')
local job = exports['thootje-society']:GetEmployeeSociety(source)
```

`GetSocietyAccount` geeft een tabel terug met `society`, `account_number` en `balance`.
`AddSocietyMoney` en `RemoveSocietyMoney` retourneren true/false.

## Belangrijke integratie-opmerkingen
- Deze resource gebruikt `exports['thootje-core']:GetPlayerData(source)` als mogelijke bron voor character-ID en naam. Als jouw core andere veldnamen/exportnamen gebruikt, pas `Config.Identifier` en `Config.PlayerName` aan.
- De persoonlijke banktransacties verwachten exports in `thootje-banking`: `RemoveBankMoney(source, amount)`, `AddBankMoney(source, amount)` en optioneel `GetBankMoney(source)`. Controleer of jouw geïnstalleerde banking-versie deze signatures aanbiedt. Als ze anders zijn, pas `bankCall` in `server/main.lua` aan.
- Zonder passende bank-export kunnen persoonlijke stortingen/opnames niet worden uitgevoerd; de bedrijfsrekening zelf blijft MySQL-gestuurd.
- Salarisbetalingen staan standaard aan maar zijn alleen een basisimplementatie: stel per medewerker `salary` in de tabel in. Test bankexports en payroll op een testserver voordat je dit live gebruikt.
- De meegeleverde versie is een basis voor bedrijfsbeheer, geen compleet gameplaypakket voor politie/ambulance/garage. Facturatie, kassa/POS, voertuigen, dispatch, uniforms en facturen zijn uitbreidingsmodules.
- De NUI gebruikt Google Fonts als externe fontbron; zonder internet valt deze terug op Inter/Arial.

## Beveiliging
Alle bedragen worden server-side gecontroleerd. Directie-acties worden op de server gecontroleerd aan de hand van de ingestelde boss-rangen. Gebruik alleen server-side exports voor het aanpassen van rekeningen. Test eerst met een back-up van je database.

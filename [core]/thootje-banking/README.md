# THOOTJE-BANKING 1.0.0

Premium bankieren voor FiveM, ontworpen voor THOOTJE-CORE. Met eigen rekeningnummers, blijvende banksaldi, transactiegeschiedenis en server-side overboekingen.

## Benodigdheden
- FiveM server met OneSync aanbevolen
- `oxmysql`
- `thootje-core`

## Installatie
1. Plaats de map `thootje-banking` in je resources.
2. Importeer `sql/thootje_banking.sql` in je database.
3. Controleer de core identifier-koppeling in `config.lua`.
4. Voeg aan `server.cfg` toe:
   ```
   ensure oxmysql
   ensure thootje-core
   ensure thootje-banking
   ```
5. Herstart de server.

## Gebruik
- `/bank` of F6: open de bankinterface.
- `/atm`: opent dezelfde interface; ATM-detectie/locatiebeperking kan via Config.RequireNearbyBank later worden uitgebreid.
- Overboekingen werken via unieke TH-rekeningnummers.
- Rekeningnaam aanpassen via de knop op het dashboard.

## THOOTJE-CORE identifier
De bank probeert de character identifier op te halen met:
`exports['thootje-core']:GetPlayerData(source)`

Hij zoekt standaard naar `citizenid`, `charid`, `characterId`, `identifier` of `id`.
Pas `Config.IdentifierFields` aan als jouw core een andere veldnaam gebruikt.

**Belangrijk voor multicharacter:** zorg dat de core-export de actieve character-data teruggeeft. Als de export niet werkt, valt de resource terug op `license:`. Dat betekent dan één rekening per FiveM-license in plaats van per character. Test dit bewust voordat je live gaat.

## Exports voor andere scripts
```lua
-- Server-side:
local balance = exports['thootje-banking']:GetBankBalance(source)

local ok = exports['thootje-banking']:AddBankMoney(source, 500, 'Salaris')
local ok = exports['thootje-banking']:RemoveBankMoney(source, 250, 'Aankoop')
```

- `GetBankBalance(source)` geeft het saldo als getal terug.
- `AddBankMoney(source, amount, reason)` boekt geld bij en registreert een transactie.
- `RemoveBankMoney(source, amount, reason)` schrijft af als er voldoende saldo is en registreert een transactie.

## Beveiliging en aandachtspunten
- Bedragen, rekeningnummers en saldo worden server-side gevalideerd.
- De saldoverplaatsing van een overboeking gebeurt met één atomische SQL-update; de transactiehistorie wordt daarna vastgelegd.
- Er is een transfer cooldown en rate limit.
- De client kan geen saldo of eigenaar meegeven.
- Geen cash/stortautomaat-koppeling in 1.0.0: dit pakket beheert banktegoeden en rekening-naar-rekening overboekingen. Koppel contant geld via je eigen core/inventory cash API voordat je stortingen en opnames toevoegt.
- De afstandscontrole voor bankfilialen/ATM's is voorbereid in config, maar niet actief in deze eerste versie.
- Test op een staging-server en controleer de exacte THOOTJE-CORE export met jouw huidige build.

## Tabellen
- `thootje_bank_accounts`
- `thootje_bank_transactions`

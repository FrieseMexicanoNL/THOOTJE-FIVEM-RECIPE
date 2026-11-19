# THOOTJE-BILLING 1.0.0

Facturen en betalingen voor THOOTJE-CORE.

## Inbegrepen
- Facturen aan online spelers versturen op basis van server-ID.
- Ontvangen en verzonden facturen bekijken.
- Factuur accepteren door te betalen of weigeren.
- Bankbetaling via configureerbare `thootje-banking` bridge.
- Uniek factuurnummer, omschrijving, bedrag, optionele toeslag en vervaldatum.
- MySQL-opslag en transactie-/statushistorie.
- Uitbetaling aan verzender, ook wanneer die offline is (uitbetalingswachtrij).
- Server-side controles: identiteit, ontvanger, afstand, bedrag, open status en vervaldatum.
- Configurabele limieten, betaalmethode, toetsenbord en meldingen.

## Vereisten
- `oxmysql`
- `thootje-core`
- `thootje-banking`
- THOOTJE-CORE moet `exports['thootje-core']:GetPlayerData(source)` beschikbaar stellen met `citizenid`, `charid`, `identifier` of `license`.
- `thootje-banking` moet de bankbridge exports leveren die hieronder staan.

## Installatie
1. Zet de map `thootje-billing` in je resources.
2. Importeer `sql/thootje_billing.sql`.
3. Controleer `shared/bridge.lua` en `config.lua` op jouw exacte core- en banking-API.
4. Zet in `server.cfg`:

```cfg
ensure oxmysql
ensure thootje-core
ensure thootje-banking
ensure thootje-billing

add_ace group.admin thootje.billing.admin allow
```

5. Start de server opnieuw.

## Gebruik
- `/billing` of F6 opent het facturatiemenu.
- Kies **Factuur maken**, vul het server-ID, bedrag en omschrijving in.
- De ontvanger moet standaard binnen 5 meter staan.
- De ontvanger ziet de factuur bij **Ontvangen** en kan betalen of weigeren.
- De verzender vindt zijn factuur terug bij **Verzonden**.

## Banking bridge: belangrijk
De resource gebruikt standaard deze exports in `thootje-banking`:
- `GetBankMoney(source)` -> huidig banksaldo als getal.
- `RemoveBankMoney(source, amount)` -> `true` bij geslaagde afschrijving.
- `AddBankMoney(source, amount)` -> `true` bij geslaagde bijschrijving.

De eerdere THOOTJE-BANKING build moet mogelijk uitgebreid worden met `GetBankMoney` en `RemoveBankMoney`, afhankelijk van de exports die jouw daadwerkelijke versie aanbiedt. Als de namen/signatures afwijken, pas `Config.Banking` en `shared/bridge.lua` aan. De resource weigert betaling wanneer de bankbridge niet correct reageert; er wordt geen eigen bankbalans aangemaakt.

## Belangrijke aandachtspunten
- Gebruik hetzelfde character identifier als in `thootje-core`, `thootje-banking` en andere THOOTJE-resources.
- `Config.PaymentMethod = 'bank'` is de ondersteunde betaalmethode. Cash mode is bewust niet geactiveerd; hiervoor is een veilige inventory-transactiebridge nodig.
- De huidige UI gebruikt server-ID om een factuur te adresseren. Alleen online ontvangers kunnen een nieuwe factuur krijgen.
- De verzender hoeft niet online te zijn wanneer de ontvanger betaalt. Het bedrag wordt dan in `thootje_billing_payouts` klaargezet en bij de volgende login uitbetaald.
- Test eerst met twee testpersonages op een stagingserver. Controleer met name bankexports en identifier-mapping.
- `thootje.admin` ACE staat los van `thootje.billing.admin`; admin-functies zijn in deze eerste versie nog niet als menu toegevoegd.


## Integratie voor andere resources (v1.1.0)
Server-side export voor vertrouwde resources:
```lua
local ok, invoiceId, invoiceNumber = exports['thootje-billing']:CreateInvoice(
    officerSource, recipientSource, 500, 'Politieboete: fout parkeren',
    { noFee = true, senderName = 'Politie - Naam agent', requireNearby = false }
)
```
Dit maakt een gewone factuur aan die in beide factuuroverzichten verschijnt en via de bestaande betaalflow kan worden voldaan. Alleen vanuit server-side resources aanroepen.

Bestaande databases: voer `sql/upgrade_1.1.0.sql` één keer uit om de kolom `no_payout` toe te voegen. Nieuwe databases krijgen deze kolom via `thootje_billing.sql`. De optie `noPayout = true` voorkomt dat een externe factuurbetaling als persoonlijk inkomen aan de verzender wordt uitgekeerd.

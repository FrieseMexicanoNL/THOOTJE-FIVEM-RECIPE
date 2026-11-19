# THOOTJE-HUD 1.0.0

Een moderne, configureerbare HUD voor FiveM, ontworpen voor THOOTJE-CORE.

## Functies
- HUD Studio openen met **F7** of `/hud`.
- Widgets aan/uit zetten: gezondheid, armor, honger, dorst, stamina, zuurstof, spraakstatus, straat, tijd, ID, baan, cash, bank en voertuig.
- Widgets verslepen naar een eigen positie.
- Accentkleuren, schaal, transparantie, hoekstijl en compacte modus.
- Instellingen lokaal opslaan via FiveM KVP.
- Voertuigpaneel met snelheid, brandstof en motorgezondheid.
- Nederlandse interface.

## Installatie
1. Zet de map `thootje-hud` in je resources-map.
2. Controleer `config.lua` en pas eventnamen aan als jouw THOOTJE-CORE andere namen gebruikt.
3. Zet in `server.cfg`:
   ```
   ensure thootje-core
   ensure thootje-hud
   ```
4. Start de server opnieuw.

## Honger en dorst koppelen
De HUD leest standaard `metadata.hunger` en `metadata.thirst` uit de playerdata. Als jouw needs-resource andere waarden gebruikt, stuur ze door:

```lua
TriggerEvent('thootje-hud:client:setNeeds', hunger, thirst)
```

Bijvoorbeeld na iedere wijziging van honger/dorst.

## Core-integratie
De resource probeert playerdata op te halen via:
- `exports['thootje-core']:GetCoreObject():Functions.GetPlayerData()`
- fallback: `exports['thootje-core']:GetPlayerData()`

Playerdata-events zijn instelbaar in `config.lua`:
- `Config.Core.PlayerLoadedEvent`
- `Config.Core.PlayerDataEvent`

Pas deze aan op de daadwerkelijke eventnamen van jouw THOOTJE-CORE. De HUD gebruikt geen ESX/QBCore als verplichte framework dependency.

## Bediening
- F7: HUD Studio openen/sluiten
- `/hud`: HUD Studio openen/sluiten
- Sleep widgets terwijl HUD Studio open is.
- Gebruik de tabbladen Widgets, Vormgeving en Handleiding.

## Belangrijk
- Dit is versie 1.0.0. De core-export en eventnamen moeten overeenkomen met jouw daadwerkelijke THOOTJE-CORE build.
- De HUD gebruikt standaard FiveM natives voor health, armor, stamina, zuurstof, straat, tijd en voertuigdata.
- Brandstof wordt uit `LegacyFuel` of `ox_fuel` gelezen als die resources gestart zijn; anders gebruikt de HUD de standaard GTA-brandstofwaarde.
- Seatbeltstatus is optioneel en wordt alleen getoond als jouw seatbelt-script `LocalPlayer.state.seatbelt` instelt.
- De Google Font wordt als externe font geladen; zonder internet gebruikt de HUD Inter/Arial fallback.

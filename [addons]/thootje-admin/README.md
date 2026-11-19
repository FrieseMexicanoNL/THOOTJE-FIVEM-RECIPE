# THOOTJE-ADMIN 1.0.0

Uitgebreid adminmenu voor FiveM. ACE-permissies beschermen het menu en serveracties. De resource gebruikt oxmysql voor permanente bans en werkt onafhankelijk van framework-player exports.

## Functies
- Modern donkerblauw/turquoise NUI adminpanel.
- Online spelers, ID, ping en globale coördinaten.
- Goto, bring, return, spectate.
- Freeze/unfreeze, heal, revive.
- Kick en warn met reden.
- Ban met duur of permanent; bans opgeslagen in MySQL en gecontroleerd bij verbinden.
- Unban via `/adminunban license:...`.
- Serveraankondigingen.
- Weer en tijd aanpassen.
- Lege voertuigen binnen ingestelde radius opruimen.
- Voertuig spawnen.
- Resource herstarten (superadmin).
- Actielog naar serverconsole.

## Installatie
1. Zet `thootje-admin` in je resources-map.
2. Importeer `sql/thootje_admin.sql`.
3. Voeg aan server.cfg toe:

```cfg
ensure oxmysql
ensure thootje-core
ensure thootje-admin

add_ace group.admin thootje.admin allow
add_ace group.admin thootje.admin.super allow
```

Voeg de juiste spelers toe aan `group.admin` via je bestaande ACE-principals. Gebruik `thootje.admin.super` alleen voor vertrouwde hoofdbeheerders.

## Gebruik
- `/admin` of F10: adminmenu openen.
- `/adminunban license:...`: ban verwijderen.
- `/adminannounce bericht`: aankondiging versturen.

## Belangrijke aandachtspunten
- Dit is een framework-onafhankelijk beheerfundament; het gebruikt nog geen THOOTJE-CORE-specifieke ban-, revive-, heal- of stafflog API.
- Revive is een generieke client-side GTA-resurrect. Als je server een death/ambulance resource gebruikt, koppel de revive-event in `client/main.lua` aan die resource.
- Weer/tijd worden client-side toegepast; voor een blijvende gesynchroniseerde wereldinstelling koppel je dit aan je weather/time-sync resource.
- Bancontrole gebruikt de FiveM `license:` identifier. Controleer dat spelers altijd een license identifier hebben.
- Gebruik resource restart alleen voor resources waarvan je de gevolgen kent. Test eerst op een stagingserver.
- De UI bevat knoppen voor unban via het servercommando; het unban-commando werkt via console of `/adminunban license:...`.

# THOOTJE RP - txAdmin Recipe 1.0.0

Deze bundel bevat **19 THOOTJE resources**, een txAdmin `recipe.yaml`, een gecombineerde SQL-installatie en installatiehandleiding.

## Meegeleverde resources

- `thootje-core`
- `thootje-multicharacter`
- `thootje-inventory`
- `thootje-banking`
- `thootje-jobs`
- `thootje-billing`
- `thootje-garage`
- `thootje-vehicles`
- `thootje-admin`
- `thootje-phone`
- `thootje-politiejob`
- `thootje-ambulancejob`
- `thootje-drugs`
- `thootje-pechhulpjob`
- `thootje-clothing`
- `thootje-housing`
- `thootje-hud`
- `thootje-shops`
- `thootje-society`

De recipe downloadt daarnaast:
- CFX default resources
- oxmysql
- ox_lib
- pma-voice

## Belangrijk: eerst GitHub instellen

txAdmin haalt een recipe op via een URL. De recipe kan niet rechtstreeks de bestanden uit deze ZIP op jouw pc lezen. Daarom moet je deze bundel eerst in een eigen GitHub-repository plaatsen.

1. Maak een **nieuwe private of public repository** aan met exact de naam `THOOTJE-FIVEM-RECIPE`.
2. Pak deze ZIP uit.
3. Upload de inhoud van de map `thootje-txadmin-recipe` naar de hoofdmap van die GitHub-repository. Zorg dat `recipe.yaml`, `resources/` en `sql/` direct in de root staan.
4. Open `recipe.yaml` en vervang beide voorkomens van `GITHUB_USERNAME` door jouw GitHub-gebruikersnaam.
5. Commit de bestanden naar de branch `main`.
6. Gebruik in txAdmin → Setup → Server Deployer → Remote URL Template deze URL:

   `https://raw.githubusercontent.com/JOUW_GITHUB_NAAM/THOOTJE-FIVEM-RECIPE/main/recipe.yaml`

Als je repository private is, kan txAdmin de bestanden niet zomaar downloaden. Gebruik voor deze deploymethode een public repository en zet geen wachtwoorden of server keys in GitHub. De server key en databasegegevens worden door txAdmin als deployervariabelen ingevuld.

## Installeren via txAdmin

1. Maak een nieuwe, lege serverdeployment aan. Gebruik dit niet over een bestaande live server heen.
2. Kies **Remote URL Template**.
3. Plak de raw recipe URL van hierboven.
4. Vul je Cfx.re license key en MySQL/MariaDB gegevens in.
5. Start de deployment.
6. Controleer na afloop de serverconsole op errors.

## Database

De recipe maakt verbinding met de door jou opgegeven database en voert `sql/install_all.sql` uit. Dit bestand bevat de installatietabellen van de meegeleverde resourceversies.

**Gebruik een lege database.** Maak vooraf een backup als je bestaande tabellen of data hebt. De recipe verwijdert geen bestaande database, maar SQL-installaties kunnen wel tabellen of kolommen aanmaken.

## Startvolgorde

De server.cfg start dependencies eerst, daarna core/character, economy, jobs, voertuigen, overheid, player systems en admin.

## Na deployment nog zelf configureren

- Voeg je eigen admin license toe in `server.cfg`.
- Controleer `Config`-bestanden van alle resources.
- Controleer of de exports van THOOTJE-CORE, THOOTJE-BANKING, THOOTJE-INVENTORY en THOOTJE-JOBS op elkaar aansluiten.
- Controleer banking/billing exports en job-/character identifiers.
- Pas politie-, EMS-, pechhulp-, kleding-, tattoo-, garage-, housing- en shoplocaties aan jouw server/map aan.
- Uniform drawable/texture IDs en tattoo hashes zijn voorbeelden en moeten op jouw kleding-/DLC-pakket worden afgestemd.
- Controleer voice-instellingen en de UDP voice-poort in je host/firewall.
- Test eerst met een testpersonage en testdatabase.

## Compatibiliteitsnotitie

Dit is een deployment recipe voor de gegenereerde THOOTJE resources. Het installeert ze en zet ze in een logische startvolgorde, maar garandeert niet dat iedere bridge/export zonder aanpassing op jouw exacte THOOTJE-CORE build aansluit. De resourceversies zijn niet allemaal samen op een echte FXServer instance geïntegreerd of runtime-getest. Test op een aparte server voordat je live gaat.

## Bestandsstructuur

```text
thootje-txadmin-recipe/
├── recipe.yaml
├── README.md
├── resources/
│   └── [thootje]/
│       ├── thootje-core/
│       ├── thootje-multicharacter/
│       └── ... overige THOOTJE resources
└── sql/
    └── install_all.sql
```

Jobs = {
    unemployed = {
        label = 'Werkloos', category = 'overig', public = true, defaultDuty = false,
        description = 'Je bent momenteel niet in dienst bij een werkgever.',
        grades = {
            [0] = { name = 'unemployed', label = 'Burger', salary = 0 }
        }
    },

    taxi = {
        label = 'Taxi Centrale', category = 'civiel', public = true, defaultDuty = false,
        description = 'Breng inwoners veilig en comfortabel naar hun bestemming.',
        grades = {
            [0] = { name = 'trainee', label = 'Aspirant Chauffeur', salary = 180 },
            [1] = { name = 'driver', label = 'Taxichauffeur', salary = 250 },
            [2] = { name = 'senior', label = 'Senior Chauffeur', salary = 325 },
            [3] = { name = 'dispatcher', label = 'Centralist', salary = 400 },
            [4] = { name = 'manager', label = 'Bedrijfsmanager', salary = 500, isBoss = true }
        }
    },

    mechanic = {
        label = 'Garagebedrijf', category = 'civiel', public = true, defaultDuty = false,
        description = 'Onderhoud voertuigen, repareer schade en help gestrande bestuurders.',
        grades = {
            [0] = { name = 'intern', label = 'Leerling Monteur', salary = 180 },
            [1] = { name = 'mechanic', label = 'Monteur', salary = 260 },
            [2] = { name = 'senior', label = 'Eerste Monteur', salary = 340 },
            [3] = { name = 'foreman', label = 'Werkplaatschef', salary = 430 },
            [4] = { name = 'manager', label = 'Garagemanager', salary = 525, isBoss = true }
        }
    },

    garbage = {
        label = 'Reinigingsdienst', category = 'civiel', public = true, defaultDuty = false,
        description = 'Houd de stad schoon en verzorg de afvalinzameling.',
        grades = {
            [0] = { name = 'trainee', label = 'Medewerker in opleiding', salary = 170 },
            [1] = { name = 'worker', label = 'Belader', salary = 230 },
            [2] = { name = 'driver', label = 'Chauffeur', salary = 300 },
            [3] = { name = 'supervisor', label = 'Uitvoerder', salary = 390 },
            [4] = { name = 'manager', label = 'Teamleider', salary = 480, isBoss = true }
        }
    },

    trucker = {
        label = 'Transportbedrijf', category = 'civiel', public = true, defaultDuty = false,
        description = 'Vervoer goederen en lever vracht veilig af.',
        grades = {
            [0] = { name = 'trainee', label = 'Bijrijder', salary = 180 },
            [1] = { name = 'driver', label = 'Vrachtwagenchauffeur', salary = 275 },
            [2] = { name = 'senior', label = 'Ervaren Chauffeur', salary = 360 },
            [3] = { name = 'planner', label = 'Transportplanner', salary = 450 },
            [4] = { name = 'manager', label = 'Transportmanager', salary = 550, isBoss = true }
        }
    },

    bus = {
        label = 'Openbaar Vervoer', category = 'civiel', public = true, defaultDuty = false,
        description = 'Vervoer reizigers volgens de dienstregeling.',
        grades = {
            [0] = { name = 'trainee', label = 'Buschauffeur in opleiding', salary = 175 },
            [1] = { name = 'driver', label = 'Buschauffeur', salary = 250 },
            [2] = { name = 'senior', label = 'Senior Chauffeur', salary = 330 },
            [3] = { name = 'planner', label = 'Planner', salary = 420 },
            [4] = { name = 'manager', label = 'OV Manager', salary = 510, isBoss = true }
        }
    },

    fisherman = {
        label = 'Visserij', category = 'civiel', public = true, defaultDuty = false,
        description = 'Vang vis en lever jouw vangst af bij de visafslag.',
        grades = {
            [0] = { name = 'deckhand', label = 'Dekhand', salary = 160 },
            [1] = { name = 'fisher', label = 'Visser', salary = 230 },
            [2] = { name = 'captain', label = 'Schipper', salary = 340 },
            [3] = { name = 'owner', label = 'Vlootbeheerder', salary = 450, isBoss = true }
        }
    },

    farmer = {
        label = 'Landbouwbedrijf', category = 'civiel', public = true, defaultDuty = false,
        description = 'Werk op het land en verzorg de oogst.',
        grades = {
            [0] = { name = 'seasonal', label = 'Seizoensmedewerker', salary = 160 },
            [1] = { name = 'farmhand', label = 'Landarbeider', salary = 230 },
            [2] = { name = 'specialist', label = 'Teeltspecialist', salary = 320 },
            [3] = { name = 'foreman', label = 'Voorman', salary = 410 },
            [4] = { name = 'owner', label = 'Bedrijfsleider', salary = 500, isBoss = true }
        }
    },

    police = {
        label = 'Politie', category = 'overheid', public = false, defaultDuty = false,
        description = 'Handhaaf de openbare orde en bescherm de inwoners.',
        grades = {
            [0] = { name = 'aspirant', label = 'Aspirant', salary = 350 },
            [1] = { name = 'agent', label = 'Agent', salary = 450 },
            [2] = { name = 'hoofdagent', label = 'Hoofdagent', salary = 525 },
            [3] = { name = 'brigadier', label = 'Brigadier', salary = 600 },
            [4] = { name = 'inspecteur', label = 'Inspecteur', salary = 700 },
            [5] = { name = 'commissaris', label = 'Commissaris', salary = 850, isBoss = true }
        }
    },

    ambulance = {
        label = 'Ambulancedienst', category = 'overheid', public = false, defaultDuty = false,
        description = 'Verleen medische hulp en vervoer patiënten.',
        grades = {
            [0] = { name = 'stagiair', label = 'Ambulancechauffeur in opleiding', salary = 330 },
            [1] = { name = 'chauffeur', label = 'Ambulancechauffeur', salary = 420 },
            [2] = { name = 'verpleegkundige', label = 'Ambulanceverpleegkundige', salary = 520 },
            [3] = { name = 'senior', label = 'Senior Verpleegkundige', salary = 625 },
            [4] = { name = 'arts', label = 'Trauma-arts', salary = 750 },
            [5] = { name = 'directeur', label = 'Ambulancecommandant', salary = 850, isBoss = true }
        }
    },

    fire = {
        label = 'Brandweer', category = 'overheid', public = false, defaultDuty = false,
        description = 'Bestrijd branden en voer reddingsacties uit.',
        grades = {
            [0] = { name = 'aspirant', label = 'Aspirant Brandwacht', salary = 330 },
            [1] = { name = 'brandwacht', label = 'Brandwacht', salary = 430 },
            [2] = { name = 'manschap', label = 'Manschap A', salary = 520 },
            [3] = { name = 'bevelvoerder', label = 'Bevelvoerder', salary = 640 },
            [4] = { name = 'officier', label = 'Officier van Dienst', salary = 760 },
            [5] = { name = 'commandant', label = 'Brandweercommandant', salary = 860, isBoss = true }
        }
    },

    government = {
        label = 'Gemeente', category = 'overheid', public = false, defaultDuty = false,
        description = 'Werk aan gemeentelijke dienstverlening en beleid.',
        grades = {
            [0] = { name = 'medewerker', label = 'Gemeentemedewerker', salary = 400 },
            [1] = { name = 'senior', label = 'Senior Medewerker', salary = 525 },
            [2] = { name = 'teamleider', label = 'Teamleider', salary = 650 },
            [3] = { name = 'wethouder', label = 'Wethouder', salary = 800 },
            [4] = { name = 'burgemeester', label = 'Burgemeester', salary = 950, isBoss = true }
        }
    },

    lawyer = {
        label = 'Rechtspraak', category = 'overheid', public = false, defaultDuty = false,
        description = 'Vertegenwoordiging, juridisch advies en rechtspleging.',
        grades = {
            [0] = { name = 'stagiair', label = 'Juridisch Stagiair', salary = 350 },
            [1] = { name = 'advocaat', label = 'Advocaat', salary = 500 },
            [2] = { name = 'senior', label = 'Senior Advocaat', salary = 650 },
            [3] = { name = 'officier', label = 'Officier van Justitie', salary = 775 },
            [4] = { name = 'rechter', label = 'Rechter', salary = 900, isBoss = true }
        }
    }
}

Societies = {
    police = {
        label = 'Politie', type = 'government', account = 'POLITIE-001',
        bossGrades = { [4] = true, [5] = true },
        grades = { [0]='Aspirant', [1]='Agent', [2]='Hoofdagent', [3]='Brigadier', [4]='Inspecteur', [5]='Commissaris' },
        locations = { { x=441.2, y=-981.9, z=30.7 } }
    },
    ambulance = {
        label = 'Ambulancedienst', type = 'government', account = 'AMB-001',
        bossGrades = { [4] = true, [5] = true },
        grades = { [0]='Stagiair', [1]='Ambulancechauffeur', [2]='Verpleegkundige', [3]='Senior verpleegkundige', [4]='Teamleider', [5]='Directeur' },
        locations = { { x=298.5, y=-584.3, z=43.3 } }
    },
    mechanic = {
        label = 'Garagebedrijf', type = 'business', account = 'GARAGE-001',
        bossGrades = { [3] = true, [4] = true },
        grades = { [0]='Leerling monteur', [1]='Monteur', [2]='Ervaren monteur', [3]='Bedrijfsleider', [4]='Eigenaar' },
        locations = { { x=-347.5, y=-133.4, z=39.0 } }
    },
    taxi = {
        label = 'Taxi Centrale', type = 'business', account = 'TAXI-001',
        bossGrades = { [3] = true, [4] = true },
        grades = { [0]='Chauffeur', [1]='Ervaren chauffeur', [2]='Senior chauffeur', [3]='Planner', [4]='Directeur' },
        locations = { { x=895.2, y=-179.1, z=74.7 } }
    },
    government = {
        label = 'Gemeente', type = 'government', account = 'GEM-001',
        bossGrades = { [3] = true, [4] = true },
        grades = { [0]='Medewerker', [1]='Senior medewerker', [2]='Coördinator', [3]='Wethouder', [4]='Burgemeester' },
        locations = { { x=-545.0, y=-204.0, z=38.2 } }
    }
}

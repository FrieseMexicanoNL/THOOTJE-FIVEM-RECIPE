Config = {}

Config.Debug = false
Config.MaxCharacters = 4
Config.DeleteCharacters = true
Config.RequireCorePatch = true

-- Character preview area. Use a quiet interior or custom MLO for best results.
Config.Preview = {
    coords = vector4(402.9, -996.8, -99.0, 180.0),
    camera = vector4(402.9, -1000.0, -98.2, 0.0),
    fov = 38.0
}

Config.Spawns = {
    {
        label = 'Legerziekenhuis',
        description = 'Start je avontuur in de stad.',
        coords = vector4(298.6, -584.4, 43.3, 70.0)
    },
    {
        label = 'Centrum',
        description = 'Begin midden in het centrum.',
        coords = vector4(215.8, -810.1, 30.7, 157.0)
    },
    {
        label = 'Haven',
        description = 'Begin bij de haven.',
        coords = vector4(-794.3, -1502.8, 1.6, 110.0)
    }
}

Config.Appearance = {
    enabled = false,
    resource = 'illenium-appearance'
}

Config.Text = {
    title = 'THOOTJE CITY',
    subtitle = 'Kies jouw verhaal',
    create = 'Nieuw personage',
    play = 'Deze persoon spelen',
    delete = 'Personage verwijderen',
    confirmDelete = 'Weet je zeker dat je dit personage wilt verwijderen?',
    noCharacters = 'Je hebt nog geen personages. Maak je eerste personage aan.'
}

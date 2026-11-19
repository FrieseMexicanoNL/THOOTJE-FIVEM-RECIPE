Config = {}

Config.CoreResource = 'thootje-core'
Config.Identifier = 'auto' -- auto probeert character ID uit THOOTJE-CORE, anders license:
Config.NotifyEvent = 'thootje-core:client:notify'

Config.OpenCommand = 'phone'
Config.OpenKey = 'F1'
Config.NumberPrefix = '06'
Config.NumberLength = 8 -- totaal nummer = prefix + 8 cijfers
Config.NumberRetryCount = 30
Config.MaxContacts = 100
Config.MaxSmsLength = 500
Config.MaxMessagesPerMinute = 8
Config.MaxCallSeconds = 60 * 60
Config.CallVoiceMode = 'pma-voice' -- pma-voice of none
Config.CallChannelBase = 7000

Config.Apps = {
    contacts = true,
    messages = true,
    phone = true,
    settings = true,
    notes = true
}

Config.DefaultWallpaper = 'aurora'
Config.Wallpapers = {
    aurora = 'Aurora',
    midnight = 'Midnight',
    ocean = 'Ocean',
    sunset = 'Sunset'
}

Config.Text = {
    no_phone = 'Je hebt geen telefoon bij je.',
    invalid_number = 'Dit telefoonnummer is ongeldig.',
    not_found = 'Dit telefoonnummer is niet in gebruik.',
    too_many_contacts = 'Je hebt het maximale aantal contacten bereikt.',
    message_too_long = 'Je bericht is te lang.',
    message_rate = 'Je verstuurt te snel berichten. Wacht even.',
    call_busy = 'Deze persoon is in gesprek.',
    call_no_answer = 'Deze persoon neemt niet op.',
    call_ended = 'Gesprek beëindigd.'
}

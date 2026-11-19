Config = {}
Config.Debug = false
Config.Command = 'billing'
Config.Key = 'F6'
Config.MaxInvoiceAmount = 1000000
Config.MaxDescriptionLength = 120
Config.MaxOpenInvoices = 30
Config.InvoiceExpiryDays = 14
Config.AllowSelfInvoice = false
Config.RequireNearbyRecipient = true
Config.NearbyDistance = 5.0
Config.PaymentMethod = 'bank' -- bank or cash
Config.CurrencySymbol = '$'
Config.AdminAce = 'thootje.billing.admin'
Config.InvoicePrefix = 'TH'
Config.InvoiceFeePercent = 0 -- optional fee added to total, e.g. 2.5
Config.NotifyEvent = 'thootje-core:client:notify'

-- Bank bridge: adapt these export names/signatures to your thootje-banking version.
-- Expected exports: GetBankMoney(source) -> number, RemoveBankMoney(source, amount) -> boolean,
-- AddBankMoney(source, amount) -> boolean. If your banking API differs, edit shared/bridge.lua.
Config.Banking = {
    resource = 'thootje-banking',
    getBalanceExport = 'GetBankMoney',
    removeExport = 'RemoveBankMoney',
    addExport = 'AddBankMoney'
}

Config.JobLabels = {
    police='Politie', ambulance='Ambulancedienst', mechanic='Garagebedrijf',
    taxi='Taxi Centrale', government='Gemeente', lawyer='Rechtspraak'
}
Config.Locale = {
    sent='Factuur succesvol verstuurd.',
    paid='Factuur betaald.',
    rejected='Factuur afgewezen.',
    notFound='Factuur niet gevonden.',
    notYours='Deze factuur is niet voor jou bestemd.',
    insufficient='Onvoldoende saldo op je rekening.',
    tooFar='De ontvanger is te ver weg.',
    invalid='Ongeldige factuurgegevens.',
    expired='Deze factuur is verlopen.',
    alreadyHandled='Deze factuur is al afgehandeld.'
}

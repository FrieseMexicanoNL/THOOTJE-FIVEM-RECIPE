Config = {}
Config.Debug = false
Config.JobName = 'police'
Config.JobLabel = 'Politie'
Config.OpenCommand = 'politie'
Config.MDTCommand = 'mdt'
Config.MDTKey = 'F6'
Config.RequireDuty = true
Config.NotifyEvent = 'thootje-core:client:notify'
Config.CuffDistance = 3.0
Config.EscortDistance = 4.0
Config.SearchDistance = 3.0
Config.FineMin = 1
Config.FineMax = 250000
Config.MaxFineReason = 120
Config.MaxConfiscateAmount = 1000
Config.MaxReportLength = 2000
Config.MaxReportTitle = 80
Config.JailMaxMinutes = 1440
Config.JailCoords = vector4(459.2, -994.8, 24.9, 90.0)
Config.ReleaseCoords = vector4(1847.1, 2585.9, 45.7, 270.0)
Config.JailTickSeconds = 60
Config.Permissions = {mdt=0,armory=0,vehicles=0,cuff=0,escort=0,search=1,fine=1,jail=2,reports=0,manage=7}
Config.Ranks = {[0]='Aspirant',[1]='Agent',[2]='Hoofdagent',[3]='Brigadier',[4]='Inspecteur',[5]='Hoofdinspecteur',[6]='Commissaris',[7]='Hoofdcommissaris',[8]='Korpschef'}
Config.Armory = {
 {label='Wapenstok',weapon='WEAPON_NIGHTSTICK'},
 {label='Taser',weapon='WEAPON_STUNGUN'},
 {label='Pistool',weapon='WEAPON_PISTOL'},
 {label='Zaklamp',weapon='WEAPON_FLASHLIGHT'}
}
Config.Vehicles = {
 {label='Politie Stanier',model='police',minGrade=0},
 {label='Politie Buffalo',model='police2',minGrade=1},
 {label='Politie SUV',model='police3',minGrade=2},
 {label='Politie Transporter',model='policet',minGrade=3},
 {label='Politie Interceptor',model='police4',minGrade=4},
 {label='Politie Bike',model='policeb',minGrade=2}
}
Config.Locations = {
 duty=vector3(441.2,-982.0,30.7),
 armory=vector3(452.6,-980.0,30.7),
 garage=vector3(454.6,-1017.4,28.4),
 boss=vector3(448.4,-973.2,30.7)
}
Config.Blips = {enabled=true,coords=vector3(425.1,-979.5,30.7),sprite=60,color=29,scale=0.8,label='Politiebureau'}
Config.Animations = {
 cuffDict='mp_arrest_paired',cuffAnim='cop_p2_back_right',
 cuffedDict='mp_arresting',cuffedAnim='idle',
 searchDict='anim@gangops@facility@servers@bodysearch@',searchAnim='player_search'
}
Config.Locale = {
 noJob='Je bent geen politieagent.',offDuty='Je moet in dienst zijn.',
 tooFar='Deze speler is te ver weg.',cuffed='Je bent geboeid.',
 uncuffed='Je bent ontboeid.',noTarget='Geen geldige speler gevonden.',
 notAllowed='Je hebt niet de juiste rang voor deze actie.',
 jailed='Je bent naar de gevangenis gebracht.',released='Je bent vrijgelaten.'
}

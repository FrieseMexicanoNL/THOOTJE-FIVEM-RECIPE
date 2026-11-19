-- IMPORTANT CORE INTEGRATION
-- thootje-core's current AddItem/RemoveItem functions read Config.Items from
-- thootje-core/config.lua. For compatibility, merge the following item keys
-- into the existing Config.Items table in thootje-core/config.lua.
-- Keep the definitions in sync with this resource's config.lua.

Config.Items = Config.Items or {}
Config.Items.water = { label = 'Flesje water', weight = 500, stack = true, usable = true }
Config.Items.bread = { label = 'Broodje', weight = 300, stack = true, usable = true }
Config.Items.sandwich = { label = 'Belegd broodje', weight = 450, stack = true, usable = true }
Config.Items.bandage = { label = 'Verband', weight = 200, stack = true, usable = true }
Config.Items.phone = { label = 'Smartphone', weight = 250, stack = false, usable = true }
Config.Items.radio = { label = 'Portofoon', weight = 800, stack = false, usable = true }
Config.Items.repairkit = { label = 'Reparatieset', weight = 2500, stack = true, usable = true }
Config.Items.money = { label = 'Contant geld', weight = 0, stack = true, usable = false }

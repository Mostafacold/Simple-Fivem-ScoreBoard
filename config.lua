Config = {}

-- Select your framework ("esx" or "qbcore")
Config.Framework = "esx"

Config.ServerName = "Space RP"
Config.MaxPlayers = 128

-- Jobs that will appear in the scoreboard stats and filters
Config.Jobs = {
    { name = 'ambulance', label = 'Medics', icon = '❤️', color = '#ef4444' },
    { name = 'police', label = 'LSPD', icon = '🛡️', color = '#3b82f6' },
    { name = 'mechanic', label = 'Mechanic', icon = '🔧', color = '#f59e0b' },
    { name = 'taxi', label = 'Taxi', icon = '🚕', color = '#facc15' },
    { name = 'unemployed', label = 'Citizen', icon = '🧍', color = '#9ca3af' }
}

-- Job color for players whose job isn't in the list above
Config.DefaultJobColor = '#a855f7'

-- Special roles with colors
Config.SpecialRoles = {
    admin = { color = "#8B0000", icon = "🛡️" },
    mod = { color = "#9B870C", icon = "👑" },
    founder = { color = "#0A2463", icon = "👑" }
}

-- VIP Commands
Config.VipaddCommand = "givevip"
Config.VipremoveCommand = "removevip"

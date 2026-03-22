local QBCore = nil
local ESX = nil

if Config.Framework == "qbcore" then
    QBCore = exports['qb-core']:GetCoreObject()
elseif Config.Framework == "esx" then
    ESX = exports['es_extended']:getSharedObject()
end

local AvatarCache = {}

AddEventHandler('playerDropped', function()
    local src = source
    if AvatarCache[src] then AvatarCache[src] = nil end
end)

function GetPlayersData()
    local players = {}
    local jobCount = {}
    
    for _, v in ipairs(Config.Jobs) do
        jobCount[v.name] = 0
    end

    local playersOnline = 0

    if Config.Framework == "esx" then
        local xPlayers = ESX.GetExtendedPlayers()
        playersOnline = #xPlayers

        for _, xPlayer in pairs(xPlayers) do
            local src = xPlayer.source
            local playerPing = GetPlayerPing(src)
            local playerGroup = xPlayer.getGroup()
            local jobName = xPlayer.job.name
            local jobLabel = xPlayer.job.label
            local jobGrade = xPlayer.job.grade_label
            local name = GetPlayerName(src)

            local playtime = 0
            if xPlayer.getPlayTime then playtime = xPlayer.getPlayTime() end
            local playtimeHours = math.floor(playtime / 3600)

            if jobCount[jobName] ~= nil then
                jobCount[jobName] = jobCount[jobName] + 1
            end

            local specialRole = nil
            local roleColor = nil
            local roleIcon = nil

            if Config.SpecialRoles[playerGroup] then
                specialRole = Config.SpecialRoles[playerGroup].label or playerGroup
                roleColor = Config.SpecialRoles[playerGroup].color
                roleIcon = Config.SpecialRoles[playerGroup].icon
            end

            if IsPlayerAceAllowed(src, "group.founder") and Config.SpecialRoles.founder then
                specialRole = Config.SpecialRoles.founder.label or 'Founder'
                roleColor = Config.SpecialRoles.founder.color
                roleIcon = Config.SpecialRoles.founder.icon
            end

            local license = GetPlayerIdentifierByType(src, 'license')
            local isVip = false
            if license and GetResourceKvpString("Sp_VIP_" .. license) == "true" then
                isVip = true
            end

            local avatar = AvatarCache[src]
            if not avatar then
                pcall(function()
                    avatar = exports.Badger_Discord_API:GetDiscordAvatar(src)
                    if avatar then AvatarCache[src] = avatar end
                end)
            end

            table.insert(players, {
                id = src, name = name, job = jobLabel, jobName = jobName,
                rank = specialRole or jobGrade, ping = playerPing,
                roleColor = roleColor, roleIcon = roleIcon,
                isSpecial = specialRole ~= nil, isVip = isVip,
                avatar = avatar, playtime = playtimeHours
            })
        end

    elseif Config.Framework == "qbcore" then
        local xPlayers = QBCore.Functions.GetQBPlayers()

        for _, xPlayer in pairs(xPlayers) do
            playersOnline = playersOnline + 1
            local src = xPlayer.PlayerData.source
            local playerPing = GetPlayerPing(src)
            
            local playerGroup = "user"
            pcall(function()
                local groups = QBCore.Functions.GetPermission(src)
                if type(groups) == "table" then
                    playerGroup = groups[1] or "user"
                elseif type(groups) == "string" then
                    playerGroup = groups
                end
            end)

            local jobName = xPlayer.PlayerData.job.name
            local jobLabel = xPlayer.PlayerData.job.label
            local jobGrade = xPlayer.PlayerData.job.grade.name
            local charinfo = xPlayer.PlayerData.charinfo
            local name = charinfo.firstname .. ' ' .. charinfo.lastname
            if not name or name == " " then name = GetPlayerName(src) end

            local playtimeHours = 0
            
            if jobCount[jobName] ~= nil then
                jobCount[jobName] = jobCount[jobName] + 1
            end

            local specialRole = nil
            local roleColor = nil
            local roleIcon = nil

            if Config.SpecialRoles[playerGroup] then
                specialRole = Config.SpecialRoles[playerGroup].label or playerGroup
                roleColor = Config.SpecialRoles[playerGroup].color
                roleIcon = Config.SpecialRoles[playerGroup].icon
            end

            if IsPlayerAceAllowed(src, "group.founder") and Config.SpecialRoles.founder then
                specialRole = Config.SpecialRoles.founder.label or 'Founder'
                roleColor = Config.SpecialRoles.founder.color
                roleIcon = Config.SpecialRoles.founder.icon
            end

            local license = GetPlayerIdentifierByType(src, 'license')
            local isVip = false
            if license and GetResourceKvpString("Sp_VIP_" .. license) == "true" then
                isVip = true
            end
            
            local avatar = AvatarCache[src]
            if not avatar then
                pcall(function()
                    avatar = exports.Badger_Discord_API:GetDiscordAvatar(src)
                    if avatar then AvatarCache[src] = avatar end
                end)
            end

            table.insert(players, {
                id = src, name = name, job = jobLabel, jobName = jobName,
                rank = specialRole or jobGrade, ping = playerPing,
                roleColor = roleColor, roleIcon = roleIcon,
                isSpecial = specialRole ~= nil, isVip = isVip,
                avatar = avatar, playtime = playtimeHours
            })
        end
    end

    if Config.UseDummyPlayers then
        for _, dummy in ipairs(Config.DummyPlayers) do
            playersOnline = playersOnline + 1
            if jobCount[dummy.jobName] ~= nil then
                jobCount[dummy.jobName] = jobCount[dummy.jobName] + 1
            end
            table.insert(players, dummy)
        end
    end

    return {
        serverName = Config.ServerName,
        playersOnline = playersOnline,
        maxPlayers = Config.MaxPlayers,
        jobCount = jobCount,
        players = players,
        jobsConfig = Config.Jobs,
        defaultJobColor = Config.DefaultJobColor
    }
end

RegisterNetEvent('esx_scoreboard:requestData')
AddEventHandler('esx_scoreboard:requestData', function()
    local _source = source
    local data = GetPlayersData()
    TriggerClientEvent('esx_scoreboard:updateData', _source, data)
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(2000)
        local data = GetPlayersData()
        TriggerClientEvent('esx_scoreboard:updateData', -1, data)
    end
end)

-- VIP Commands
RegisterCommand(Config.VipaddCommand, function(source, args, rawCommand)
    local src = source
    if src == 0 or IsPlayerAceAllowed(src, "group.admin") or IsPlayerAceAllowed(src, "group.founder") then
        local targetId = tonumber(args[1])
        if targetId and GetPlayerName(targetId) then
            local identifier = GetPlayerIdentifierByType(targetId, 'license')
            if identifier then
                SetResourceKvp("Sp_VIP_" .. identifier, "true")
                TriggerClientEvent('ox_lib:notify', targetId, { title = 'VIP System', description = 'You have been granted VIP status!', type = 'success' })
                if src > 0 then
                    TriggerClientEvent('ox_lib:notify', src, { title = 'System', description = 'Granted VIP to ID ' .. targetId, type = 'success' })
                else
                    print('Granted VIP to ID ' .. targetId)
                end
            end
        else
            if src > 0 then
                TriggerClientEvent('ox_lib:notify', src, { title = 'Error', description = 'Invalid Player ID.', type = 'error' })
            else
                print('Invalid Player ID.')
            end
        end
    else
        TriggerClientEvent('ox_lib:notify', src, { title = 'Error', description = 'You do not have permission to use this command.', type = 'error' })
    end
end, false)

RegisterCommand(Config.VipremoveCommand, function(source, args, rawCommand)
    local src = source
    if src == 0 or IsPlayerAceAllowed(src, "group.admin") or IsPlayerAceAllowed(src, "group.founder") then
        local targetId = tonumber(args[1])
        if targetId and GetPlayerName(targetId) then
            local identifier = GetPlayerIdentifierByType(targetId, 'license')
            if identifier then
                DeleteResourceKvp("Sp_VIP_" .. identifier)
                TriggerClientEvent('ox_lib:notify', targetId, { title = 'VIP System', description = 'Your VIP status has been removed.', type = 'error' })
                if src > 0 then
                    TriggerClientEvent('ox_lib:notify', src, { title = 'System', description = 'Removed VIP from ID ' .. targetId, type = 'success' })
                else
                    print('Removed VIP from ID ' .. targetId)
                end
            end
        else
            if src > 0 then
                TriggerClientEvent('ox_lib:notify', src, { title = 'Error', description = 'Invalid Player ID.', type = 'error' })
            else
                print('Invalid Player ID.')
            end
        end
    else
        TriggerClientEvent('ox_lib:notify', src, { title = 'Error', description = 'You do not have permission to use this command.', type = 'error' })
    end
end, false)



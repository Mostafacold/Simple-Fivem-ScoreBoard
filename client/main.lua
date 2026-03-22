local isScoreboardOpen = false

RegisterCommand('togglescoreboard', function()
    isScoreboardOpen = not isScoreboardOpen

    if isScoreboardOpen then
        TriggerServerEvent('esx_scoreboard:requestData')
        SetNuiFocus(true, true)
    else
        SendNUIMessage({action = 'hide'})
        SetNuiFocus(false, false)
    end
end, false)

RegisterKeyMapping('togglescoreboard', 'Toggle Scoreboard', 'keyboard', 'F10')

RegisterNetEvent('esx_scoreboard:updateData')
AddEventHandler('esx_scoreboard:updateData', function(data)
    if isScoreboardOpen then SendNUIMessage({action = 'show', data = data}) end
end)

RegisterNUICallback('closeScoreboard', function(data, cb)
    isScoreboardOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({action = 'hide'})
    cb('ok')
end)

ESX = exports["es_extended"]:getSharedObject()

RegisterServerEvent('as_gangbuilder:recruter')
AddEventHandler('as_gangbuilder:recruter', function(targetId, jobName)
    local xTarget = ESX.GetPlayerFromId(targetId)
    if xTarget then
        xTarget.setJob2(jobName, 1)
        TriggerClientEvent('esx:showNotification', targetId, "~b~Vous avez été recruté dans le gang : ~s~" .. jobName)
    end
end)

RegisterServerEvent('as_gangbuilder:virer')
AddEventHandler('as_gangbuilder:virer', function(targetId)
    local xTarget = ESX.GetPlayerFromId(targetId)
    if xTarget then
        xTarget.setJob2('unemployed', 0)
        TriggerClientEvent('esx:showNotification', targetId, "~r~Vous avez été viré de votre gang.")
    end
end)

RegisterServerEvent('as_gangbuilder:promouvoir')
AddEventHandler('as_gangbuilder:promouvoir', function(targetId)
    local xTarget = ESX.GetPlayerFromId(targetId)
    if xTarget then
        local currentGrade = xTarget.getJob2().grade
        local jobName = xTarget.getJob2().name

        exports.oxmysql:query("SELECT MAX(grade) as max FROM job_grades WHERE job_name = ?", { jobName }, function(result)
            if result and result[1] and tonumber(result[1].max) > currentGrade then
                xTarget.setJob2(jobName, currentGrade + 1)
                TriggerClientEvent('esx:showNotification', targetId, "~g~Vous avez été promu dans le gang")
            else
                TriggerClientEvent('esx:showNotification', source, "~r~Promotion impossible : grade max atteint.")
            end
        end)
    end
end)

RegisterServerEvent('as_gangbuilder:destituer')
AddEventHandler('as_gangbuilder:destituer', function(targetId)
    local xTarget = ESX.GetPlayerFromId(targetId)
    if xTarget then
        local currentGrade = xTarget.getJob2().grade
        local jobName = xTarget.getJob2().name

        if currentGrade <= 0 then
            TriggerClientEvent('esx:showNotification', source, "~r~Ce joueur est déjà au grade minimal.")
            return
        end

        xTarget.setJob2(jobName, currentGrade - 1)
        TriggerClientEvent('esx:showNotification', targetId, "~y~Vous avez été rétrogradé dans le gang")
    end
end)

ESX.RegisterServerCallback('as_gangbuilder:fouille', function(source, cb, targetId)
    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xTarget then return cb({}) end

    local data = {
        inventory = xTarget.getInventory(),
        money = xTarget.getMoney(),
        black_money = xTarget.getAccount('black_money').money,
        loadout = xTarget.getLoadout()
    }

    cb(data)
end)

-- Ligotage / Véhicule
RegisterServerEvent('as_gangbuilder:ligoter')
AddEventHandler('as_gangbuilder:ligoter', function(target)
    TriggerClientEvent('as_gangbuilder:client:ligoter', target)
end)

RegisterServerEvent('as_gangbuilder:deligoter')
AddEventHandler('as_gangbuilder:deligoter', function(target)
    TriggerClientEvent('as_gangbuilder:client:deligoter', target)
end)
local ligotterPlayers = {} 

ESX.RegisterServerCallback('as_gangbuilder:checkLigotage', function(_, cb, target)
    cb(ligotterPlayers[target] == true)
end)

ESX.RegisterServerCallback('as_gangbuilder:isInVehicle', function(_, cb, target)
    local xTarget = ESX.GetPlayerFromId(target)
    if xTarget then
        TriggerClientEvent('as_gangbuilder:checkInVehicleClient', xTarget.source, function(isInVeh)
            cb(isInVeh)
        end)
    else
        cb(false)
    end
end)

RegisterServerEvent('as_gangbuilder:mettreVehicule')
AddEventHandler('as_gangbuilder:mettreVehicule', function(target, vehNetId, seat)
    TriggerClientEvent('as_gangbuilder:client:mettreVehicule', target, vehNetId, seat)
end)

RegisterServerEvent('as_gangbuilder:sortirVehicule')
AddEventHandler('as_gangbuilder:sortirVehicule', function(target)
    TriggerClientEvent('as_gangbuilder:client:sortirVehicule', target)
end)


-- handlers/client/astrxwf7_handlers.lua

RegisterNetEvent('as_gangbuilder:gang:ligotter')
AddEventHandler('as_gangbuilder:gang:ligotter', function()
    local playerPed = PlayerPedId()
    RequestAnimDict('mp_arresting')
    while not HasAnimDictLoaded('mp_arresting') do Wait(0) end
    TaskPlayAnim(playerPed, 'mp_arresting', 'idle', 8.0, -8, -1, 49, 0, false, false, false)
    SetEnableHandcuffs(playerPed, true)
    DisablePlayerFiring(playerPed, true)
    SetCurrentPedWeapon(playerPed, `WEAPON_UNARMED`, true)
    FreezeEntityPosition(playerPed, true)
end)

RegisterNetEvent('as_gangbuilder:gang:deligotter')
AddEventHandler('as_gangbuilder:gang:deligotter', function()
    local playerPed = PlayerPedId()
    ClearPedTasks(playerPed)
    SetEnableHandcuffs(playerPed, false)
    DisablePlayerFiring(playerPed, false)
    FreezeEntityPosition(playerPed, false)
end)

RegisterNetEvent('as_gangbuilder:gang:putInVehicle')
AddEventHandler('as_gangbuilder:gang:putInVehicle', function(netVeh, seat)
    local playerPed = PlayerPedId()
    local vehicle = NetToVeh(netVeh)
    if DoesEntityExist(vehicle) then
        TaskWarpPedIntoVehicle(playerPed, vehicle, seat)
    end
end)

RegisterNetEvent('as_gangbuilder:gang:outVehicle')
AddEventHandler('as_gangbuilder:gang:outVehicle', function()
    local playerPed = PlayerPedId()
    if IsPedInAnyVehicle(playerPed, false) then
        TaskLeaveVehicle(playerPed, GetVehiclePedIsIn(playerPed, false), 16)
    end
end)

ESX = exports['es_extended']:getSharedObject()

function GetPlayerJob2Data()
    local playerData = ESX.GetPlayerData()

    if playerData and playerData.job2 and playerData.job2.name then
        return {
            name = playerData.job2.name,
            grade = playerData.job2.grade,
            grade_name = playerData.job2.grade_name,
            label = playerData.job2.label
        }
    end

    return nil
end

function IsPlayerGangBoss()
    local job2 = GetPlayerJob2Data()
    return job2 ~= nil and job2.name ~= Config.UnemployedJob and job2.grade_name == Config.BossGradeName
end

function KeyboardInput(entryTitle, textEntry, maxLength)
    AddTextEntry('FMMC_KEY_TIP1', entryTitle)
    DisplayOnscreenKeyboard(1, 'FMMC_KEY_TIP1', '', textEntry or '', '', '', '', maxLength)

    while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do
        Wait(0)
    end

    if UpdateOnscreenKeyboard() ~= 2 then
        return GetOnscreenKeyboardResult()
    end

    return nil
end

function GetFreeSeat(vehicle)
    if not DoesEntityExist(vehicle) then return nil end

    local maxSeats = GetVehicleMaxNumberOfPassengers(vehicle)

    for seat = 0, maxSeats - 1 do
        if IsVehicleSeatFree(vehicle, seat) then
            return seat
        end
    end

    return nil
end

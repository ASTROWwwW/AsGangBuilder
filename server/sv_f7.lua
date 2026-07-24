local tiedPlayers = {}

local function getBossContext(src, targetId)
    local xPlayer, job2 = GetPlayerJob2(src)

    if not xPlayer or not job2 or job2.name == Config.UnemployedJob or job2.grade_name ~= Config.BossGradeName then
        Notify(src, '~r~Accès refusé.')
        return nil
    end

    if not IsPlayerNear(src, targetId, Config.PlayerInteractDistance) then
        Notify(src, '~r~Aucun joueur à proximité.')
        return nil
    end

    local xTarget = ESX.GetPlayerFromId(tonumber(targetId))
    if not xTarget then return nil end

    return xPlayer, job2, xTarget
end

local function getMemberContext(src, targetId)
    local xPlayer, job2 = GetPlayerJob2(src)

    if not xPlayer or not job2 or job2.name == Config.UnemployedJob then
        Notify(src, '~r~Accès refusé.')
        return nil
    end

    if not IsPlayerNear(src, targetId, Config.PlayerInteractDistance) then
        Notify(src, '~r~Aucun joueur à proximité.')
        return nil
    end

    local xTarget = ESX.GetPlayerFromId(tonumber(targetId))
    if not xTarget then return nil end

    return xPlayer, job2, xTarget
end

RegisterNetEvent('as_gangbuilder:recruter', function(targetId)
    local src = source
    local _, job2, xTarget = getBossContext(src, targetId)
    if not job2 then return end

    if xTarget.job2 and xTarget.job2.name ~= Config.UnemployedJob then
        Notify(src, '~r~Ce joueur appartient déjà à un gang.')
        return
    end

    GetGangGradeBounds(job2.name, function(minGrade)
        if not minGrade then
            Notify(src, '~r~Aucun grade défini pour ce gang.')
            return
        end

        xTarget.setJob2(job2.name, minGrade)
        Notify(xTarget.source, '~b~Vous avez été recruté dans le gang : ~s~' .. job2.name)
        Notify(src, '~g~Joueur recruté.')
    end)
end)

RegisterNetEvent('as_gangbuilder:virer', function(targetId)
    local src = source
    local _, job2, xTarget = getBossContext(src, targetId)
    if not job2 then return end

    if not xTarget.job2 or xTarget.job2.name ~= job2.name then
        Notify(src, '~r~Ce joueur ne fait pas partie de votre gang.')
        return
    end

    if xTarget.job2.grade_name == Config.BossGradeName then
        Notify(src, '~r~Vous ne pouvez pas virer un boss.')
        return
    end

    xTarget.setJob2(Config.UnemployedJob, 0)
    Notify(xTarget.source, '~r~Vous avez été viré de votre gang.')
    Notify(src, '~g~Joueur viré du gang.')
end)

RegisterNetEvent('as_gangbuilder:promouvoir', function(targetId)
    local src = source
    local _, job2, xTarget = getBossContext(src, targetId)
    if not job2 then return end

    if not xTarget.job2 or xTarget.job2.name ~= job2.name then
        Notify(src, '~r~Ce joueur ne fait pas partie de votre gang.')
        return
    end

    local currentGrade = tonumber(xTarget.job2.grade) or 0

    GetGangGradeBounds(job2.name, function(_, maxGrade)
        if not maxGrade then return end

        local newGrade = currentGrade + 1
        if newGrade >= maxGrade then
            Notify(src, '~r~Promotion impossible : rang boss atteint.')
            return
        end

        exports.oxmysql:scalar('SELECT COUNT(*) FROM job_grades WHERE job_name = ? AND grade = ?', { job2.name, newGrade }, function(exists)
            if (exists or 0) == 0 then
                Notify(src, '~r~Ce grade n\'existe pas dans le gang.')
                return
            end

            xTarget.setJob2(job2.name, newGrade)
            Notify(xTarget.source, '~g~Vous avez été promu dans le gang.')
            Notify(src, '~g~Joueur promu.')
        end)
    end)
end)

RegisterNetEvent('as_gangbuilder:destituer', function(targetId)
    local src = source
    local _, job2, xTarget = getBossContext(src, targetId)
    if not job2 then return end

    if not xTarget.job2 or xTarget.job2.name ~= job2.name then
        Notify(src, '~r~Ce joueur ne fait pas partie de votre gang.')
        return
    end

    if xTarget.job2.grade_name == Config.BossGradeName then
        Notify(src, '~r~Vous ne pouvez pas rétrograder un boss.')
        return
    end

    local currentGrade = tonumber(xTarget.job2.grade) or 0

    GetGangGradeBounds(job2.name, function(minGrade)
        if not minGrade then return end

        local newGrade = currentGrade - 1
        if newGrade < minGrade then
            Notify(src, '~r~Ce joueur est déjà au grade minimal.')
            return
        end

        exports.oxmysql:scalar('SELECT COUNT(*) FROM job_grades WHERE job_name = ? AND grade = ?', { job2.name, newGrade }, function(exists)
            if (exists or 0) == 0 then
                Notify(src, '~r~Ce grade n\'existe pas dans le gang.')
                return
            end

            xTarget.setJob2(job2.name, newGrade)
            Notify(xTarget.source, '~y~Vous avez été rétrogradé dans le gang.')
            Notify(src, '~y~Joueur rétrogradé.')
        end)
    end)
end)

ESX.RegisterServerCallback('as_gangbuilder:fouille', function(source, cb, targetId)
    local _, _, xTarget = getMemberContext(source, targetId)
    if not xTarget then return cb(nil) end

    cb({
        inventory = xTarget.getInventory(),
        money = xTarget.getMoney(),
        black_money = xTarget.getAccount('black_money').money,
        loadout = xTarget.getLoadout()
    })
end)

RegisterNetEvent('as_gangbuilder:toggleLigotage', function(targetId)
    local src = source
    local _, _, xTarget = getMemberContext(src, targetId)
    if not xTarget then return end

    local target = xTarget.source

    if tiedPlayers[target] then
        tiedPlayers[target] = nil
        TriggerClientEvent('as_gangbuilder:client:deligoter', target)
        Notify(src, '~g~Le joueur a été détaché.')
    else
        tiedPlayers[target] = true
        TriggerClientEvent('as_gangbuilder:client:ligoter', target)
        Notify(src, '~o~Le joueur a été ligoté.')
    end
end)

RegisterNetEvent('as_gangbuilder:toggleVehicule', function(targetId, vehNetId, seat)
    local src = source
    local _, _, xTarget = getMemberContext(src, targetId)
    if not xTarget then return end

    local target = xTarget.source
    local targetPed = GetPlayerPed(target)
    if targetPed == 0 then return end

    if GetVehiclePedIsIn(targetPed) ~= 0 then
        TriggerClientEvent('as_gangbuilder:client:sortirVehicule', target)
        Notify(src, '~g~Joueur sorti du véhicule.')
        return
    end

    local netId = tonumber(vehNetId)
    local seatIndex = tonumber(seat)
    if not netId or not seatIndex then
        Notify(src, '~r~Aucun véhicule ou siège disponible.')
        return
    end

    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if vehicle == 0 or not DoesEntityExist(vehicle) then
        Notify(src, '~r~Aucun véhicule proche.')
        return
    end

    if #(GetEntityCoords(targetPed) - GetEntityCoords(vehicle)) > Config.VehicleInteractDistance then
        Notify(src, '~r~Le véhicule est trop loin.')
        return
    end

    TriggerClientEvent('as_gangbuilder:client:mettreVehicule', target, netId, math.floor(seatIndex))
    Notify(src, '~g~Joueur placé dans le véhicule.')
end)

AddEventHandler('playerDropped', function()
    tiedPlayers[source] = nil
end)

local f7Menu = RageUI.CreateMenu('Menu Gang', 'Actions disponibles')
local fouilleMenu = RageUI.CreateSubMenu(f7Menu, 'Fouille', 'Inventaire & Armes')
local fouilleData = nil
local menuThreadRunning = false

local function getClosestTarget()
    local player, distance = ESX.Game.GetClosestPlayer()

    if not player or player == -1 or not distance or distance > Config.PlayerInteractDistance then
        ESX.ShowNotification('~r~Aucun joueur à proximité')
        return nil
    end

    return GetPlayerServerId(player)
end

local function runMenuThread()
    if menuThreadRunning then return end
    menuThreadRunning = true

    CreateThread(function()
        while RageUI.Visible(f7Menu) or RageUI.Visible(fouilleMenu) do
            Wait(1)

            RageUI.IsVisible(f7Menu, function()
                local job2 = GetPlayerJob2Data()
                if not job2 then return end

                RageUI.Separator('Gang : ~p~' .. job2.name .. ' ~s~ - Grade : ~p~' .. tostring(job2.grade_name))
                RageUI.Line()

                RageUI.Button('Fouiller', nil, {}, true, {
                    onSelected = function()
                        local target = getClosestTarget()
                        if not target then return end

                        ESX.TriggerServerCallback('as_gangbuilder:fouille', function(data)
                            if not data then
                                ESX.ShowNotification('~r~Fouille impossible')
                                return
                            end

                            fouilleData = data
                            RageUI.Visible(fouilleMenu, true)
                        end, target)
                    end
                })

                RageUI.Button('Ligotter / Détacher', nil, {}, true, {
                    onSelected = function()
                        local target = getClosestTarget()
                        if target then
                            TriggerServerEvent('as_gangbuilder:toggleLigotage', target)
                        end
                    end
                })

                RageUI.Button('Mettre / Sortir du véhicule', nil, {}, true, {
                    onSelected = function()
                        local target = getClosestTarget()
                        if not target then return end

                        local vehicle, distance = ESX.Game.GetClosestVehicle()

                        if not vehicle or vehicle == 0 or not distance or distance > Config.VehicleInteractDistance then
                            TriggerServerEvent('as_gangbuilder:toggleVehicule', target)
                            return
                        end

                        local seat = GetFreeSeat(vehicle)
                        TriggerServerEvent('as_gangbuilder:toggleVehicule', target, VehToNet(vehicle), seat)
                    end
                })

                if IsPlayerGangBoss() then
                    RageUI.Line()
                    RageUI.Separator('~b~Gestion de membres')

                    RageUI.Button('Recruter', nil, {}, true, {
                        onSelected = function()
                            local target = getClosestTarget()
                            if target then
                                TriggerServerEvent('as_gangbuilder:recruter', target)
                            end
                        end
                    })

                    RageUI.Button('Virer', nil, {}, true, {
                        onSelected = function()
                            local target = getClosestTarget()
                            if target then
                                TriggerServerEvent('as_gangbuilder:virer', target)
                            end
                        end
                    })

                    RageUI.Button('Promouvoir', nil, {}, true, {
                        onSelected = function()
                            local target = getClosestTarget()
                            if target then
                                TriggerServerEvent('as_gangbuilder:promouvoir', target)
                            end
                        end
                    })

                    RageUI.Button('Destituer', nil, {}, true, {
                        onSelected = function()
                            local target = getClosestTarget()
                            if target then
                                TriggerServerEvent('as_gangbuilder:destituer', target)
                            end
                        end
                    })
                end
            end)

            RageUI.IsVisible(fouilleMenu, function()
                if not fouilleData then return end

                RageUI.Separator(('Argent liquide : ~g~%s$~s~'):format(fouilleData.money or 0))
                RageUI.Separator(('Argent sale : ~r~%s$~s~'):format(fouilleData.black_money or 0))
                RageUI.Line()

                for _, item in pairs(fouilleData.inventory or {}) do
                    if (item.count or 0) > 0 then
                        RageUI.Button(item.label, nil, { RightLabel = 'x' .. item.count }, true)
                    end
                end

                for _, weapon in pairs(fouilleData.loadout or {}) do
                    RageUI.Button(weapon.label, nil, {}, true)
                end
            end)
        end

        fouilleData = nil
        menuThreadRunning = false
    end)
end

RegisterCommand('F7_GROUP', function()
    local job2 = GetPlayerJob2Data()

    if not job2 or job2.name == Config.UnemployedJob then return end

    RageUI.Visible(f7Menu, not RageUI.Visible(f7Menu))
    runMenuThread()
end, false)

RegisterKeyMapping('F7_GROUP', 'Menu intéraction illégale', 'keyboard', 'F7')

RegisterNetEvent('as_gangbuilder:client:ligoter', function()
    local playerPed = PlayerPedId()

    RequestAnimDict('mp_arresting')
    while not HasAnimDictLoaded('mp_arresting') do
        Wait(0)
    end

    TaskPlayAnim(playerPed, 'mp_arresting', 'idle', 8.0, -8.0, -1, 49, 0, false, false, false)
    SetEnableHandcuffs(playerPed, true)
    DisablePlayerFiring(playerPed, true)
    SetCurrentPedWeapon(playerPed, `WEAPON_UNARMED`, true)
    FreezeEntityPosition(playerPed, true)
end)

RegisterNetEvent('as_gangbuilder:client:deligoter', function()
    local playerPed = PlayerPedId()

    ClearPedTasks(playerPed)
    SetEnableHandcuffs(playerPed, false)
    DisablePlayerFiring(playerPed, false)
    FreezeEntityPosition(playerPed, false)
end)

RegisterNetEvent('as_gangbuilder:client:mettreVehicule', function(netId, seat)
    local vehicle = NetToVeh(netId)

    if DoesEntityExist(vehicle) then
        TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, seat)
    end
end)

RegisterNetEvent('as_gangbuilder:client:sortirVehicule', function()
    local playerPed = PlayerPedId()

    if IsPedInAnyVehicle(playerPed, false) then
        TaskLeaveVehicle(playerPed, GetVehiclePedIsIn(playerPed, false), 16)
    end
end)

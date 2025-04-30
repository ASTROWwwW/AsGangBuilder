function astrxwF7()
    local main = RageUI.CreateMenu('Menu Gang', 'Actions disponibles')
    local playerFouille = RageUI.CreateSubMenu(main, 'Fouille', 'Inventaire & Armes')

    RageUI.Visible(main, not RageUI.Visible(main))

    

    while main do Wait(1)
        RageUI.IsVisible(main, function()
            RageUI.Separator('Gang : ~p~' .. ESX.PlayerData.job2.name .. ' ~s~ - Grade : ~p~' .. ESX.PlayerData.job2.grade_name)
            RageUI.Line()
            RageUI.Button('Fouiller', nil, {}, true, {
                onSelected = function()
                    local player, distance = ESX.Game.GetClosestPlayer()
                    if player ~= -1 and distance <= 3.0 then
                        ESX.TriggerServerCallback('as_gangbuilder:fouille', function(data)
                            Gangs.gangs.Fouille = data
                            RageUI.Visible(playerFouille, true)
                        end, GetPlayerServerId(player))
                    else
                        ESX.ShowNotification('~r~Aucun joueur à proximité')
                    end
                end
            })

            RageUI.Button('Ligotter / Détacher', nil, {}, true, {
                onSelected = function()
                    local player, distance = ESX.Game.GetClosestPlayer()
                    if player ~= -1 and distance <= 3.0 then
                        local target = GetPlayerServerId(player)
                        ESX.TriggerServerCallback('as_gangbuilder:checkLigotage', function(isLigote)
                            if isLigote then
                                TriggerServerEvent('as_gangbuilder:deligoter', target)
                                ESX.ShowNotification('~g~Le joueur a été détaché')
                            else
                                TriggerServerEvent('as_gangbuilder:ligoter', target)
                                ESX.ShowNotification('~o~Le joueur a été ligoté')
                            end
                        end, target)
                    else
                        ESX.ShowNotification('~r~Aucun joueur à proximité')
                    end
                end
            })

            RageUI.Button('Mettre / Sortir du véhicule', nil, {}, true, {
                onSelected = function()
                    local player, distance = ESX.Game.GetClosestPlayer()
                    if player ~= -1 and distance <= 3.0 then
                        local target = GetPlayerServerId(player)
                        ESX.TriggerServerCallback('as_gangbuilder:isInVehicle', function(isInVeh)
                            local veh, dist = ESX.Game.GetClosestVehicle()
                            if veh and dist <= 5.0 then
                                if isInVeh then
                                    TriggerServerEvent('as_gangbuilder:sortirVehicule', target)
                                    ESX.ShowNotification('~g~Joueur sorti du véhicule')
                                else
                                    local seat = GetFreeVehicleSeat(veh)
                                    if seat ~= -2 then
                                        TriggerServerEvent('as_gangbuilder:mettreVehicule', target, VehToNet(veh), seat)
                                        ESX.ShowNotification('~g~Joueur placé dans le véhicule')
                                    else
                                        ESX.ShowNotification('~r~Aucun siège disponible')
                                    end
                                end
                            else
                                ESX.ShowNotification('~r~Aucun véhicule proche')
                            end
                        end, target)
                    else
                        ESX.ShowNotification('~r~Aucun joueur à proximité')
                    end
                end
            })

            RageUI.Line()

            if ESX.PlayerData.job2 and ESX.PlayerData.job2.grade_name == "boss" then
                RageUI.Separator("~b~Gestion de membres")

                RageUI.Button("Recruter", nil, {}, true, {
                    onSelected = function()
                        local player, dist = ESX.Game.GetClosestPlayer()
                        if player ~= -1 and dist <= 3.0 then
                            TriggerServerEvent('as_gangbuilder:recruter', GetPlayerServerId(player), ESX.PlayerData.job2.name)
                        else
                            ESX.ShowNotification("~r~Aucun joueur à proximité")
                        end
                    end
                })

                RageUI.Button("Virer", nil, {}, true, {
                    onSelected = function()
                        local player, dist = ESX.Game.GetClosestPlayer()
                        if player ~= -1 and dist <= 3.0 then
                            TriggerServerEvent('as_gangbuilder:virer', GetPlayerServerId(player))
                        else
                            ESX.ShowNotification("~r~Aucun joueur à proximité")
                        end
                    end
                })

                RageUI.Button("Promouvoir", nil, {}, true, {
                    onSelected = function()
                        local player, dist = ESX.Game.GetClosestPlayer()
                        if player ~= -1 and dist <= 3.0 then
                            TriggerServerEvent('as_gangbuilder:promouvoir', GetPlayerServerId(player))
                        else
                            ESX.ShowNotification("~r~Aucun joueur à proximité")
                        end
                    end
                })

                RageUI.Button("Destituer", nil, {}, true, {
                    onSelected = function()
                        local player, dist = ESX.Game.GetClosestPlayer()
                        if player ~= -1 and dist <= 3.0 then
                            TriggerServerEvent('as_gangbuilder:destituer', GetPlayerServerId(player))
                        else
                            ESX.ShowNotification("~r~Aucun joueur à proximité")
                        end
                    end
                })
            end
        end)

        RageUI.IsVisible(playerFouille, function()
            RageUI.Separator(('Argent liquide : ~g~%s$~s~'):format(Gangs.gangs.Fouille.money))
            RageUI.Separator(('Argent sale : ~r~%s$~s~'):format(Gangs.gangs.Fouille.black_money))
            RageUI.Line()

            for _, item in pairs(Gangs.gangs.Fouille.inventory) do
                RageUI.Button(item.label, nil, {RightLabel = "x"..item.count}, true)
            end

            for _, weap in pairs(Gangs.gangs.Fouille.loadout) do
                RageUI.Button(weap.label, nil, {}, true)
            end
        end)

        if not RageUI.Visible(main) and not RageUI.Visible(playerFouille) then
            main = RMenu:DeleteType('main')
            break
        end
    end
end
RegisterCommand('F7_GROUP', function()
    if ESX.PlayerData.job2.name == 'unemployed' then return end

   astrxwF7()
end)

RegisterKeyMapping('F7_GROUP', 'Menu intéraction illégale', 'keyboard', 'F7')

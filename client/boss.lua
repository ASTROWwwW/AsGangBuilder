ESX = exports["es_extended"]:getSharedObject()

local loadedGangs = {}
local playerJob2 = nil
local playerLoaded = false
local gangMoney, gangBlackMoney = 0, 0

-- Chargement des gangs au lancement
CreateThread(function()
    while ESX.GetPlayerData().job2 == nil do Wait(100) end
    playerLoaded = true
    playerJob2 = ESX.GetPlayerData().job2
    TriggerServerEvent("as_gangbuilder:getGangsForClient")
end)

RegisterNetEvent('esx:setJob2', function(job)
    playerJob2 = job
end)

RegisterNetEvent("as_gangbuilder:sendGangsToClient", function(gangs)
    loadedGangs = gangs
end)

RegisterNetEvent("as_gangbuilder:requestRefresh", function()
    if playerLoaded then
        TriggerServerEvent("as_gangbuilder:getGangsForClient")
    end
end)

RegisterNetEvent("as_gangbuilder:receiveGangMoney", function(amount)
    gangMoney = amount or 0
end)

RegisterNetEvent("as_gangbuilder:receiveGangBlackMoney", function(amount)
    gangBlackMoney = amount or 0
end)


function GetPlayerJob2Data()
    local playerData = ESX.GetPlayerData()
    if playerData and playerData.job2 then
        return {
            name = playerData.job2.name,
            grade = playerData.job2.grade,
            grade_name = playerData.job2.grade_name,
            label = playerData.job2.label
        }
    end
    return nil
end

CreateThread(function()
    while true do
        local sleep = 500

        if playerLoaded then
            local job2 = GetPlayerJob2Data()

            for _, gang in pairs(loadedGangs) do
                if job2 and job2.name == gang.name and job2.grade_name == "boss" then
                    local pos = json.decode(gang.pos_boss)
                    if pos then
                        local playerCoords = GetEntityCoords(PlayerPedId())
                        local dist = #(playerCoords - vector3(pos.x, pos.y, pos.z))

                        if dist < 10.0 then
                            sleep = 1

                            DrawMarker(
                                tonumber(gang.marker_type) or 1,
                                pos.x, pos.y, pos.z - 0.95,
                                0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                                1.0, 1.0, 1.0,
                                tonumber(gang.marker_color_r) or 255,
                                tonumber(gang.marker_color_g) or 0,
                                tonumber(gang.marker_color_b) or 0,
                                180, false, true, 2, nil, nil, false
                            )

                            if dist < 2.0 then
                                ESX.ShowHelpNotification("~INPUT_CONTEXT~ Interagir avec le point boss")
                                if IsControlJustPressed(0, 38) then
                                    OpenBossMenu(gang.name)
                                end
                            end
                        end
                    end
                end
            end
        end

        Wait(sleep)
    end
end)




-- Menu Boss avec gestion membres + argent
function OpenBossMenu(gangName)
    local main = RageUI.CreateMenu("Menu Boss", "Actions Disponibles")
    local members = RageUI.CreateSubMenu(main, "Membres", "Liste des membres")
    local memberActions = RageUI.CreateSubMenu(members, "Action", "Gérer le membre")
    local moneyMenu = RageUI.CreateSubMenu(main, "Argent", "Fonds du gang")
    local membersData, selectedMember = {}, nil

    RageUI.Visible(main, true)
    FreezeEntityPosition(PlayerPedId(), true)

    CreateThread(function()
        while RageUI.Visible(main) or RageUI.Visible(members) or RageUI.Visible(memberActions) or RageUI.Visible(moneyMenu) do
            Wait(1)

            RageUI.IsVisible(main, function()
                RageUI.Separator('Gang : ~p~' .. ESX.PlayerData.job2.name .. ' ~s~ - Grade : ~p~' .. ESX.PlayerData.job2.grade_name)
                RageUI.Button("Gérer les membres", nil, {}, true, {
                    onSelected = function()
                        ESX.TriggerServerCallback('as_gangbuilder:boss:getAllMembers', function(m)
                            membersData = m or {}
                        end, gangName)
                        RageUI.Visible(members, true)
                    end
                })
                RageUI.Button("Gérer l'argent du gang", nil, {}, true, {
                    onSelected = function()
                        ESX.TriggerServerCallback("as_gangbuilder:getGangMoney", function(money)
                            gangMoney = money
                        end, gangName)
                        ESX.TriggerServerCallback("as_gangbuilder:getGangBlackMoney", function(black)
                            gangBlackMoney = black
                        end, gangName)
                        RageUI.Visible(moneyMenu, true)
                    end
                })
            end)

            RageUI.IsVisible(members, function()
                local maxGrade = 0
                for _, m in pairs(membersData) do maxGrade = math.max(maxGrade, m.job2_grade) end

                for _, m in pairs(membersData) do
                    local isBoss = m.job2_grade == maxGrade
                    RageUI.Button(('%s %s | ID: %s | Grade: ~b~%s~s~%s'):format(
                        m.firstname, m.lastname, m.UniqueID, m.gradeLabel, isBoss and ' ~r~(Boss)' or ''), nil,
                        {RightLabel = isBoss and '🔒' or '>>'}, not isBoss, {
                            onSelected = function()
                                selectedMember = m
                            end
                        }, memberActions)
                end
            end)

            RageUI.IsVisible(memberActions, function()
                RageUI.Button("Virer", nil, {}, true, {
                    onSelected = function()
                        TriggerServerEvent('as_gangbuilder:boss:fireMember', selectedMember.identifier)
                    end
                })
                RageUI.Button("Promouvoir", nil, {}, true, {
                    onSelected = function()
                        TriggerServerEvent('as_gangbuilder:boss:promoteMember', selectedMember.identifier, selectedMember.job2_grade)
                    end
                })
                RageUI.Button("Rétrograder", nil, {}, true, {
                    onSelected = function()
                        TriggerServerEvent('as_gangbuilder:boss:demoteMember', selectedMember.identifier, selectedMember.job2_grade)
                    end
                })
            end)

            RageUI.IsVisible(moneyMenu, function()
                RageUI.Separator("Argent propre : ~g~" .. gangMoney .. "$")
                RageUI.Separator("Argent sale : ~r~" .. gangBlackMoney .. "$")

                RageUI.Button("Déposer de l'argent ~g~ propre", nil, {}, true, {
                    onSelected = function()
                        local amount = KeyboardInput("Montant à déposer", "", 10)
                        if amount then
                            TriggerServerEvent("as_gangbuilder:depositGangMoney", gangName, tonumber(amount))
                            Wait(250)
                            ESX.TriggerServerCallback("as_gangbuilder:getGangMoney", function(m) gangMoney = m end, gangName)
                        end
                    end
                })

                RageUI.Button("Retirer de l'argent ~g~ propre", nil, {}, true, {
                    onSelected = function()
                        local amount = KeyboardInput("Montant à retirer", "", 10)
                        if amount then
                            TriggerServerEvent("as_gangbuilder:withdrawGangMoney", gangName, tonumber(amount))
                            Wait(250)
                            ESX.TriggerServerCallback("as_gangbuilder:getGangMoney", function(m) gangMoney = m end, gangName)
                        end
                    end
                })
                RageUI.Line()
                RageUI.Button("Déposer de l'argent ~r~sale", nil, {}, true, {
                    onSelected = function()
                        local amount = KeyboardInput("Montant à déposer (black_money)", "", 10)
                        if amount then
                            TriggerServerEvent("as_gangbuilder:depositGangBlackMoney", gangName, tonumber(amount))
                            Wait(250)
                            ESX.TriggerServerCallback("as_gangbuilder:getGangBlackMoney", function(m) gangBlackMoney = m end, gangName)
                        end
                    end
                })

                RageUI.Button("Retirer de l'argent ~r~ sale", nil, {}, true, {
                    onSelected = function()
                        local amount = KeyboardInput("Montant à retirer (black_money)", "", 10)
                        if amount then
                            TriggerServerEvent("as_gangbuilder:withdrawGangBlackMoney", gangName, tonumber(amount))
                            Wait(250)
                            ESX.TriggerServerCallback("as_gangbuilder:getGangBlackMoney", function(m) gangBlackMoney = m end, gangName)
                        end
                    end
                })
            end)
        end
        FreezeEntityPosition(PlayerPedId(), false)
    end)
end
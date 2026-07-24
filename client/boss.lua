local bossPoints = {}
local playerLoaded = false
local gangMoney, gangBlackMoney = 0, 0
local membersData, selectedMember = {}, nil
local currentGang = nil

local bossMenu = RageUI.CreateMenu('Menu Boss', 'Actions Disponibles')
local membersMenu = RageUI.CreateSubMenu(bossMenu, 'Membres', 'Liste des membres')
local memberActionsMenu = RageUI.CreateSubMenu(membersMenu, 'Action', 'Gérer le membre')
local moneyMenu = RageUI.CreateSubMenu(bossMenu, 'Argent', 'Fonds du gang')

CreateThread(function()
    while ESX.GetPlayerData().job2 == nil do
        Wait(250)
    end

    playerLoaded = true
    TriggerServerEvent('as_gangbuilder:getGangsForClient')
end)

RegisterNetEvent('esx:setJob2', function()
    if playerLoaded then
        TriggerServerEvent('as_gangbuilder:getGangsForClient')
    end
end)

RegisterNetEvent('as_gangbuilder:requestRefresh', function()
    if playerLoaded then
        TriggerServerEvent('as_gangbuilder:getGangsForClient')
    end
end)

RegisterNetEvent('as_gangbuilder:sendGangsToClient', function(gangs)
    bossPoints = {}

    for _, gang in ipairs(gangs or {}) do
        if gang.pos_boss then
            local pos = json.decode(gang.pos_boss)

            if pos and pos.x and pos.y and pos.z then
                bossPoints[#bossPoints + 1] = {
                    name = gang.name,
                    coords = vector3(pos.x + 0.0, pos.y + 0.0, pos.z + 0.0),
                    markerType = tonumber(gang.marker_type) or 1,
                    markerSize = tonumber(gang.marker_size) or 1.0,
                    r = tonumber(gang.marker_color_r) or 255,
                    g = tonumber(gang.marker_color_g) or 0,
                    b = tonumber(gang.marker_color_b) or 0
                }
            end
        end
    end
end)

local function goBack(child, parent)
    RageUI.Visible(child, false)
    RageUI.Visible(parent, true)
end

local function refreshFunds()
    ESX.TriggerServerCallback('as_gangbuilder:getGangMoney', function(money)
        gangMoney = money or 0
    end, currentGang)

    ESX.TriggerServerCallback('as_gangbuilder:getGangBlackMoney', function(money)
        gangBlackMoney = money or 0
    end, currentGang)
end

local function transferFunds(event, title)
    local amount = tonumber(KeyboardInput(title, '', 10))

    if not amount or amount <= 0 then
        ESX.ShowNotification('~r~Montant invalide.')
        return
    end

    TriggerServerEvent(event, currentGang, math.floor(amount))
    Wait(250)
    refreshFunds()
end

function OpenBossMenu(gangName)
    currentGang = gangName
    membersData, selectedMember = {}, nil

    RageUI.Visible(bossMenu, true)
    FreezeEntityPosition(PlayerPedId(), true)

    CreateThread(function()
        while RageUI.Visible(bossMenu) or RageUI.Visible(membersMenu) or RageUI.Visible(memberActionsMenu) or RageUI.Visible(moneyMenu) do
            Wait(1)

            RageUI.IsVisible(bossMenu, function()
                local job2 = GetPlayerJob2Data()
                if job2 then
                    RageUI.Separator('Gang : ~p~' .. job2.name .. ' ~s~ - Grade : ~p~' .. tostring(job2.grade_name))
                end

                RageUI.Button('Gérer les membres', nil, {}, true, {
                    onSelected = function()
                        ESX.TriggerServerCallback('as_gangbuilder:boss:getAllMembers', function(members)
                            membersData = members or {}
                        end, currentGang)
                        RageUI.Visible(membersMenu, true)
                    end
                })

                RageUI.Button('Gérer l\'argent du gang', nil, {}, true, {
                    onSelected = function()
                        refreshFunds()
                        RageUI.Visible(moneyMenu, true)
                    end
                })
            end)

            RageUI.IsVisible(membersMenu, function()
                local maxGrade = 0
                for _, member in ipairs(membersData) do
                    maxGrade = math.max(maxGrade, member.job2_grade)
                end

                for _, member in ipairs(membersData) do
                    local isBoss = member.job2_grade == maxGrade

                    RageUI.Button(('%s %s | ID: %s | Grade: ~b~%s~s~%s'):format(
                        member.firstname, member.lastname, member.UniqueID, member.gradeLabel,
                        isBoss and ' ~r~(Boss)' or ''
                    ), nil, { RightLabel = isBoss and '🔒' or '>>' }, not isBoss, {
                        onSelected = function()
                            selectedMember = member
                        end
                    }, memberActionsMenu)
                end
            end)

            RageUI.IsVisible(memberActionsMenu, function()
                if not selectedMember then return end

                RageUI.Button('Virer', nil, {}, true, {
                    onSelected = function()
                        TriggerServerEvent('as_gangbuilder:boss:fireMember', selectedMember.identifier)
                        goBack(memberActionsMenu, membersMenu)
                    end
                })

                RageUI.Button('Promouvoir', nil, {}, true, {
                    onSelected = function()
                        TriggerServerEvent('as_gangbuilder:boss:promoteMember', selectedMember.identifier)
                        goBack(memberActionsMenu, membersMenu)
                    end
                })

                RageUI.Button('Rétrograder', nil, {}, true, {
                    onSelected = function()
                        TriggerServerEvent('as_gangbuilder:boss:demoteMember', selectedMember.identifier)
                        goBack(memberActionsMenu, membersMenu)
                    end
                })
            end)

            RageUI.IsVisible(moneyMenu, function()
                RageUI.Separator('Argent propre : ~g~' .. gangMoney .. '$')
                RageUI.Separator('Argent sale : ~r~' .. gangBlackMoney .. '$')

                RageUI.Button('Déposer de l\'argent ~g~propre', nil, {}, true, {
                    onSelected = function()
                        transferFunds('as_gangbuilder:depositGangMoney', 'Montant à déposer')
                    end
                })

                RageUI.Button('Retirer de l\'argent ~g~propre', nil, {}, true, {
                    onSelected = function()
                        transferFunds('as_gangbuilder:withdrawGangMoney', 'Montant à retirer')
                    end
                })

                RageUI.Line()

                RageUI.Button('Déposer de l\'argent ~r~sale', nil, {}, true, {
                    onSelected = function()
                        transferFunds('as_gangbuilder:depositGangBlackMoney', 'Montant à déposer (black_money)')
                    end
                })

                RageUI.Button('Retirer de l\'argent ~r~sale', nil, {}, true, {
                    onSelected = function()
                        transferFunds('as_gangbuilder:withdrawGangBlackMoney', 'Montant à retirer (black_money)')
                    end
                })
            end)
        end

        FreezeEntityPosition(PlayerPedId(), false)
        currentGang = nil
    end)
end

CreateThread(function()
    while true do
        local sleep = 500

        if playerLoaded and IsPlayerGangBoss() then
            local job2 = GetPlayerJob2Data()
            local playerCoords = GetEntityCoords(PlayerPedId())

            for _, point in ipairs(bossPoints) do
                if job2.name == point.name then
                    local dist = #(playerCoords - point.coords)

                    if dist < Config.MarkerDrawDistance then
                        sleep = 1

                        DrawMarker(
                            point.markerType,
                            point.coords.x, point.coords.y, point.coords.z - 0.95,
                            0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                            point.markerSize, point.markerSize, point.markerSize,
                            point.r, point.g, point.b,
                            180, false, true, 2, nil, nil, false
                        )

                        if dist < Config.BossInteractDistance then
                            ESX.ShowHelpNotification('~INPUT_CONTEXT~ Interagir avec le point boss')

                            if IsControlJustReleased(0, 38) then
                                OpenBossMenu(point.name)
                            end
                        end
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

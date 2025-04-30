ESX = exports["es_extended"]:getSharedObject()

local gangCoffres = {}

RegisterNetEvent("as_gangbuilder:sendCoffres")
AddEventHandler("as_gangbuilder:sendCoffres", function(gangs)
    gangCoffres = {}

    for _, gang in ipairs(gangs) do
        if gang.pos_coffre then
            local pos = json.decode(gang.pos_coffre)
            table.insert(gangCoffres, {
                name = gang.name,
                label = gang.label,
                coords = vector3(pos.x, pos.y, pos.z),
                markerType = tonumber(gang.marker_type) or 1,
                color = {
                    r = tonumber(gang.marker_color_r) or 255,
                    g = tonumber(gang.marker_color_g) or 0,
                    b = tonumber(gang.marker_color_b) or 0
                }
            })
        end
    end
end)

CreateThread(function()
    while true do
        local sleep = 500
        local playerCoords = GetEntityCoords(PlayerPedId())
        local job2 = GetPlayerJob2Data()

        for _, coffre in ipairs(gangCoffres) do
            if job2 and job2.name == coffre.name then
                local dist = #(playerCoords - coffre.coords)

                if dist < 10.0 then
                    sleep = 1
                    DrawMarker(
                        coffre.markerType,
                        coffre.coords.x, coffre.coords.y, coffre.coords.z - 0.95,
                        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                        1.0, 1.0, 1.0,
                        coffre.color.r, coffre.color.g, coffre.color.b,
                        180, false, true, 2, nil, nil, false
                    )
                end

                if dist < 1.5 then
                    sleep = 1
                    ESX.ShowHelpNotification("~INPUT_CONTEXT~ Ouvrir le coffre de gang")
                    if IsControlJustReleased(0, 38) then
                        TriggerServerEvent("as_gangbuilder:openGangStash", coffre.name)
                    end
                end
            end
        end

        Wait(sleep)
    end
end)


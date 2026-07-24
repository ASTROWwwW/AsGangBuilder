local gangCoffres = {}

RegisterNetEvent('as_gangbuilder:sendCoffres', function(gangs)
    gangCoffres = {}

    for _, gang in ipairs(gangs or {}) do
        if gang.pos_coffre then
            local pos = json.decode(gang.pos_coffre)

            if pos and pos.x and pos.y and pos.z then
                gangCoffres[#gangCoffres + 1] = {
                    name = gang.name,
                    label = gang.label,
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

CreateThread(function()
    while true do
        local sleep = 500

        if #gangCoffres > 0 then
            local job2 = GetPlayerJob2Data()

            if job2 then
                local playerCoords = GetEntityCoords(PlayerPedId())

                for _, coffre in ipairs(gangCoffres) do
                    if job2.name == coffre.name then
                        local dist = #(playerCoords - coffre.coords)

                        if dist < Config.MarkerDrawDistance then
                            sleep = 1

                            DrawMarker(
                                coffre.markerType,
                                coffre.coords.x, coffre.coords.y, coffre.coords.z - 0.95,
                                0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                                coffre.markerSize, coffre.markerSize, coffre.markerSize,
                                coffre.r, coffre.g, coffre.b,
                                180, false, true, 2, nil, nil, false
                            )

                            if dist < Config.CoffreInteractDistance then
                                ESX.ShowHelpNotification('~INPUT_CONTEXT~ Ouvrir le coffre de gang')

                                if IsControlJustReleased(0, 38) then
                                    TriggerServerEvent('as_gangbuilder:openGangStash', coffre.name)
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

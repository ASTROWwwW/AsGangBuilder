local ox_inventory = exports.ox_inventory

function RegisterGangStashes()
    exports.oxmysql:execute("SELECT * FROM gangs", {}, function(gangs)
        for _, gang in ipairs(gangs) do
            if gang.name and gang.label and gang.pos_coffre then
                local pos = json.decode(gang.pos_coffre)
                if pos and pos.x and pos.y and pos.z then
                    local stashId = "gangstash_" .. gang.name

                    -- Enregistrement basique du stash sans restriction job (job2 non géré nativement)
                    ox_inventory:RegisterStash(
                        stashId,
                        "Coffre de gang - " .. gang.label,
                        40,
                        100000
                    )

                    print(('[AsGangs] Coffre "%s" enregistré à %.2f %.2f %.2f'):format(stashId, pos.x, pos.y, pos.z))
                end
            end
        end
    end)
end

RegisterNetEvent("as_gangbuilder:getGangsForClient")
AddEventHandler("as_gangbuilder:getGangsForClient", function()
    local src = source
    exports.oxmysql:execute("SELECT * FROM gangs", {}, function(result)
        TriggerClientEvent("as_gangbuilder:sendCoffres", src, result)
    end)
end)


RegisterServerEvent("as_gangbuilder:openGangStash")
AddEventHandler("as_gangbuilder:openGangStash", function(gangName)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    if xPlayer.job2 and xPlayer.job2.name == gangName then
        local stashId = "gangstash_" .. gangName
        exports.ox_inventory:forceOpenInventory(source, 'stash', stashId)
    else
        print(("[AsGangs] Refus d'ouverture du coffre pour %s (job2=%s)"):format(xPlayer.identifier, xPlayer.job2 and xPlayer.job2.name or "nil"))
        DropPlayer(src, "Tentative d'accès à un coffre de gang non autorisé.")
    end
end)

AddEventHandler("onResourceStart", function(resource)
    if resource == GetCurrentResourceName() then
        Wait(1000)
        RegisterGangStashes()
    end
end)
local gangStashes = {}

function RegisterGangStashes()
    exports.oxmysql:query('SELECT name, label, pos_coffre FROM gangs', {}, function(gangs)
        gangStashes = {}

        for _, gang in ipairs(gangs or {}) do
            if gang.name and gang.label and gang.pos_coffre then
                local pos = json.decode(gang.pos_coffre)

                if pos and pos.x and pos.y and pos.z then
                    local coords = vector3(pos.x + 0.0, pos.y + 0.0, pos.z + 0.0)
                    local stashId = 'gangstash_' .. gang.name

                    gangStashes[gang.name] = coords

                    exports.ox_inventory:RegisterStash(
                        stashId,
                        'Coffre de gang - ' .. gang.label,
                        Config.StashSlots,
                        Config.StashWeight,
                        false,
                        nil,
                        coords
                    )

                    DebugLog(('Coffre "%s" enregistré à %.2f %.2f %.2f'):format(stashId, coords.x, coords.y, coords.z))
                end
            end
        end
    end)
end

RegisterNetEvent('as_gangbuilder:openGangStash', function(gangName)
    local src = source

    if not IsGangMember(src, gangName) then
        Notify(src, '~r~Vous n\'avez pas accès à ce coffre.')
        DebugLog(('Refus d\'ouverture du coffre "%s" pour l\'ID %d.'):format(tostring(gangName), src))
        return
    end

    local coords = gangStashes[gangName]
    if not coords then
        Notify(src, '~r~Coffre introuvable.')
        return
    end

    local ped = GetPlayerPed(src)
    if ped == 0 or #(GetEntityCoords(ped) - coords) > Config.PlayerInteractDistance then
        Notify(src, '~r~Vous êtes trop loin du coffre.')
        return
    end

    exports.ox_inventory:forceOpenInventory(src, 'stash', 'gangstash_' .. gangName)
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        Wait(1000)
        RegisterGangStashes()
    end
end)

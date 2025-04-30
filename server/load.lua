RegisterNetEvent("as_gangbuilder:getGangsForClient", function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    if not xPlayer or not xPlayer.job2 then
        print(("[as_gangbuilder] Le joueur %s n'a pas de job2."):format(GetPlayerName(src)))
        return
    end

    local job2Name = xPlayer.job2.name
    local job2Grade = xPlayer.job2.grade_name

    -- Requête 1 : Récupération des infos des gangs
    exports.oxmysql:query("SELECT * FROM gangs", {}, function(gangs)
        if not gangs or #gangs == 0 then
            print("[as_gangbuilder] Aucun gang trouvé dans la base.")
            return
        end

        -- Requête 2 : Comptage des grades par job
        exports.oxmysql:query("SELECT job_name, COUNT(*) as count FROM job_grades GROUP BY job_name", {}, function(gradeCounts)
            local gradeMap = {}
            for _, g in pairs(gradeCounts) do
                gradeMap[g.job_name] = g.count
            end

            -- Log des gangs
            for _, gang in ipairs(gangs) do
                local gradeCount = gradeMap[gang.name] or 0
                print(("\27[34m[AsGangs]\27[0m Gang \27[33m'%s'\27[0m chargé avec \27[32m%d\27[0m grade%s."):format(
                    gang.name, gradeCount, gradeCount > 1 and "s" or ""))
                
            end
            if job2Grade == "boss" then
                for _, gang in ipairs(gangs) do
                    if gang.name == job2Name then
                      
                        TriggerClientEvent("as_gangbuilder:sendGangsToClient", src, { gang })
                        return
                    end
                end
              
            else
                
            end
        end)
    end)
end)

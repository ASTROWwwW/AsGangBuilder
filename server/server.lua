RegisterServerEvent("as_gangbuilder:createGang")
AddEventHandler("as_gangbuilder:createGang", function(data)
    local src = source
    local posCoffre = json.encode({x = data.posCoffre.x, y = data.posCoffre.y, z = data.posCoffre.z})
    local posBoss = json.encode({x = data.posBoss.x, y = data.posBoss.y, z = data.posBoss.z})

    -- Flag pour vérifier la fin des opérations
    local operationsCompleted = {
        gang = false,
        job = false,
        grades = false
    }

    local  function checkAllCompleted()
            if operationsCompleted.gang and operationsCompleted.job and operationsCompleted.grades then
                print("[GANG BUILDER] Gang '" .. data.name .. "' enregistré avec succès.")
                TriggerClientEvent("esx:showNotification", src, "~g~Gang '" .. data.label .. "' enregistré avec succès.")
                TriggerEvent('esx_society:registerSociety', data.name, data.label, 'society_' .. data.name, 'society', 'society', {})

                RegisterGangStashes()
                TriggerClientEvent("as_gangbuilder:requestRefresh", -1)
                print('loaded')
            end
        end

    -- GANG
    exports.oxmysql:scalar("SELECT COUNT(*) FROM gangs WHERE name = ?", { data.name }, function(gangExists)
        if gangExists > 0 then
            exports.oxmysql:update([[
                UPDATE gangs 
                SET label = ?, pos_coffre = ?, pos_boss = ?, marker_type = ?, marker_size = ?, marker_color_r = ?, marker_color_g = ?, marker_color_b = ?
                WHERE name = ?
            ]], {
                data.label,
                posCoffre,
                posBoss,
                tonumber(data.markerType),
                tonumber(data.markerSize),
                data.markerColor.r,
                data.markerColor.g,
                data.markerColor.b,
                data.name
            }, function()
                operationsCompleted.gang = true
                checkAllCompleted()
            end)
        else
            exports.oxmysql:insert([[
                INSERT INTO gangs (name, label, pos_coffre, pos_boss, marker_type, marker_size, marker_color_r, marker_color_g, marker_color_b)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            ]], {
                data.name, data.label,
                posCoffre,
                posBoss,
                tonumber(data.markerType),
                tonumber(data.markerSize),
                data.markerColor.r,
                data.markerColor.g,
                data.markerColor.b
            }, function()
                operationsCompleted.gang = true
                checkAllCompleted()
            end)
        end
    end)

    -- JOB
    exports.oxmysql:scalar("SELECT COUNT(*) FROM jobs WHERE name = ?", { data.name }, function(jobExists)
        if jobExists > 0 then
            exports.oxmysql:update("UPDATE jobs SET label = ? WHERE name = ?", {
                data.label, data.name
            }, function()
                operationsCompleted.job = true
                checkAllCompleted()
            end)
        else
            exports.oxmysql:insert([[
                INSERT INTO jobs (name, label, whitelisted, SecondaryJob)
                VALUES (?, ?, 0, 1)
            ]], {
                data.name,
                data.label
            }, function()
                operationsCompleted.job = true
                checkAllCompleted()
            end)
        end
    end)

    
    exports.oxmysql:execute("DELETE FROM job_grades WHERE job_name = ?", { data.name }, function()
        local total = #data.grades
        local inserted = 0

        if total == 0 then
            operationsCompleted.grades = true
            checkAllCompleted()
        end

        for _, grade in ipairs(data.grades) do
            exports.oxmysql:insert([[
                INSERT INTO job_grades (job_name, grade, name, label, salary, skin_male, skin_female)
                VALUES (?, ?, ?, ?, 0, ?, ?)
            ]], {
                data.name,
                tonumber(grade.grade),
                grade.name,
                grade.label,
                "{}", "{}"
            }, function()
                inserted = inserted + 1
                if inserted == total then
                    operationsCompleted.grades = true
                    checkAllCompleted()
                end
            end)
        end
       
       
        


    end)
end)

RegisterNetEvent("as_gangbuilder:deleteGang", function(gangName)
    local src = source
    if not gangName or gangName == "" then return end

    exports.oxmysql:transaction({
        {
            query = 'DELETE FROM jobs WHERE name = ?',
            values = { gangName }
        },
        {
            query = 'DELETE FROM job_grades WHERE job_name = ?',
            values = { gangName }
        },
        {
            query = 'DELETE FROM gangs WHERE name = ?',
            values = { gangName }
        }
    }, function(success)
        if success then
            TriggerClientEvent('esx:showNotification', src, 'Le gang a bien été supprimé.')
            RegisterGangStashes()
            TriggerClientEvent("as_gangbuilder:requestRefresh", -1)
            print(("^1[AsGangs]^0 Gang supprimé : ^3%s^0 par joueur ID ^2%d^0"):format(gangName, src))
        else
            TriggerClientEvent('esx:showNotification', src, '~r~Erreur lors de la suppression.')
        end
    end)
end)





RegisterServerEvent("as_gangbuilder:getAllGangs")
AddEventHandler("as_gangbuilder:getAllGangs", function()
    local src = source

    exports.oxmysql:query("SELECT * FROM gangs", {}, function(gangs)
        if not gangs or #gangs == 0 then
            TriggerClientEvent("as_gangbuilder:receiveGangs", src, {})
            return
        end

        -- Initialisation des structures de grade
        for i = 1, #gangs do
            gangs[i].grades = {}
        end

        exports.oxmysql:query("SELECT job_name, grade, name, label FROM job_grades", {}, function(grades)
            for _, grade in pairs(grades) do
                for i = 1, #gangs do
                    if grade.job_name == gangs[i].name then
                        table.insert(gangs[i].grades, {
                            grade = tonumber(grade.grade),
                            name = grade.name,
                            label = grade.label
                        })
                    end
                end
            end

            TriggerClientEvent("as_gangbuilder:receiveGangs", src, gangs)
        end)
    end)
end)

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
---------------------------------- BOSS --------------------------------------------
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------


ESX.RegisterServerCallback('as_gangbuilder:boss:getAllMembers', function(source, cb, gangName)
    if not gangName or gangName == '' then
        print("[AsGangs] [ERREUR] Nom du gang invalide fourni au callback.")
        return cb({})
    end

    exports.oxmysql:query([[
        SELECT identifier, firstname, lastname, UniqueID, job2, job2_grade
        FROM users
        WHERE job2 = ?
    ]], { gangName }, function(users)
        if not users or #users == 0 then
            print(('[AsGangs] Aucun membre trouvé pour le gang "%s".'):format(gangName))
            return cb({})
        end

        exports.oxmysql:query("SELECT grade, label FROM job_grades WHERE job_name = ?", { gangName }, function(grades)
            local gradeLabelMap = {}
            local maxGrade = -1

            for _, grade in pairs(grades) do
                local g = tonumber(grade.grade)
                gradeLabelMap[g] = grade.label
                if g > maxGrade then maxGrade = g end
            end

            local members = {}
            local boss = nil

            for _, user in pairs(users) do
                local g = tonumber(user.job2_grade)
                local label = gradeLabelMap[g] or "Inconnu"

                local memberData = {
                    identifier   = user.identifier,
                    firstname    = user.firstname,
                    lastname     = user.lastname,
                    UniqueID     = user.UniqueID,
                    job2         = user.job2,
                    job2_grade   = g,
                    gradeLabel   = label
                }

                if g == maxGrade then
                    boss = memberData
                else
                    table.insert(members, memberData)
                end
            end

            if boss then
                table.insert(members, 1, boss)
            end

            print(('[AsGangs] %d membre(s) chargés pour le gang "%s".'):format(#members, gangName))
            for i, m in ipairs(members) do
                local lock = (i == 1 and m.job2_grade == maxGrade) and " (BOSS - LOCK)" or ""
                print(('  → %s %s | ID: %s | Grade: %s%s')
                    :format(m.firstname, m.lastname, m.UniqueID, m.gradeLabel, lock))
            end

            cb(members)
        end)
    end)
end)


RegisterServerEvent('as_gangbuilder:boss:fireMember')
AddEventHandler('as_gangbuilder:boss:fireMember', function(identifier)
    if not identifier then return end

    exports.oxmysql:update("UPDATE users SET job2 = 'unemployed', job2_grade = 0 WHERE identifier = ?", {identifier}, function(rowsChanged)
        if rowsChanged  then
            TriggerClientEvent("esx:showNotification", source, "~r~Le membre a été viré du gang.")
        else
            TriggerClientEvent("esx:showNotification", source, "~r~Impossible de virer ce membre.")
        end
    end)
end)

RegisterServerEvent('as_gangbuilder:boss:promoteMember')
AddEventHandler('as_gangbuilder:boss:promoteMember', function(identifier, currentGrade)
    if not identifier or currentGrade == nil then return end
    local newGrade = tonumber(currentGrade) + 1

    exports.oxmysql:query("SELECT MAX(grade) as maxGrade FROM job_grades WHERE job_name = (SELECT job2 FROM users WHERE identifier = ?)", {identifier}, function(result)
        local maxGrade = tonumber(result[1].maxGrade or 0)

        if newGrade >= maxGrade then
            TriggerClientEvent("esx:showNotification", source, "~r~Promotion impossible : tu ne peux pas promouvoir au rang boss.")
            return
        end

        exports.oxmysql:update("UPDATE users SET job2_grade = ? WHERE identifier = ?", {newGrade, identifier}, function(rowsChanged)
            if rowsChanged then
                TriggerClientEvent("esx:showNotification", source, ("~g~Membre promu au grade %d."):format(newGrade))
            else
                TriggerClientEvent("esx:showNotification", source, "~r~La promotion a échoué.")
            end
        end)
    end)
end)

RegisterServerEvent('as_gangbuilder:boss:demoteMember')
AddEventHandler('as_gangbuilder:boss:demoteMember', function(identifier, currentGrade)
    if not identifier or currentGrade == nil then return end
    local newGrade = tonumber(currentGrade) - 1

    if newGrade < 0 then
        TriggerClientEvent("esx:showNotification", source, "~r~Rétrogradation impossible : grade minimal atteint.")
        return
    end

    exports.oxmysql:query("SELECT 1 FROM job_grades WHERE job_name = (SELECT job2 FROM users WHERE identifier = ?) AND grade = ?", {identifier, newGrade}, function(result)
        if result and #result > 0 then
            exports.oxmysql:update("UPDATE users SET job2_grade = ? WHERE identifier = ?", {newGrade, identifier}, function(rowsChanged)
                if rowsChanged  then
                    TriggerClientEvent("esx:showNotification", source, ("~y~Membre rétrogradé au grade %d."):format(newGrade))
                else
                    TriggerClientEvent("esx:showNotification", source, "~r~Échec de la rétrogradation.")
                end
            end)
        else
            TriggerClientEvent("esx:showNotification", source, "~r~Ce grade n'existe pas dans le métier.")
        end
    end)
end)




ESX = exports['es_extended']:getSharedObject()

-- Callback: Obtenir l'argent propre du gang
ESX.RegisterServerCallback('as_gangbuilder:getGangMoney', function(source, cb, gangName)
    exports.oxmysql:scalar("SELECT money FROM gangs WHERE name = ?", {gangName}, function(money)
        cb(money or 0)
    end)
end)

-- Callback: Obtenir l'argent sale du gang
ESX.RegisterServerCallback('as_gangbuilder:getGangBlackMoney', function(source, cb, gangName)
    exports.oxmysql:scalar("SELECT black_money FROM gangs WHERE name = ?", {gangName}, function(money)
        cb(money or 0)
    end)
end)

-- Dépôt argent propre
RegisterServerEvent("as_gangbuilder:depositGangMoney")
AddEventHandler("as_gangbuilder:depositGangMoney", function(gangName, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer and amount > 0 and xPlayer.getMoney() >= amount then
        xPlayer.removeMoney(amount)
        exports.oxmysql:update("UPDATE gangs SET money = money + ? WHERE name = ?", {amount, gangName})
        xPlayer.showNotification("~g~Vous avez déposé ~s~" .. amount .. "$ dans la caisse du gang.")
    else
        xPlayer.showNotification("~r~Fonds insuffisants pour déposer.")
    end
end)

-- Retrait argent propre
RegisterServerEvent("as_gangbuilder:withdrawGangMoney")
AddEventHandler("as_gangbuilder:withdrawGangMoney", function(gangName, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or amount <= 0 then return end

    exports.oxmysql:scalar("SELECT money FROM gangs WHERE name = ?", {gangName}, function(gangMoney)
        if gangMoney and gangMoney >= amount then
            exports.oxmysql:update("UPDATE gangs SET money = money - ? WHERE name = ?", {amount, gangName})
            xPlayer.addMoney(amount)
            xPlayer.showNotification("~g~Vous avez retiré ~s~" .. amount .. "$ du coffre de gang.")
        else
            xPlayer.showNotification("~r~Le coffre ne contient pas assez d'argent.")
        end
    end)
end)

-- Dépôt argent sale
RegisterServerEvent("as_gangbuilder:depositGangBlackMoney")
AddEventHandler("as_gangbuilder:depositGangBlackMoney", function(gangName, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer and amount > 0 and xPlayer.getAccount('black_money').money >= amount then
        xPlayer.removeAccountMoney('black_money', amount)
        exports.oxmysql:update("UPDATE gangs SET black_money = black_money + ? WHERE name = ?", {amount, gangName})
        xPlayer.showNotification("~g~Argent sale déposé : ~s~" .. amount .. "$.")
    else
        xPlayer.showNotification("~r~Argent sale insuffisant.")
    end
end)

-- Retrait argent sale
RegisterServerEvent("as_gangbuilder:withdrawGangBlackMoney")
AddEventHandler("as_gangbuilder:withdrawGangBlackMoney", function(gangName, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or amount <= 0 then return end

    exports.oxmysql:scalar("SELECT black_money FROM gangs WHERE name = ?", {gangName}, function(gangBlackMoney)
        if gangBlackMoney and gangBlackMoney >= amount then
            exports.oxmysql:update("UPDATE gangs SET black_money = black_money - ? WHERE name = ?", {amount, gangName})
            xPlayer.addAccountMoney('black_money', amount)
            xPlayer.showNotification("~g~Vous avez retiré ~s~" .. amount .. "$ d'argent sale du gang.")
        else
            xPlayer.showNotification("~r~Fonds d'argent sale insuffisants.")
        end
    end)
end)


local function sanitizeGrades(grades)
    if type(grades) ~= 'table' then return nil, 'liste invalide' end

    local cleaned, usedLevels, usedNames = {}, {}, {}
    local bossLevel = nil

    for _, grade in ipairs(grades) do
        if type(grade) ~= 'table' then return nil, 'grade invalide' end

        local name = SanitizeJobName(grade.name)
        local label = SanitizeLabel(grade.label)
        local level = tonumber(grade.grade)

        if not name or not label or not IsFiniteNumber(level) then return nil, 'grade invalide' end

        level = math.floor(level)
        if level < 0 or level > Config.MaxGradeLevel then return nil, 'niveau invalide' end
        if usedLevels[level] or usedNames[name] then return nil, 'doublon de grade' end

        usedLevels[level] = true
        usedNames[name] = true
        cleaned[#cleaned + 1] = { name = name, label = label, grade = level }

        if name == Config.BossGradeName then
            bossLevel = level
        end
    end

    if not bossLevel then return nil, 'grade boss manquant' end
    if #cleaned < 2 then return nil, 'ajoute au moins un grade non-boss' end

    for _, grade in ipairs(cleaned) do
        if grade.grade > bossLevel then return nil, 'le boss doit avoir le grade le plus haut' end
    end

    return cleaned
end

RegisterNetEvent('as_gangbuilder:createGang', function(data)
    local src = source

    if not IsGangAdmin(src) then
        Notify(src, '~r~Accès refusé.')
        return
    end

    if type(data) ~= 'table' then return end

    local name = SanitizeJobName(data.name)
    local label = SanitizeLabel(data.label)
    local posCoffre = SanitizeCoords(data.posCoffre)
    local posBoss = SanitizeCoords(data.posBoss)

    if not name or not label or not posCoffre or not posBoss or name == Config.UnemployedJob then
        Notify(src, '~r~Données du gang invalides.')
        return
    end

    local grades, gradeError = sanitizeGrades(data.grades)
    if not grades then
        Notify(src, '~r~Grades invalides : ' .. gradeError)
        return
    end

    local color = type(data.markerColor) == 'table' and data.markerColor or {}
    local markerType = SanitizeInteger(data.markerType, 0, 43, 1)
    local markerSize = SanitizeFloat(data.markerSize, 0.1, 10.0, 1.0)
    local colorR = SanitizeInteger(color.r, 0, 255, 255)
    local colorG = SanitizeInteger(color.g, 0, 255, 0)
    local colorB = SanitizeInteger(color.b, 0, 255, 0)

    local encodedCoffre = json.encode(posCoffre)
    local encodedBoss = json.encode(posBoss)

    exports.oxmysql:scalar('SELECT COUNT(*) FROM gangs WHERE name = ?', { name }, function(gangExists)
        exports.oxmysql:scalar('SELECT COUNT(*) FROM jobs WHERE name = ?', { name }, function(jobExists)
            local queries = {}

            if (gangExists or 0) > 0 then
                queries[#queries + 1] = {
                    query = [[
                        UPDATE gangs
                        SET label = ?, pos_coffre = ?, pos_boss = ?, marker_type = ?, marker_size = ?,
                            marker_color_r = ?, marker_color_g = ?, marker_color_b = ?
                        WHERE name = ?
                    ]],
                    values = { label, encodedCoffre, encodedBoss, markerType, markerSize, colorR, colorG, colorB, name }
                }
            else
                queries[#queries + 1] = {
                    query = [[
                        INSERT INTO gangs (name, label, pos_coffre, pos_boss, marker_type, marker_size, marker_color_r, marker_color_g, marker_color_b)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                    ]],
                    values = { name, label, encodedCoffre, encodedBoss, markerType, markerSize, colorR, colorG, colorB }
                }
            end

            if (jobExists or 0) > 0 then
                queries[#queries + 1] = {
                    query = 'UPDATE jobs SET label = ? WHERE name = ?',
                    values = { label, name }
                }
            else
                queries[#queries + 1] = {
                    query = 'INSERT INTO jobs (name, label, whitelisted, SecondaryJob) VALUES (?, ?, 0, 1)',
                    values = { name, label }
                }
            end

            queries[#queries + 1] = {
                query = 'DELETE FROM job_grades WHERE job_name = ?',
                values = { name }
            }

            for _, grade in ipairs(grades) do
                queries[#queries + 1] = {
                    query = [[
                        INSERT INTO job_grades (job_name, grade, name, label, salary, skin_male, skin_female)
                        VALUES (?, ?, ?, ?, 0, ?, ?)
                    ]],
                    values = { name, grade.grade, grade.name, grade.label, '{}', '{}' }
                }
            end

            exports.oxmysql:transaction(queries, function(success)
                if not success then
                    Notify(src, '~r~Erreur lors de l\'enregistrement du gang.')
                    return
                end

                TriggerEvent('esx_society:registerSociety', name, label, 'society_' .. name, 'society', 'society', {})
                RegisterGangStashes()
                TriggerClientEvent('as_gangbuilder:requestRefresh', -1)

                Notify(src, '~g~Gang \'' .. label .. '\' enregistré avec succès.')
                print(('[AsGangs] Gang "%s" enregistré par %s (ID %d).'):format(name, GetPlayerName(src) or 'console', src))
            end)
        end)
    end)
end)

RegisterNetEvent('as_gangbuilder:deleteGang', function(gangName)
    local src = source

    if not IsGangAdmin(src) then
        Notify(src, '~r~Accès refusé.')
        return
    end

    local name = SanitizeJobName(gangName)
    if not name then return end

    exports.oxmysql:transaction({
        { query = 'DELETE FROM jobs WHERE name = ?', values = { name } },
        { query = 'DELETE FROM job_grades WHERE job_name = ?', values = { name } },
        { query = 'DELETE FROM gangs WHERE name = ?', values = { name } },
        { query = 'UPDATE users SET job2 = ?, job2_grade = 0 WHERE job2 = ?', values = { Config.UnemployedJob, name } }
    }, function(success)
        if not success then
            Notify(src, '~r~Erreur lors de la suppression.')
            return
        end

        RegisterGangStashes()
        TriggerClientEvent('as_gangbuilder:requestRefresh', -1)

        Notify(src, '~g~Le gang a bien été supprimé.')
        print(('[AsGangs] Gang "%s" supprimé par %s (ID %d).'):format(name, GetPlayerName(src) or 'console', src))
    end)
end)

RegisterNetEvent('as_gangbuilder:getAllGangs', function()
    local src = source

    if not IsGangAdmin(src) then
        Notify(src, '~r~Accès refusé.')
        return
    end

    exports.oxmysql:query([[
        SELECT name, label, pos_coffre, pos_boss, marker_type, marker_size, marker_color_r, marker_color_g, marker_color_b
        FROM gangs
    ]], {}, function(gangs)
        if not gangs or #gangs == 0 then
            TriggerClientEvent('as_gangbuilder:receiveGangs', src, {})
            return
        end

        local index = {}
        for i = 1, #gangs do
            gangs[i].grades = {}
            index[gangs[i].name] = gangs[i]
        end

        exports.oxmysql:query('SELECT job_name, grade, name, label FROM job_grades', {}, function(grades)
            for _, grade in ipairs(grades or {}) do
                local gang = index[grade.job_name]
                if gang then
                    gang.grades[#gang.grades + 1] = {
                        grade = tonumber(grade.grade),
                        name = grade.name,
                        label = grade.label
                    }
                end
            end

            TriggerClientEvent('as_gangbuilder:receiveGangs', src, gangs)
        end)
    end)
end)

RegisterNetEvent('as_gangbuilder:getGangsForClient', function()
    local src = source
    local xPlayer, job2 = GetPlayerJob2(src)

    if not xPlayer or not job2 or not job2.name or job2.name == Config.UnemployedJob then
        TriggerClientEvent('as_gangbuilder:sendGangsToClient', src, {})
        TriggerClientEvent('as_gangbuilder:sendCoffres', src, {})
        return
    end

    exports.oxmysql:query([[
        SELECT name, label, pos_coffre, pos_boss, marker_type, marker_size, marker_color_r, marker_color_g, marker_color_b
        FROM gangs
        WHERE name = ?
    ]], { job2.name }, function(gangs)
        gangs = gangs or {}
        TriggerClientEvent('as_gangbuilder:sendGangsToClient', src, gangs)
        TriggerClientEvent('as_gangbuilder:sendCoffres', src, gangs)
    end)
end)

ESX.RegisterServerCallback('as_gangbuilder:isAdmin', function(source, cb)
    cb(IsGangAdmin(source))
end)

ESX.RegisterServerCallback('as_gangbuilder:boss:getAllMembers', function(source, cb, gangName)
    local src = source

    if not IsGangBoss(src, gangName) then
        return cb({})
    end

    exports.oxmysql:query([[
        SELECT identifier, firstname, lastname, UniqueID, job2, job2_grade
        FROM users
        WHERE job2 = ?
    ]], { gangName }, function(users)
        if not users or #users == 0 then
            return cb({})
        end

        exports.oxmysql:query('SELECT grade, label FROM job_grades WHERE job_name = ?', { gangName }, function(grades)
            local gradeLabels, maxGrade = {}, -1

            for _, grade in ipairs(grades or {}) do
                local level = tonumber(grade.grade)
                gradeLabels[level] = grade.label
                if level > maxGrade then maxGrade = level end
            end

            local members, boss = {}, nil

            for _, user in ipairs(users) do
                local level = tonumber(user.job2_grade) or 0
                local member = {
                    identifier = user.identifier,
                    firstname = user.firstname,
                    lastname = user.lastname,
                    UniqueID = user.UniqueID,
                    job2 = user.job2,
                    job2_grade = level,
                    gradeLabel = gradeLabels[level] or 'Inconnu'
                }

                if level == maxGrade and not boss then
                    boss = member
                else
                    members[#members + 1] = member
                end
            end

            if boss then
                table.insert(members, 1, boss)
            end

            DebugLog(('%d membre(s) chargés pour le gang "%s".'):format(#members, gangName))
            cb(members)
        end)
    end)
end)

local function withManagedMember(src, identifier, cb)
    if type(identifier) ~= 'string' or identifier == '' then return end

    local xPlayer, job2 = GetPlayerJob2(src)
    if not xPlayer or not job2 or job2.name == Config.UnemployedJob or job2.grade_name ~= Config.BossGradeName then
        Notify(src, '~r~Accès refusé.')
        return
    end

    if xPlayer.identifier == identifier then
        Notify(src, '~r~Vous ne pouvez pas vous gérer vous-même.')
        return
    end

    exports.oxmysql:query('SELECT job2, job2_grade FROM users WHERE identifier = ?', { identifier }, function(rows)
        local target = rows and rows[1]

        if not target or target.job2 ~= job2.name then
            Notify(src, '~r~Ce joueur ne fait pas partie de votre gang.')
            return
        end

        GetGangGradeBounds(job2.name, function(minGrade, maxGrade)
            if not maxGrade then
                Notify(src, '~r~Aucun grade défini pour ce gang.')
                return
            end

            local targetGrade = tonumber(target.job2_grade) or 0
            if targetGrade >= maxGrade then
                Notify(src, '~r~Vous ne pouvez pas gérer un autre boss.')
                return
            end

            cb(job2.name, targetGrade, minGrade, maxGrade)
        end)
    end)
end

RegisterNetEvent('as_gangbuilder:boss:fireMember', function(identifier)
    local src = source

    withManagedMember(src, identifier, function()
        ApplyJob2(identifier, Config.UnemployedJob, 0, function(done)
            Notify(src, done and '~r~Le membre a été viré du gang.' or '~r~Impossible de virer ce membre.')
        end)
    end)
end)

RegisterNetEvent('as_gangbuilder:boss:promoteMember', function(identifier)
    local src = source

    withManagedMember(src, identifier, function(gangName, targetGrade, _, maxGrade)
        local newGrade = targetGrade + 1

        if newGrade >= maxGrade then
            Notify(src, '~r~Promotion impossible : tu ne peux pas promouvoir au rang boss.')
            return
        end

        exports.oxmysql:scalar('SELECT COUNT(*) FROM job_grades WHERE job_name = ? AND grade = ?', { gangName, newGrade }, function(exists)
            if (exists or 0) == 0 then
                Notify(src, '~r~Ce grade n\'existe pas dans le gang.')
                return
            end

            ApplyJob2(identifier, gangName, newGrade, function(done)
                Notify(src, done and ('~g~Membre promu au grade %d.'):format(newGrade) or '~r~La promotion a échoué.')
            end)
        end)
    end)
end)

RegisterNetEvent('as_gangbuilder:boss:demoteMember', function(identifier)
    local src = source

    withManagedMember(src, identifier, function(gangName, targetGrade, minGrade)
        local newGrade = targetGrade - 1

        if newGrade < (minGrade or 0) then
            Notify(src, '~r~Rétrogradation impossible : grade minimal atteint.')
            return
        end

        exports.oxmysql:scalar('SELECT COUNT(*) FROM job_grades WHERE job_name = ? AND grade = ?', { gangName, newGrade }, function(exists)
            if (exists or 0) == 0 then
                Notify(src, '~r~Ce grade n\'existe pas dans le gang.')
                return
            end

            ApplyJob2(identifier, gangName, newGrade, function(done)
                Notify(src, done and ('~y~Membre rétrogradé au grade %d.'):format(newGrade) or '~r~Échec de la rétrogradation.')
            end)
        end)
    end)
end)

local function readGangFunds(column)
    return function(source, cb, gangName)
        if not IsGangBoss(source, gangName) then
            return cb(0)
        end

        exports.oxmysql:scalar(('SELECT %s FROM gangs WHERE name = ?'):format(column), { gangName }, function(amount)
            cb(tonumber(amount) or 0)
        end)
    end
end

ESX.RegisterServerCallback('as_gangbuilder:getGangMoney', readGangFunds('money'))
ESX.RegisterServerCallback('as_gangbuilder:getGangBlackMoney', readGangFunds('black_money'))

local function depositFunds(src, gangName, rawAmount, column, account)
    if not IsGangBoss(src, gangName) then return end

    local amount = SanitizeAmount(rawAmount)
    if not amount then
        Notify(src, '~r~Montant invalide.')
        return
    end

    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local available = account and xPlayer.getAccount(account).money or xPlayer.getMoney()
    if available < amount then
        Notify(src, '~r~Fonds insuffisants pour déposer.')
        return
    end

    if account then
        xPlayer.removeAccountMoney(account, amount)
    else
        xPlayer.removeMoney(amount)
    end

    exports.oxmysql:update(('UPDATE gangs SET %s = %s + ? WHERE name = ?'):format(column, column), { amount, gangName }, function(affected)
        if (affected or 0) > 0 then
            Notify(src, ('~g~Vous avez déposé ~s~%d$ dans la caisse du gang.'):format(amount))
            return
        end

        if account then
            xPlayer.addAccountMoney(account, amount)
        else
            xPlayer.addMoney(amount)
        end
        Notify(src, '~r~Dépôt impossible : gang introuvable.')
    end)
end

local function withdrawFunds(src, gangName, rawAmount, column, account)
    if not IsGangBoss(src, gangName) then return end

    local amount = SanitizeAmount(rawAmount)
    if not amount then
        Notify(src, '~r~Montant invalide.')
        return
    end

    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    exports.oxmysql:update(('UPDATE gangs SET %s = %s - ? WHERE name = ? AND %s >= ?'):format(column, column, column), { amount, gangName, amount }, function(affected)
        if (affected or 0) == 0 then
            Notify(src, '~r~Le coffre ne contient pas assez d\'argent.')
            return
        end

        if account then
            xPlayer.addAccountMoney(account, amount)
        else
            xPlayer.addMoney(amount)
        end

        Notify(src, ('~g~Vous avez retiré ~s~%d$ du coffre de gang.'):format(amount))
    end)
end

RegisterNetEvent('as_gangbuilder:depositGangMoney', function(gangName, amount)
    depositFunds(source, gangName, amount, 'money', nil)
end)

RegisterNetEvent('as_gangbuilder:withdrawGangMoney', function(gangName, amount)
    withdrawFunds(source, gangName, amount, 'money', nil)
end)

RegisterNetEvent('as_gangbuilder:depositGangBlackMoney', function(gangName, amount)
    depositFunds(source, gangName, amount, 'black_money', 'black_money')
end)

RegisterNetEvent('as_gangbuilder:withdrawGangBlackMoney', function(gangName, amount)
    withdrawFunds(source, gangName, amount, 'black_money', 'black_money')
end)

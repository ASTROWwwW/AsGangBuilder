ESX = exports['es_extended']:getSharedObject()

function IsFiniteNumber(value)
    return type(value) == 'number' and value == value and value ~= math.huge and value ~= -math.huge
end

function DebugLog(message)
    if Config.Debug then
        print('[AsGangs] ' .. message)
    end
end

function Notify(src, message)
    TriggerClientEvent('esx:showNotification', src, message)
end

function IsGangAdmin(src)
    return src == 0 or IsPlayerAceAllowed(src, Config.AdminAce)
end

function GetPlayerJob2(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return nil, nil end
    return xPlayer, xPlayer.job2
end

function IsGangMember(src, gangName)
    if type(gangName) ~= 'string' or gangName == '' or gangName == Config.UnemployedJob then
        return false
    end
    local xPlayer, job2 = GetPlayerJob2(src)
    if not xPlayer or not job2 then return false end
    return job2.name == gangName
end

function IsGangBoss(src, gangName)
    if not IsGangMember(src, gangName) then return false end
    local _, job2 = GetPlayerJob2(src)
    return job2.grade_name == Config.BossGradeName
end

function IsPlayerNear(src, targetId, maxDistance)
    targetId = tonumber(targetId)
    if not targetId or targetId == src then return false end

    local srcPed = GetPlayerPed(src)
    local targetPed = GetPlayerPed(targetId)
    if srcPed == 0 or targetPed == 0 then return false end

    return #(GetEntityCoords(srcPed) - GetEntityCoords(targetPed)) <= maxDistance
end

function SanitizeAmount(value)
    local amount = tonumber(value)
    if not IsFiniteNumber(amount) then return nil end

    amount = math.floor(amount)
    if amount <= 0 or amount > Config.MaxTransaction then return nil end

    return amount
end

function SanitizeJobName(value)
    if type(value) ~= 'string' then return nil end

    local name = value:lower():gsub('[^a-z0-9_]', '')
    if #name < 2 or #name > Config.MaxNameLength then return nil end

    return name
end

function SanitizeLabel(value)
    if type(value) ~= 'string' then return nil end

    local label = value:gsub('%c', ''):gsub('%s+', ' '):match('^%s*(.-)%s*$')
    if #label < 1 or #label > Config.MaxLabelLength then return nil end

    return label
end

function SanitizeCoords(value)
    if type(value) ~= 'table' then return nil end

    local x, y, z = tonumber(value.x), tonumber(value.y), tonumber(value.z)
    if not IsFiniteNumber(x) or not IsFiniteNumber(y) or not IsFiniteNumber(z) then return nil end

    return { x = x + 0.0, y = y + 0.0, z = z + 0.0 }
end

function SanitizeInteger(value, min, max, default)
    local number = tonumber(value)
    if not IsFiniteNumber(number) then return default end

    number = math.floor(number)
    if number < min then return min end
    if number > max then return max end

    return number
end

function SanitizeFloat(value, min, max, default)
    local number = tonumber(value)
    if not IsFiniteNumber(number) then return default end

    if number < min then return min end
    if number > max then return max end

    return number + 0.0
end

function GetGangGradeBounds(gangName, cb)
    exports.oxmysql:query('SELECT MIN(grade) AS minGrade, MAX(grade) AS maxGrade FROM job_grades WHERE job_name = ?', { gangName }, function(rows)
        local row = rows and rows[1]
        if not row or row.maxGrade == nil then
            return cb(nil, nil)
        end
        cb(tonumber(row.minGrade), tonumber(row.maxGrade))
    end)
end

function ApplyJob2(identifier, jobName, grade, cb)
    local xTarget = ESX.GetPlayerFromIdentifier and ESX.GetPlayerFromIdentifier(identifier)

    if xTarget then
        xTarget.setJob2(jobName, grade)
        return cb(true)
    end

    exports.oxmysql:update('UPDATE users SET job2 = ?, job2_grade = ? WHERE identifier = ?', { jobName, grade, identifier }, function(affected)
        cb((affected or 0) > 0)
    end)
end

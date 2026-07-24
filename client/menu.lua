local mainMenu = RageUI.CreateMenu('Gang Builder', 'Création d\'un gang')
local gradesMenu = RageUI.CreateSubMenu(mainMenu, 'Grades', 'Liste des grades')
local gradeEditMenu = RageUI.CreateSubMenu(gradesMenu, 'Grade', 'Modifier un grade')
local bossGradeMenu = RageUI.CreateSubMenu(gradesMenu, 'Grade Boss', 'Modifier le label')
local menuPrincipal = RageUI.CreateMenu('Gestion Gangs', 'Sélectionner une action')
local menuGangsList = RageUI.CreateSubMenu(menuPrincipal, 'Gangs existants', 'Modifier un gang')

local availableGangs = {}
local isEditing = false
local isMenuOpen = false
local selectedGrade = nil

local defaultData = {
    name = '',
    label = '',
    posCoffre = nil,
    posBoss = nil,
    markerType = 1,
    markerSize = 1.0,
    markerColor = { r = 255, g = 0, b = 0 },
    grades = {}
}

local gangBuilderData = {}

local function resetBuilderData()
    isEditing = false
    gangBuilderData = {
        name = defaultData.name,
        label = defaultData.label,
        posCoffre = nil,
        posBoss = nil,
        markerType = defaultData.markerType,
        markerSize = defaultData.markerSize,
        markerColor = { r = 255, g = 0, b = 0 },
        grades = {}
    }
end

resetBuilderData()

local function goBack(child, parent)
    RageUI.Visible(child, false)
    RageUI.Visible(parent, true)
end

local function clamp(value, min, max, fallback)
    local number = tonumber(value)
    if not number or number ~= number then return fallback end
    if number < min then return min end
    if number > max then return max end
    return number
end

local function updateBossGrade()
    local maxGrade = -1
    local bossLabel = 'Chef'
    local newGrades = {}

    for _, grade in ipairs(gangBuilderData.grades) do
        if grade.name ~= Config.BossGradeName then
            newGrades[#newGrades + 1] = grade
            if grade.grade > maxGrade then
                maxGrade = grade.grade
            end
        elseif grade.label then
            bossLabel = grade.label
        end
    end

    newGrades[#newGrades + 1] = {
        name = Config.BossGradeName,
        label = bossLabel,
        grade = maxGrade + 1
    }

    gangBuilderData.grades = newGrades
end

local function loadGangIntoBuilder(gang)
    local coffre = json.decode(gang.pos_coffre)
    local boss = json.decode(gang.pos_boss)

    isEditing = true
    gangBuilderData.name = gang.name
    gangBuilderData.label = gang.label
    gangBuilderData.posCoffre = coffre and vector3(coffre.x + 0.0, coffre.y + 0.0, coffre.z + 0.0) or nil
    gangBuilderData.posBoss = boss and vector3(boss.x + 0.0, boss.y + 0.0, boss.z + 0.0) or nil
    gangBuilderData.markerType = tonumber(gang.marker_type) or defaultData.markerType
    gangBuilderData.markerSize = tonumber(gang.marker_size) or defaultData.markerSize
    gangBuilderData.markerColor = {
        r = tonumber(gang.marker_color_r) or 255,
        g = tonumber(gang.marker_color_g) or 0,
        b = tonumber(gang.marker_color_b) or 0
    }
    gangBuilderData.grades = gang.grades or {}

    updateBossGrade()
end

RegisterNetEvent('as_gangbuilder:receiveGangs', function(gangs)
    availableGangs = gangs or {}
end)

local function drawBuilderMenus()
    RageUI.IsVisible(menuPrincipal, function()
        RageUI.Button('~g~Créer un nouveau gang', nil, {}, true, {
            onSelected = function()
                resetBuilderData()
                RageUI.Visible(mainMenu, true)
            end
        })

        RageUI.Button('~b~Modifier un gang existant', nil, {}, true, {
            onSelected = function()
                TriggerServerEvent('as_gangbuilder:getAllGangs')
                RageUI.Visible(menuGangsList, true)
            end
        })
    end)

    RageUI.IsVisible(mainMenu, function()
        RageUI.Button('Nom du gang : ~b~' .. (gangBuilderData.name ~= '' and gangBuilderData.name or 'Non défini'), nil, {}, not isEditing, {
            onSelected = function()
                local input = KeyboardInput('Nom du gang', gangBuilderData.name, Config.MaxNameLength)
                if input then
                    gangBuilderData.name = input:lower():gsub('[^a-z0-9_]', '')
                end
            end
        })

        RageUI.Button('Label du gang : ~b~' .. (gangBuilderData.label ~= '' and gangBuilderData.label or 'Non défini'), nil, {}, true, {
            onSelected = function()
                local input = KeyboardInput('Label du gang', gangBuilderData.label, Config.MaxLabelLength)
                if input then gangBuilderData.label = input end
            end
        })

        RageUI.Button('Position Coffre : ~b~' .. (gangBuilderData.posCoffre and 'Définie' or 'Non définie'), 'Appuie pour enregistrer ta position actuelle', {}, true, {
            onSelected = function()
                gangBuilderData.posCoffre = GetEntityCoords(PlayerPedId())
            end
        })

        RageUI.Button('Position Boss : ~b~' .. (gangBuilderData.posBoss and 'Définie' or 'Non définie'), 'Appuie pour enregistrer ta position actuelle', {}, true, {
            onSelected = function()
                gangBuilderData.posBoss = GetEntityCoords(PlayerPedId())
            end
        })

        RageUI.Button('Type de marker : ~b~' .. gangBuilderData.markerType, nil, {}, true, {
            onSelected = function()
                local input = KeyboardInput('Type de marker (0-43)', tostring(gangBuilderData.markerType), 3)
                if input then
                    gangBuilderData.markerType = math.floor(clamp(input, 0, 43, gangBuilderData.markerType))
                end
            end
        })

        RageUI.Button('Taille marker : ~b~' .. gangBuilderData.markerSize, nil, {}, true, {
            onSelected = function()
                local input = KeyboardInput('Taille du marker (0.1 - 10.0)', tostring(gangBuilderData.markerSize), 4)
                if input then
                    gangBuilderData.markerSize = clamp(input, 0.1, 10.0, gangBuilderData.markerSize)
                end
            end
        })

        RageUI.Button('Couleur marker : R (~r~' .. gangBuilderData.markerColor.r .. '~s~)', nil, {}, true, {
            onSelected = function()
                local input = KeyboardInput('Rouge (0-255)', tostring(gangBuilderData.markerColor.r), 3)
                if input then
                    gangBuilderData.markerColor.r = math.floor(clamp(input, 0, 255, gangBuilderData.markerColor.r))
                end
            end
        })

        RageUI.Button('Couleur marker : G (~g~' .. gangBuilderData.markerColor.g .. '~s~)', nil, {}, true, {
            onSelected = function()
                local input = KeyboardInput('Vert (0-255)', tostring(gangBuilderData.markerColor.g), 3)
                if input then
                    gangBuilderData.markerColor.g = math.floor(clamp(input, 0, 255, gangBuilderData.markerColor.g))
                end
            end
        })

        RageUI.Button('Couleur marker : B (~b~' .. gangBuilderData.markerColor.b .. '~s~)', nil, {}, true, {
            onSelected = function()
                local input = KeyboardInput('Bleu (0-255)', tostring(gangBuilderData.markerColor.b), 3)
                if input then
                    gangBuilderData.markerColor.b = math.floor(clamp(input, 0, 255, gangBuilderData.markerColor.b))
                end
            end
        })

        RageUI.Button('Grades', nil, {}, true, {
            onSelected = function()
                RageUI.Visible(gradesMenu, true)
            end
        })

        RageUI.Button('~g~Valider la création du gang', nil, {}, true, {
            onSelected = function()
                if gangBuilderData.name == '' or gangBuilderData.label == '' or not gangBuilderData.posCoffre or not gangBuilderData.posBoss then
                    ESX.ShowNotification('~r~Tous les champs doivent être remplis.')
                    return
                end

                updateBossGrade()

                if #gangBuilderData.grades < 2 then
                    ESX.ShowNotification('~r~Ajoute au moins un grade en plus du boss.')
                    return
                end

                TriggerServerEvent('as_gangbuilder:createGang', {
                    name = gangBuilderData.name,
                    label = gangBuilderData.label,
                    posCoffre = { x = gangBuilderData.posCoffre.x, y = gangBuilderData.posCoffre.y, z = gangBuilderData.posCoffre.z },
                    posBoss = { x = gangBuilderData.posBoss.x, y = gangBuilderData.posBoss.y, z = gangBuilderData.posBoss.z },
                    markerType = gangBuilderData.markerType,
                    markerSize = gangBuilderData.markerSize,
                    markerColor = gangBuilderData.markerColor,
                    grades = gangBuilderData.grades
                })

                RageUI.CloseAll()
                isMenuOpen = false
            end
        })

        if isEditing then
            RageUI.Line()

            RageUI.Button('~r~Supprimer ce gang', '~r~Cette action est irréversible', {}, true, {
                onSelected = function()
                    local confirm = KeyboardInput('Tapez OUI pour confirmer la suppression', '', 5)

                    if confirm and confirm:lower() == 'oui' then
                        TriggerServerEvent('as_gangbuilder:deleteGang', gangBuilderData.name)
                        RageUI.CloseAll()
                        isMenuOpen = false
                        resetBuilderData()
                    else
                        ESX.ShowNotification('~y~Suppression annulée.')
                    end
                end
            })
        end
    end)

    RageUI.IsVisible(gradesMenu, function()
        RageUI.Separator('~b~Grades définis')

        for index, grade in ipairs(gangBuilderData.grades) do
            if grade.name ~= Config.BossGradeName then
                RageUI.Button(('%s (%s - grade: %s)'):format(grade.label, grade.name, grade.grade), nil, {}, true, {
                    onSelected = function()
                        selectedGrade = index
                        RageUI.Visible(gradeEditMenu, true)
                    end
                })
            end
        end

        RageUI.Line()

        for index, grade in ipairs(gangBuilderData.grades) do
            if grade.name == Config.BossGradeName then
                RageUI.Button(('Boss (%s - grade : %s)'):format(grade.label, grade.grade), 'Modifier uniquement le label du boss', {}, true, {
                    onSelected = function()
                        selectedGrade = index
                        RageUI.Visible(bossGradeMenu, true)
                    end
                })
                break
            end
        end

        RageUI.Button('~g~Ajouter un grade', nil, {}, true, {
            onSelected = function()
                local name = KeyboardInput('Nom du grade (ex: recruit)', '', Config.MaxNameLength)
                if not name then return end

                name = name:lower():gsub('[^a-z0-9_]', '')
                if #name < 2 or name == Config.BossGradeName then
                    ESX.ShowNotification('~r~Nom de grade invalide.')
                    return
                end

                local label = KeyboardInput('Label du grade (ex: Recrue)', '', Config.MaxLabelLength)
                if not label or label == '' then return end

                local gradeValue = tonumber(KeyboardInput('Numéro de hiérarchie (ex: 0,1,2)', '', 2))
                if not gradeValue then
                    ESX.ShowNotification('~r~Numéro de grade invalide.')
                    return
                end

                gradeValue = math.floor(clamp(gradeValue, 0, Config.MaxGradeLevel, 0))

                for _, existing in ipairs(gangBuilderData.grades) do
                    if existing.name ~= Config.BossGradeName and (existing.grade == gradeValue or existing.name == name) then
                        ESX.ShowNotification('~r~Ce grade existe déjà.')
                        return
                    end
                end

                gangBuilderData.grades[#gangBuilderData.grades + 1] = {
                    name = name,
                    label = label,
                    grade = gradeValue
                }

                updateBossGrade()
            end
        })
    end)

    RageUI.IsVisible(gradeEditMenu, function()
        local grade = gangBuilderData.grades[selectedGrade]
        if not grade or grade.name == Config.BossGradeName then return end

        RageUI.Button('Nom : ~b~' .. grade.name, nil, {}, false)

        RageUI.Button('Label : ~b~' .. grade.label, nil, {}, true, {
            onSelected = function()
                local input = KeyboardInput('Label du grade', grade.label, Config.MaxLabelLength)
                if input and input ~= '' then grade.label = input end
            end
        })

        RageUI.Button('Grade (hiérarchie) : ~b~' .. grade.grade, nil, {}, true, {
            onSelected = function()
                local input = tonumber(KeyboardInput('Grade hiérarchique', tostring(grade.grade), 2))
                if not input then return end

                local value = math.floor(clamp(input, 0, Config.MaxGradeLevel, grade.grade))

                for index, existing in ipairs(gangBuilderData.grades) do
                    if index ~= selectedGrade and existing.name ~= Config.BossGradeName and existing.grade == value then
                        ESX.ShowNotification('~r~Un grade avec ce niveau existe déjà.')
                        return
                    end
                end

                grade.grade = value
                updateBossGrade()
            end
        })

        RageUI.Button('~r~Supprimer ce grade', nil, {}, true, {
            onSelected = function()
                table.remove(gangBuilderData.grades, selectedGrade)
                selectedGrade = nil
                updateBossGrade()
                goBack(gradeEditMenu, gradesMenu)
            end
        })
    end)

    RageUI.IsVisible(bossGradeMenu, function()
        local grade = gangBuilderData.grades[selectedGrade]
        if not grade then return end

        RageUI.Separator('~r~Grade Boss (verrouillé sauf label)')
        RageUI.Button('Nom : ~c~boss (fixe)', nil, {}, false)
        RageUI.Button('Grade : ~c~' .. grade.grade .. ' (automatique)', nil, {}, false)

        RageUI.Button('Label : ~b~' .. grade.label, 'Modifier le label du boss', {}, true, {
            onSelected = function()
                local input = KeyboardInput('Label du grade boss', grade.label, Config.MaxLabelLength)
                if input and input ~= '' then grade.label = input end
            end
        })
    end)

    RageUI.IsVisible(menuGangsList, function()
        if #availableGangs == 0 then
            RageUI.Separator('~r~Aucun gang trouvé')
            return
        end

        for _, gang in ipairs(availableGangs) do
            RageUI.Button(('%s (%s)'):format(gang.label, gang.name), 'Modifier ce gang', {}, true, {
                onSelected = function()
                    loadGangIntoBuilder(gang)
                    RageUI.Visible(mainMenu, true)
                end
            })
        end
    end)
end

RegisterCommand('gangbuilder', function()
    if isMenuOpen then
        isMenuOpen = false
        RageUI.CloseAll()
        return
    end

    ESX.TriggerServerCallback('as_gangbuilder:isAdmin', function(allowed)
        if not allowed then
            ESX.ShowNotification('~r~Vous n\'avez pas accès à cet outil.')
            return
        end

        isMenuOpen = true
        RageUI.Visible(menuPrincipal, true)

        CreateThread(function()
            while isMenuOpen do
                Wait(1)
                drawBuilderMenus()
            end
        end)
    end)
end, false)

CreateThread(function()
    while true do
        local sleep = 500

        if isMenuOpen then
            sleep = 1

            local markerType = gangBuilderData.markerType or 1
            local markerSize = gangBuilderData.markerSize or 1.0
            local color = gangBuilderData.markerColor

            if gangBuilderData.posCoffre then
                DrawMarker(markerType,
                    gangBuilderData.posCoffre.x, gangBuilderData.posCoffre.y, gangBuilderData.posCoffre.z - 0.95,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    markerSize, markerSize, markerSize,
                    color.r, color.g, color.b,
                    180, false, true, 2, nil, nil, false)
            end

            if gangBuilderData.posBoss then
                DrawMarker(markerType,
                    gangBuilderData.posBoss.x, gangBuilderData.posBoss.y, gangBuilderData.posBoss.z - 0.95,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    markerSize, markerSize, markerSize,
                    color.r, color.g, color.b,
                    180, false, true, 2, nil, nil, false)
            end
        end

        Wait(sleep)
    end
end)

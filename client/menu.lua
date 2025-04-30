local mainMenu = RageUI.CreateMenu("Gang Builder", "Création d’un gang")
local gradesMenu = RageUI.CreateSubMenu(mainMenu, "Grades", "Liste des grades")
local gradeEditMenu = RageUI.CreateSubMenu(gradesMenu, "Grade", "Modifier un grade")
local bossGradeMenu = RageUI.CreateSubMenu(gradesMenu, "Grade Boss", "Modifier le label")
local menuPrincipal = RageUI.CreateMenu("Gestion Gangs", "Sélectionner une action")
local menuGangsList = RageUI.CreateSubMenu(menuPrincipal, "Gangs existants", "Modifier un gang")
local availableGangs = {}
local isEditing = false

local isMenuOpen = false
local selectedGrade = nil
RegisterNetEvent("as_gangbuilder:receiveGangs", function(gangs)
    availableGangs = gangs
end)

local gangBuilderData = {
    name = "",
    label = "",
    posCoffre = nil,
    posBoss = nil,
    markerType = 1, -- FIX ICI
    markerSize = 1.0,
    markerColor = {r = 255, g = 0, b = 0},
    grades = {}
}

function LoadGangIntoBuilder(gang)
    isEditing = true
    gangBuilderData.name = gang.name
    gangBuilderData.label = gang.label
    gangBuilderData.posCoffre = vector3(json.decode(gang.pos_coffre).x, json.decode(gang.pos_coffre).y, json.decode(gang.pos_coffre).z)
    gangBuilderData.posBoss   = vector3(json.decode(gang.pos_boss).x, json.decode(gang.pos_boss).y, json.decode(gang.pos_boss).z)    
    gangBuilderData.markerType = tonumber(gang.marker_type)
    gangBuilderData.markerSize = tonumber(gang.marker_size)
    gangBuilderData.markerColor = {
        r = tonumber(gang.marker_color_r),
        g = tonumber(gang.marker_color_g),
        b = tonumber(gang.marker_color_b)
    }
    gangBuilderData.grades = gang.grades or {}
    UpdateBossGrade()
end

function ResetGangBuilderData()
    isEditing = false
    gangBuilderData = {
        name = "",
        label = "",
        posCoffre = nil,
        posBoss = nil,
        markerType = "",
        markerSize = 1.0,
        markerColor = {r = 255, g = 0, b = 0},
        grades = {}
    }
end

RegisterCommand("gangbuilder", function()
    isMenuOpen = not isMenuOpen
    RageUI.Visible(menuPrincipal, isMenuOpen)
    CreateThread(function()
        while isMenuOpen do
            Wait(1)
            RageUI.IsVisible(menuPrincipal, function()
                RageUI.Button("~g~Créer un nouveau gang", nil, {}, true, {
                    onSelected = function()
                        ResetGangBuilderData() -- nouvelle instance vierge
                        RageUI.Visible(mainMenu, true)
                    end
                })
            
                RageUI.Button("~b~Modifier un gang existant", nil, {}, true, {
                    onSelected = function()
                        TriggerServerEvent("as_gangbuilder:getAllGangs")
                        RageUI.Visible(menuGangsList, true)
                    end
                })
            end)
            
            RageUI.IsVisible(mainMenu, function()

                RageUI.Button("Nom du gang : ~b~" .. (gangBuilderData.name ~= "" and gangBuilderData.name or "Non défini"), nil, {}, true, {
                    onSelected = function()
                        local input = KeyboardInput("Nom du gang", gangBuilderData.name, 20)
                        if input then gangBuilderData.name = input end
                    end
                })

                RageUI.Button("Label du gang : ~b~" .. (gangBuilderData.label ~= "" and gangBuilderData.label or "Non défini"), nil, {}, true, {
                    onSelected = function()
                        local input = KeyboardInput("Label du gang", gangBuilderData.label, 20)
                        if input then gangBuilderData.label = input end
                    end
                })

                RageUI.Button("Position Coffre : ~b~" .. (gangBuilderData.posCoffre and "Définie" or "Non définie"), "Appuie pour enregistrer ta position actuelle", {}, true, {
                    onSelected = function()
                        local coords = GetEntityCoords(PlayerPedId())
                        gangBuilderData.posCoffre = vector3(coords.x, coords.y, coords.z)
                    end
                })

                RageUI.Button("Position Boss : ~b~" .. (gangBuilderData.posBoss and "Définie" or "Non définie"), "Appuie pour enregistrer ta position actuelle", {}, true, {
                    onSelected = function()
                        local coords = GetEntityCoords(PlayerPedId())
                        gangBuilderData.posBoss = vector3(coords.x, coords.y, coords.z)
                    end
                })

                RageUI.Button("Type de marker : ~b~" .. (gangBuilderData.markerType or "Non défini"), nil, {}, true, {
                    onSelected = function()
                        local input = KeyboardInput("Type de marker (ex: 1, 2, 6)", tostring(gangBuilderData.markerType), 3)

                        if input then gangBuilderData.markerType = tonumber(input) end
                    end
                })

                RageUI.Button("Taille marker : ~b~" .. gangBuilderData.markerSize, nil, {}, true, {
                    onSelected = function()
                        local input = KeyboardInput("Taille du marker (ex: 1.0, 2.5)", tostring(gangBuilderData.markerSize), 4)
                        if input then gangBuilderData.markerSize = tonumber(input) end
                    end
                })

                RageUI.Button("Couleur marker : R (~r~" .. gangBuilderData.markerColor.r .. "~s~)", nil, {}, true, {
                    onSelected = function()
                        local input = KeyboardInput("Rouge (0-255)", tostring(gangBuilderData.markerColor.r), 3)
                        if input then gangBuilderData.markerColor.r = tonumber(input) end
                    end
                })

                RageUI.Button("Couleur marker : G (~g~" .. gangBuilderData.markerColor.g .. "~s~)", nil, {}, true, {
                    onSelected = function()
                        local input = KeyboardInput("Vert (0-255)", tostring(gangBuilderData.markerColor.g), 3)
                        if input then gangBuilderData.markerColor.g = tonumber(input) end
                    end
                })

                RageUI.Button("Couleur marker : B (~b~" .. gangBuilderData.markerColor.b .. "~s~)", nil, {}, true, {
                    onSelected = function()
                        local input = KeyboardInput("Bleu (0-255)", tostring(gangBuilderData.markerColor.b), 3)
                        if input then gangBuilderData.markerColor.b = tonumber(input) end
                    end
                })

                RageUI.Button("Grades", nil, {}, true, {
                    onSelected = function()
                        RageUI.Visible(gradesMenu, true)
                    end
                })
                RageUI.Button("~g~Valider la création du gang", nil, {}, true, {
                    onSelected = function()
                        if gangBuilderData.name == "" or gangBuilderData.label == "" or not gangBuilderData.posCoffre or not gangBuilderData.posBoss then
                            ESX.ShowNotification("~r~Tous les champs doivent être remplis.")
                            return
                        end
                
                        TriggerServerEvent("as_gangbuilder:createGang", gangBuilderData)
                        ESX.ShowNotification("~g~Gang envoyé au serveur !")
                        RageUI.CloseAll()
                        isMenuOpen = false
                    end
                })

                if isEditing then
                    RageUI.Line()
                    RageUI.Button("~r~Supprimer ce gang", "~r~Cette action est irréversible", {}, true, {
                        onSelected = function()
                            local confirm = KeyboardInput("Tapez OUI pour confirmer la suppression", "", 5)
                            if confirm and confirm:lower() == "oui" then
                                TriggerServerEvent("as_gangbuilder:deleteGang", gangBuilderData.name)
                                RageUI.CloseAll()
                                isMenuOpen = false
                                ResetGangBuilderData()
                            else
                                ESX.ShowNotification("~y~Suppression annulée.")
                            end
                        end
                    })
                end
                
                

            end)

            RageUI.IsVisible(gradesMenu, function()
                RageUI.Separator("~b~Grades définis")

                for i, grade in ipairs(gangBuilderData.grades) do
                    if grade.name ~= "boss" then
                        RageUI.Button(grade.label .. " (" .. grade.name .. " - grade: " .. grade.grade .. ")", nil, {}, true, {
                            onSelected = function()
                                selectedGrade = i
                                RageUI.Visible(gradeEditMenu, true)
                            end
                        })
                    end
                end
                
                
                
                RageUI.Line()
                local bossGrade = nil
                for i, grade in ipairs(gangBuilderData.grades) do
                    if grade.name == "boss" then
                        bossGrade = grade
                        break
                    end
                end
                
                if bossGrade then
                    RageUI.Button("Boss (" .. bossGrade.label .. " - grade : " .. bossGrade.grade .. ")", "Modifier uniquement le label du boss", {}, true, {
                        onSelected = function()
                            for i, grade in ipairs(gangBuilderData.grades) do
                                if grade.name == "boss" then
                                    selectedGrade = i
                                    break
                                end
                            end
                            RageUI.Visible(bossGradeMenu, true)
                        end
                    })
                end
                
                
                    
               
                
                RageUI.Button("~g~Ajouter un grade", nil, {}, true, {
                    onSelected = function()
                        local name = KeyboardInput("Nom du grade (ex: recruit)", "", 20)
                        local label = KeyboardInput("Label du grade (ex: Recrue)", "", 20)
                        local gradeNum = KeyboardInput("Numéro de hiérarchie (ex: 0,1,2)", "", 2)
                        if name and label and gradeNum then
                            local gradeValue = tonumber(gradeNum)
                            if gradeValue then
                                -- Vérifie si ce grade est déjà utilisé (hors boss)
                                for _, g in ipairs(gangBuilderData.grades) do
                                    if g.grade == gradeValue and g.name ~= "boss" then
                                        ESX.ShowNotification("~r~Un grade avec ce niveau existe déjà.")
                                        return
                                    end
                                end
                                table.insert(gangBuilderData.grades, {
                                    name = name,
                                    label = label,
                                    grade = gradeValue
                                })
                                UpdateBossGrade()
                            end
                        end
                    end
                })
                
                
            end)

            RageUI.IsVisible(gradeEditMenu, function()
                local grade = gangBuilderData.grades[selectedGrade]
                if grade then
                    if grade.name ~= "boss" then
                        RageUI.Button("Nom : ~b~" .. grade.name, nil, {}, false)
                        RageUI.Button("Label : ~b~" .. grade.label, nil, {}, true, {
                            onSelected = function()
                                local input = KeyboardInput("Label du grade", grade.label, 20)
                                if input then grade.label = input end
                            end
                        })
                        RageUI.Button("Grade (hiérarchie) : ~b~" .. grade.grade, nil, {}, true, {
                            onSelected = function()
                                local input = KeyboardInput("Grade hiérarchique", tostring(grade.grade), 2)
                                if input then grade.grade = tonumber(input) end
                            end
                        })
                        RageUI.Button("~r~Supprimer ce grade", nil, {}, true, {
                            onSelected = function()
                                table.remove(gangBuilderData.grades, selectedGrade)
                                UpdateBossGrade()
                                RageUI.GoBack()
                            end
                        })
                    else
                        RageUI.Button("Nom : ~c~boss (fixe)", nil, {}, false)
                        RageUI.Button("Grade : ~c~" .. grade.grade .. " (auto)", nil, {}, false)
                        RageUI.Button("Label : ~b~" .. grade.label, nil, {}, true, {
                            onSelected = function()
                                local input = KeyboardInput("Label du boss", grade.label, 20)
                                if input then grade.label = input end
                            end
                        })
                    end
                end
            end)
            RageUI.IsVisible(bossGradeMenu, function()
                local grade = gangBuilderData.grades[selectedGrade]
                if grade then
                    RageUI.Separator("~r~Grade Boss (verrouillé sauf label)")
                    
                    RageUI.Button("Nom : ~c~boss (fixe)", nil, {}, false)
            
                    RageUI.Button("Grade : ~c~" .. grade.grade .. " (automatique)", nil, {}, false)
            
                    RageUI.Button("Label : ~b~" .. grade.label, "Modifier le label du boss", {}, true, {
                        onSelected = function()
                            local input = KeyboardInput("Label du grade boss", grade.label, 20)
                            if input then
                                grade.label = input
                            end
                        end
                    })
                end
            end)
            RageUI.IsVisible(menuGangsList, function()
                if #availableGangs == 0 then
                    RageUI.Separator("~r~Aucun gang trouvé")
                else
                    for i, gang in ipairs(availableGangs) do
                        RageUI.Button(gang.label .. " (" .. gang.name .. ")", "Modifier ce gang", {}, true, {
                            onSelected = function()
                                LoadGangIntoBuilder(gang)
                                RageUI.Visible(mainMenu, true)
                            end
                        })
                    end
                end
            end)
            
            
        end
    end)
end)



function KeyboardInput(entryTitle, textEntry, maxLength)
    AddTextEntry('FMMC_KEY_TIP1', entryTitle)
    DisplayOnscreenKeyboard(1, 'FMMC_KEY_TIP1', '', textEntry, '', '', '', maxLength)
    while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do Wait(0) end
    if UpdateOnscreenKeyboard() ~= 2 then
        return GetOnscreenKeyboardResult()
    end
    return nil
end



CreateThread(function()
    while true do
        Wait(0)
        if isMenuOpen then
            local markerType = tonumber(gangBuilderData.markerType) or 1
            local markerSize = tonumber(gangBuilderData.markerSize) or 1.0
            local r = gangBuilderData.markerColor.r or 255
            local g = gangBuilderData.markerColor.g or 0
            local b = gangBuilderData.markerColor.b or 0

            if gangBuilderData.posCoffre then
                DrawMarker(markerType, gangBuilderData.posCoffre.x, gangBuilderData.posCoffre.y, gangBuilderData.posCoffre.z - 0.95, 
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    markerSize, markerSize, markerSize, r, g, b, 180, false, true, 2, nil, nil, false)
            end

            if gangBuilderData.posBoss then
                DrawMarker(markerType, gangBuilderData.posBoss.x, gangBuilderData.posBoss.y, gangBuilderData.posBoss.z - 0.95, 
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    markerSize, markerSize, markerSize, r, g, b, 180, false, true, 2, nil, nil, false)
            end
        else
            Wait(500)
        end
    end
end)

function UpdateBossGrade()
    local maxGrade = -1
    local bossLabel = "Chef"
    local newGrades = {}

    -- Parcourt et récupère tous les grades sauf le boss
    for _, grade in ipairs(gangBuilderData.grades) do
        if grade.name ~= "boss" then
            table.insert(newGrades, grade)
            if grade.grade > maxGrade then
                maxGrade = grade.grade
            end
        elseif grade.label then
            bossLabel = grade.label -- on récupère l'ancien label s'il existe
        end
    end

    -- Ajoute un nouveau grade boss avec grade supérieur
    table.insert(newGrades, {
        name = "boss",
        label = bossLabel,
        grade = maxGrade + 1
    })

    gangBuilderData.grades = newGrades -- remplace proprement
end

CreateThread(function()
    while true do
        Wait(0)
        if isMenuOpen then
            local markerType = tonumber(gangBuilderData.markerType) or 1
            local markerSize = tonumber(gangBuilderData.markerSize) or 1.0
            local r = gangBuilderData.markerColor.r or 255
            local g = gangBuilderData.markerColor.g or 0
            local b = gangBuilderData.markerColor.b or 0

            -- ✅ Ceci s'exécute automatiquement avec les données chargées
            if gangBuilderData.posCoffre then
                DrawMarker(markerType, gangBuilderData.posCoffre.x, gangBuilderData.posCoffre.y, gangBuilderData.posCoffre.z - 0.95,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    markerSize, markerSize, markerSize, r, g, b, 180, false, true, 2, nil, nil, false)
            end

            if gangBuilderData.posBoss then
                DrawMarker(markerType, gangBuilderData.posBoss.x, gangBuilderData.posBoss.y, gangBuilderData.posBoss.z - 0.95,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    markerSize, markerSize, markerSize, r, g, b, 180, false, true, 2, nil, nil, false)
            end
        else
            Wait(500)
        end
    end
end)

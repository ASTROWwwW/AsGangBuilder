Gang = {}
Gang.__index = Gang

function Gang:new(name, label)
    local self = setmetatable({}, Gang)
    self.name = name
    self.label = label
    self.grades = {}
    self.boss = {x = 0.0, y = 0.0, z = 0.0}
    self.coffre = {x = 0.0, y = 0.0, z = 0.0}
    return self
end


function Gang:setBossPos(coords)
    self.boss = coords
end

function Gang:getData()
    return {
        name = self.name,
        label = self.label,
        grades = self.grades,
        boss = self.boss,
        coffre = self.coffre
    }
end


function Gang:setCoffre(coords)
    self.coffre = coords
end

function Gang:addGrade(name, label, level)
    table.insert(self.grades, {
        name = name,
        label = label,
        level = tonumber(level) or 0
    })
end




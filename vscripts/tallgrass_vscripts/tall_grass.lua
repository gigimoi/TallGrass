local grass_areas = {}
function enter_grass(trigger)
    if trigger.activator.bush_caller == nil then
        trigger.activator.bush_caller = trigger.caller
        if grass_areas[trigger.caller:GetEntityIndex()] == nil then
            grass_areas[trigger.caller:GetEntityIndex()] = { }
        end
        local grass_area = grass_areas[trigger.caller:GetEntityIndex()]
        grass_area[trigger.activator] = true
        if not trigger.activator:HasAbility("ability_tallgrass_ability") then
            trigger.activator:AddAbility("ability_tallgrass_ability")
        end
        local ability_tallgrass_ability = trigger.activator:FindAbilityByName("ability_tallgrass_ability")
        
        local found_enemies = false
        for unit, in_bush in pairs(grass_area) do
            if not unit:IsNull() and in_bush then
                if unit:GetTeam() ~= trigger.activator:GetTeam() then
                    unit:RemoveModifierByName("modifier_bush_invisible")
                    ability_tallgrass_ability:ApplyDataDrivenModifier(unit, unit, "modifier_bush_invisible_revealed", {})
                    found_enemies = true
                end
            end
        end
        if not found_enemies then
            ability_tallgrass_ability:ApplyDataDrivenModifier(trigger.activator, trigger.activator, "modifier_bush_invisible", { })
        else
            ability_tallgrass_ability:ApplyDataDrivenModifier(trigger.activator, trigger.activator, "modifier_bush_invisible_revealed", { })
        end
        trigger.activator.in_bush = true

        local revealers = init_revealer_group(trigger.activator:GetAbsOrigin())
        Timers:CreateTimer(function()
            trigger.activator.bush_caller = nil
            if trigger.activator:IsNull() then
                return
            end
            if trigger.activator.in_bush then
                for k, v in ipairs(revealers) do
                    Timers:CreateTimer(RandomFloat(0, 0.2), function()
                        if trigger.activator:IsNull() then
                            return
                        end
                        AddFOWViewer(trigger.activator:GetTeamNumber(), v, trigger.activator:GetCurrentVisionRange() - (trigger.activator:GetAbsOrigin() - v):Length2D(), 1 / 4, true)
                    end)
                end
                return 1 / 10
            end
            return 
        end)
    end
end
_G["existing_revealer_groups"] = { }
function init_revealer_group(position)
    if existing_revealer_groups[position] ~= nil then
        return existing_revealer_groups[position]
    end
    local revealers = { }
    local ents = Entities:FindAllInSphere(position, 240)
    for k, ent in ipairs(ents) do
        if string.match(ent:GetName(), "bush_fow_revealer") then
            revealers[#revealers + 1] = ent:GetAbsOrigin()
        end
    end
    local revealers = build_revealer_group(revealers)
    for k, v in ipairs(revealers) do
        existing_revealer_groups[v] = revealers
    end
    return revealers
end
_G["init_revealer_group"] = init_revealer_group
function build_revealer_group(revealers) 
    local initial_group_size = #revealers
    for k, v in ipairs(revealers) do
        local ents = Entities:FindAllInSphere(v, 240)
        for k, ent in ipairs(ents) do
            if string.match(ent:GetName(), "bush_fow_revealer") then
                if not tall_grass_table_contains(revealers, ent:GetAbsOrigin()) then
                    revealers[#revealers + 1] = ent:GetAbsOrigin()
                end
            end
        end
    end
    if #revealers == initial_group_size or #revealers > 100 then
        return revealers 
    else
        return build_revealer_group(revealers)
    end
end

function exit_grass(trigger)
    if trigger.activator.bush_caller == nil then
        trigger.activator.bush_caller = trigger.caller
        if not trigger.activator:HasAbility("ability_tallgrass_ability") then
            trigger.activator:AddAbility("ability_tallgrass_ability")
        end
        local ability_tallgrass_ability = trigger.activator:FindAbilityByName("ability_tallgrass_ability")

        local grass_area = grass_areas[trigger.caller:GetEntityIndex()]
        if grass_area == nil then return end
        grass_area[trigger.activator] = false
        
        local friendly_team_in_bush = false
        for unit, in_bush in pairs(grass_area) do
            if not unit:IsNull() and in_bush then
                if unit:GetTeam() == trigger.activator:GetTeam() then
                    friendly_team_in_bush = true
                    break
                end
            end
        end
        if not friendly_team_in_bush then
            for unit, in_bush in pairs(grass_area) do
                if not unit:IsNull() and in_bush then
                    if unit:GetTeam() ~= trigger.activator:GetTeam() then
                        ability_tallgrass_ability:ApplyDataDrivenModifier(unit, unit, "modifier_bush_invisible", { })
                        unit:RemoveModifierByName("modifier_bush_invisible_revealed")
                        found_enemies = true
                    end
                end
            end
        end
        
        trigger.activator:RemoveModifierByName("modifier_bush_invisible")
        trigger.activator:RemoveModifierByName("modifier_bush_invisible_revealed")

        trigger.activator.in_bush = false
    end
end

function unit_attack(event)
    local caster = event.caster
    local target = event.target
    local attacker = event.attacker

    if not caster:HasAbility("ability_tallgrass_ability") then
        caster:AddAbility("ability_tallgrass_ability")
    end
    local ability_tallgrass_ability = attacker:FindAbilityByName("ability_tallgrass_ability")
    ability_tallgrass_ability:ApplyDataDrivenModifier(attacker, attacker, "modifier_bush_invisible_revealed", {})
    attacker:RemoveModifierByName("modifier_bush_invisible")

    Timers:CreateTimer(0.75, function()
        if attacker.in_bush then
            ability_tallgrass_ability:ApplyDataDrivenModifier(attacker, attacker, "modifier_bush_invisible", {})
            attacker:RemoveModifierByName("modifier_bush_invisible_revealed")
        end
    end)
end

function tall_grass_table_contains(table, value)
    for k, v in pairs(table) do
        if value == v then
            return true
        end
    end
    return false
end

local fow_revealers = Entities:FindAllByModel("models/props_gameplay/rune_invisibility01.vmdl")
for k, revealer in ipairs(fow_revealers) do
    if(string.match(revealer:GetName(), "bush_fow_revealer")) then
        revealer:SetModel("models/development/invisiblebox.vmdl")
    end
end
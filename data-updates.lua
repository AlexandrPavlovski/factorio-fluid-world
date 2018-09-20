function fw.deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == "table" then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[fw.deepcopy(orig_key)] = fw.deepcopy(orig_value)
        end
        setmetatable(copy, fw.deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function fw.is_item_convertable(item)
    for _, flag in pairs(item.flags) do
        if flag == "hidden" then
            return false
        end
    end

    if item.subgroup == "fill-barrel" then
        return false
    end

    --exclude ores
    if fw.items_that_should_not_be_converted[item.name] == 1 then
        return false
    end

    return true
end

function fw.is_recipe_convertable(item)
    return true
end

function fw.does_item_should_have_solid_variant(item)
    for _, solid in pairs(fw.prototypes_with_solid_variant) do
        if solid.name == item.name or solid.type == item.type then
            return true
        end
    end
    return false
end

function fw.fluidify_item(item)
    item.type = "fluid"
    item.default_temperature = 25
    item.heat_capacity = "0.1KJ"
    item.base_color = {r = 0, g = 0, b = 0}
    item.flow_color = {r = 0, g = 0, b = 0}
    item.max_temperature = 100
    item.pressure_to_speed_ratio = 0.4
    item.flow_to_energy_ratio = 0.59
    item.order = "a[fluid]-b[" .. item.name .. "]"
end

function fw.fluidify_recipe(item)
    local recipe = data.raw["recipe"][item.name]
    -- if recipe == nil then
    --     print(item.name)
    -- end
    if recipe ~= nil and recipe.category ~= "solidifying" then
        if recipe.category == nil or recipe.category == "crafting" then
            recipe.category = "fluid-crafting"
        else
            recipe.category = "fluid-" .. recipe.category
        end

        local ingredients = recipe.ingredients
        if ingredients == nil then
            ingredients = recipe.normal.ingredients
            recipe.ingredients = recipe.normal.ingredients
        end
        for _, ingredient in pairs(ingredients) do
            if ingredient.type ~= "fluid" then
                local ing_name, ing_amount
                -- print(serpent.block(ingredient))
                if ingredient.type == nil then
                    ing_name = ingredient[1]
                    ing_amount = ingredient[2]
                else
                    ing_name = ingredient.name
                    ing_amount = ingredient.amount
                end

                if fw.items_that_should_not_be_converted[ing_name] ~= 1 then                    
                    -- print(ing_name .. " - " .. serpent.block(ingredient))
                    ingredient = {type = "fluid", name = ing_name, amount = ing_amount * 10}
                end
            end
        end

        local results = recipe.results
        if results == nil and recipe.normal ~= nil then
            results = recipe.normal.results
        end
        if results ~= nil then
            for _, result in pairs(results) do
                if result.type ~= "fluid" then
                    local res_name, res_amount
                    if result.type == nil then
                        res_name = result[1]
                        res_amount = result[2]
                    else
                        res_name = result.name
                        res_amount = result.amount
                    end

                    if fw.items_that_should_not_be_converted[res_name] ~= 1 then
                        result = {type = "fluid", name = res_name, amount = res_amount * 10}
                    end
                end
            end
        else
            local res = recipe.result
            if res == nil then
                res = recipe.normal.result
            end
            if res.type ~= "fluid" then
                local result_count = recipe.result_count
                if result_count == nil and recipe.normal ~= nil then
                    result_count = recipe.normal.result_count
                end
                if result_count == nil then
                    result_count = 1
                end
                
                recipe.results = {{type = "fluid", name = res, amount = result_count * 10}}
                recipe.result = nil
                recipe.result_count = nil
                recipe.normal = nil
                recipe.expensive = nil
            end
        end

        -- if recipe.name == "steam-engine" then 
        --     print("!!! - " .. serpent.block(recipe))
        -- end
    end
end

function fw.change_solid_item_recipe(item)
    local recipe = data.raw["recipe"][item.name]
    if recipe ~= nil then
        recipe.category = "solidifying"
        recipe.ingredients = {{type = "fluid", name = item.name, amount = 10}}
        recipe.results = {{type = "item", name = item.name, amount = 1}}
    end
end

function fw.log(item, item_name, message)
    if item.name == item_name then
        print(message)
    end
end

function fw.convert_item(item)
    if fw.is_item_convertable(item) then
        -- print(item.name)
        local new_item = fw.deepcopy(item)
        fw.fluidify_item(new_item)
        data:extend({new_item})

        if fw.does_item_should_have_solid_variant(item) then
            fw.change_solid_item_recipe(item)
        end

        -- else
        --     fw.log(item, "flamethrower-turret", "6")
        --     fw.fluidify_item(item)
        --     fw.log(item, "flamethrower-turret", "7")
        -- end

        fw.fluidify_recipe(item)
    end
end

function fw.start_converting()
    for _, type in pairs(fw.types_to_convert) do
        for _, item in pairs(data.raw[type.type]) do
            fw.convert_item(item)
        end
    end
end

fw.start_converting()
-- error("STOP")

-- for _, recipe in pairs(data.raw["recipe"]) do
--     if fw.is_recipe_convertable(item) then
--         local new_fluid_recipe = {
--         }
--         data:extend({new_fluid_recipe})
--     end
-- end

-- local x = {}
-- local y = deepcopy(x)

-- data:extend(
--     {
--         {
--             type = "recipe",
--             name = "iron-chest",
--             category = "fluid-crafting",
--             --enabled = false,
--             --energy_required = 5,
--             ingredients = {
--                 {type = "fluid", name = "iron-plate", amount = 8}
--             },
--             results = {
--                 {type = "fluid", name = "iron-chest", amount = 1}
--             },
--             --icon = "__base__/graphics/icons/fluid/basic-oil-processing.png",
--             --subgroup = "fluid-recipes",
--             order = "a[oil-processing]-a[iron-chest]"
--         },
--         {
--             type = "recipe",
--             name = "iron-plate",
--             category = "fluid-smelting",
--             energy_required = 3.5,
--             ingredients = {{"iron-ore", 1}},
--             results = {{type = "fluid", name = "iron-plate", amount = 1}}
--         }
--     }
-- )

-- local new_stone_furnace = data.raw["furnace"]["stone-furnace"]
-- new_stone_furnace.collision_box = {{-0.7, -0.7}, {0.7, 0.7}}
-- new_stone_furnace.selection_box = {{-1, -1}, {1, 1}}
-- new_stone_furnace.crafting_categories = {"fluid-smelting"}
-- new_stone_furnace.fluid_boxes = {
--     {
--         production_type = "output",
--         base_area = 1,
--         base_level = 1,
--         pipe_covers = pipecoverspictures(),
--         pipe_connections = {{position = {-0.5, -1.5}}}
--     }
-- }

-- local new_burner_mining_drill = data.raw["mining-drill"]["burner-mining-drill"]
-- new_burner_mining_drill.resource_categories = {"basic-fluid"}
-- new_burner_mining_drill.collision_box = {{-1.1, -1.1}, {1.1, 1.1}}
-- new_burner_mining_drill.selection_box = {{-1.2, -1.2}, {1.2, 1.2}}
-- new_burner_mining_drill.vector_to_place_result = {0, 0}
-- new_burner_mining_drill.output_fluid_box = {
--     production_type = "output",
--     base_area = 1,
--     base_level = 1,
--     pipe_covers = pipecoverspictures(),
--     pipe_connections = {{position = {-1, -2}}}
-- }
-- new_burner_mining_drill.input_fluid_box = {
--     production_type = "input-output",
--     base_area = 10,
--     height = 2,
--     base_level = -1,
--     pipe_picture = assembler2pipepictures(),
--     pipe_covers = pipecoverspictures(),
--     pipe_connections = {{ position = {-1, 2}}}
-- }

-- local new_coal = data.raw["resource"]["coal"]
-- new_coal.mining_particle = nil
-- new_coal.category = "basic-fluid"
-- new_coal.minable.result = nil
-- new_coal.minable.results = {
--     {
--         type = "fluid",
--         name = "coal",
--         amount_min = 10,
--         amount_max = 10,
--         probability = 1
--     }
-- }
-- new_coal.minable.required_fluid = "coal"

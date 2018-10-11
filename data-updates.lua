function fw.is_item_convertable(item)
    for _, flag in pairs(item.flags) do
        if flag == "hidden" then
            return false
        end
    end

    if item.subgroup == "fill-barrel" then
        return false
    end

    if fw.items_that_should_not_be_converted[item.name] then
        return false
    end

    return true
end

function fw.is_recipe_convertable(item)
    return true
end

function fw.should_item_have_solid_variant(item)
    for _, solid in pairs(fw.prototypes_with_solid_variant) do
        if solid.name == item.name or solid.type == item.type then
            if solid.except ~= nil then
                for _, exc in pairs(solid.except) do
                    if exc == item.name then
                        return false
                    end
                end
            end
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
    item.subgroup = "fluid-" .. item.subgroup
    item.icons = {
        {icon = item.icon},
        {icon = "__fluidworld__/graphics/icons/fluid-overlay.png"}
    }
    item.icon = nil
end

function fw.fluidify_recipe(name)
    local recipe = data.raw["recipe"][name]
    -- if recipe == nil then
    --     print(item.name)
    -- end
    if recipe ~= nil and recipe.category ~= "solidifying" then
        if recipe.category == nil or recipe.category == "crafting" then
            recipe.category = "fluid-crafting"
        else
            recipe.category = "fluid-" .. recipe.category
        end

        local enabled = recipe.enabled
        if enabled == nil and recipe.normal ~= nil then
            enabled = recipe.normal.enabled
        end
        recipe.enabled = enabled

        local energy = recipe.energy_required
        if energy == nil and recipe.normal ~= nil then
            energy = recipe.normal.energy_required
        end
        recipe.energy_required = energy

        local ingredients = recipe.ingredients
        if ingredients == nil then
            ingredients = recipe.normal.ingredients
            recipe.ingredients = recipe.normal.ingredients
        end
        for key, ingredient in pairs(ingredients) do
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

                if fw.items_that_should_not_be_converted[ing_name] ~= true then
                    -- print(ing_name .. " - " .. serpent.block(ingredient))
                    ingredients[key] = {type = "fluid", name = ing_name, amount = ing_amount * 10}
                end
            end
        end

        local results = recipe.results
        if results == nil and recipe.normal ~= nil then
            results = recipe.normal.results
        end
        if results ~= nil then
            for key, result in pairs(results) do
                if result.type ~= "fluid" then
                    local res_name, res_amount
                    if result.type == nil then
                        res_name = result[1]
                        res_amount = result[2]
                    else
                        res_name = result.name
                        res_amount = result.amount
                    end

                    if res_amount == nil then
                        results[key] = {
                            type = "fluid",
                            name = result.name,
                            probability = result.probability,
                            amount = result.amount * 10
                        }
                    elseif fw.items_that_should_not_be_converted[res_name] ~= true then
                        results[key] = {type = "fluid", name = res_name, amount = res_amount * 10}
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

    -- if recipe.name == "sulfuric-acid" then
    --     print("!!! - " .. serpent.block(recipe))
    -- end
    end
end

function fw.add_solidify_recipe(item)
    local recipe = data.raw["recipe"][item.name]
    if recipe ~= nil then
        local solid_recipe = util.table.deepcopy(recipe)
        solid_recipe.name = "solid-" .. item.name
        solid_recipe.category = "solidifying"
        solid_recipe.ingredients = {{type = "fluid", name = item.name, amount = 10}}
        solid_recipe.results = {{type = "item", name = item.name, amount = 1}}
        data:extend({solid_recipe})
    end
end

function fw.convert_item(item)
    if fw.is_item_convertable(item) then
        local new_item = util.table.deepcopy(item)
        fw.fluidify_item(new_item)
        data:extend({new_item})

        fw.fluidify_recipe(item.name)

        if fw.should_item_have_solid_variant(item) then
            fw.add_solidify_recipe(item)
        end

    -- else
    --     fw.log(item, "flamethrower-turret", "6")
    --     fw.fluidify_item(item)
    --     fw.log(item, "flamethrower-turret", "7")
    -- end
    end
end

function fw.update_technologies()
    for _, tech in pairs(data.raw["technology"]) do
        if tech.effects ~= nil then
            local new_effects = {}
            local added = false
            for _, effect in pairs(tech.effects) do
                if effect.type == "unlock-recipe" and data.raw["recipe"]["solid-" .. effect.recipe] ~= nil then
                    new_effects[#new_effects + 1] = {
                        type = "unlock-recipe",
                        recipe = "solid-" .. effect.recipe
                    }
                    added = true
                end
            end
            if added then
                for _, new in pairs(new_effects) do
                    tech.effects[#tech.effects + 1] = new
                end
            end
        end
    end
end

function fw.update_assemblers()
    local am1 = data.raw["assembling-machine"]["assembling-machine-1"]
    am1.crafting_categories = {"fluid-crafting"}
    am1.fluid_boxes = {
        {
            production_type = "input",
            pipe_picture = assembler2pipepictures(),
            pipe_covers = pipecoverspictures(),
            base_area = 10,
            base_level = -1,
            pipe_connections = {{type = "input", position = {1, -2}}}
        },
        {
            production_type = "input",
            pipe_picture = assembler2pipepictures(),
            pipe_covers = pipecoverspictures(),
            base_area = 10,
            base_level = -1,
            pipe_connections = {{type = "input", position = {-1, -2}}}
        },
        {
            production_type = "output",
            pipe_picture = assembler2pipepictures(),
            pipe_covers = pipecoverspictures(),
            base_area = 10,
            base_level = 1,
            pipe_connections = {{type = "output", position = {0, 2}}}
        }
    }

    local am2 = data.raw["assembling-machine"]["assembling-machine-2"]
    am2.crafting_categories = {"fluid-crafting", "fluid-advanced-crafting", "fluid-crafting-with-fluid"}
    am2.fluid_boxes = {
        {
            production_type = "input",
            pipe_picture = assembler2pipepictures(),
            pipe_covers = pipecoverspictures(),
            base_area = 10,
            base_level = -1,
            pipe_connections = {{type = "input", position = {1, -2}}}
        },
        {
            production_type = "input",
            pipe_picture = assembler2pipepictures(),
            pipe_covers = pipecoverspictures(),
            base_area = 10,
            base_level = -1,
            pipe_connections = {{type = "input", position = {-1, -2}}}
        },
        {
            production_type = "input",
            pipe_picture = assembler2pipepictures(),
            pipe_covers = pipecoverspictures(),
            base_area = 10,
            base_level = -1,
            pipe_connections = {{type = "input", position = {2, 0}}}
        },
        {
            production_type = "input",
            pipe_picture = assembler2pipepictures(),
            pipe_covers = pipecoverspictures(),
            base_area = 10,
            base_level = -1,
            pipe_connections = {{type = "input", position = {-2, 0}}}
        },
        {
            production_type = "output",
            pipe_picture = assembler2pipepictures(),
            pipe_covers = pipecoverspictures(),
            base_area = 10,
            base_level = 1,
            pipe_connections = {{type = "output", position = {0, 2}}}
        }
    }

    local am3 = data.raw["assembling-machine"]["assembling-machine-3"]
    am3.crafting_categories = {"fluid-crafting", "fluid-advanced-crafting", "fluid-crafting-with-fluid"}
    am3.fluid_boxes = {
        {
            production_type = "input",
            pipe_picture = assembler2pipepictures(),
            pipe_covers = pipecoverspictures(),
            base_area = 10,
            base_level = -1,
            pipe_connections = {{type = "input", position = {1, -2}}}
        },
        {
            production_type = "input",
            pipe_picture = assembler2pipepictures(),
            pipe_covers = pipecoverspictures(),
            base_area = 10,
            base_level = -1,
            pipe_connections = {{type = "input", position = {-1, -2}}}
        },
        {
            production_type = "input",
            pipe_picture = assembler2pipepictures(),
            pipe_covers = pipecoverspictures(),
            base_area = 10,
            base_level = -1,
            pipe_connections = {{type = "input", position = {2, 1}}}
        },
        {
            production_type = "input",
            pipe_picture = assembler2pipepictures(),
            pipe_covers = pipecoverspictures(),
            base_area = 10,
            base_level = -1,
            pipe_connections = {{type = "input", position = {-2, 1}}}
        },
        {
            production_type = "input",
            pipe_picture = assembler2pipepictures(),
            pipe_covers = pipecoverspictures(),
            base_area = 10,
            base_level = -1,
            pipe_connections = {{type = "input", position = {2, 0}}}
        },
        {
            production_type = "input",
            pipe_picture = assembler2pipepictures(),
            pipe_covers = pipecoverspictures(),
            base_area = 10,
            base_level = -1,
            pipe_connections = {{type = "input", position = {-2, 0}}}
        },
        {
            production_type = "output",
            pipe_picture = assembler2pipepictures(),
            pipe_covers = pipecoverspictures(),
            base_area = 10,
            base_level = 1,
            pipe_connections = {{type = "output", position = {0, 2}}}
        }
    }
end

function fw.update_buildings()
    local cp = data.raw["assembling-machine"]["chemical-plant"]
    cp.crafting_categories = {"fluid-chemistry"}
    cp.fluid_boxes = {
        {
            production_type = "input",
            pipe_covers = pipecoverspictures(),
            base_area = 10,
            base_level = -1,
            pipe_connections = {{type = "input", position = {-1, -2}}}
        },
        {
            production_type = "input",
            pipe_covers = pipecoverspictures(),
            base_area = 10,
            base_level = -1,
            pipe_connections = {{type = "input", position = {1, -2}}}
        },
        {
            production_type = "input",
            pipe_covers = pipecoverspictures(),
            base_level = 1,
            pipe_connections = {{type = "input", position = {-1, 2}}}
        },
        {
            production_type = "output",
            pipe_covers = pipecoverspictures(),
            base_level = 1,
            pipe_connections = {{position = {1, 2}}}
        }
    }

    data.raw["assembling-machine"]["oil-refinery"].crafting_categories = {"fluid-oil-processing"}

    local cf = data.raw["assembling-machine"]["centrifuge"]
    cf.crafting_categories = {"fluid-centrifuging"}
    cf.fluid_boxes = {
        {
            production_type = "input",
            pipe_covers = pipecoverspictures(),
            base_area = 10,
            base_level = -1,
            pipe_connections = {{type = "input", position = {-1, -2}}}
        },
        {
            production_type = "input",
            pipe_covers = pipecoverspictures(),
            base_area = 10,
            base_level = -1,
            pipe_connections = {{type = "input", position = {1, -2}}}
        },
        {
            production_type = "output",
            pipe_covers = pipecoverspictures(),
            base_level = 1,
            pipe_connections = {{type = "output", position = {-1, 2}}}
        },
        {
            production_type = "output",
            pipe_covers = pipecoverspictures(),
            base_level = 1,
            pipe_connections = {{type = "output", position = {1, 2}}}
        }
    }
end

function fw.update_furnaces()
    local sf = data.raw["furnace"]["stone-furnace"]
    sf.crafting_categories = {"fluid-smelting"}
    sf.fluid_boxes = {
        {
            production_type = "input",
            pipe_covers = pipecoverspictures(),
            base_area = 10,
            base_level = -1,
            pipe_connections = {{type = "input", position = {0.5, 1.5}}}
        },
        {
            production_type = "output",
            pipe_covers = pipecoverspictures(),
            base_area = 10,
            base_level = 1,
            pipe_connections = {{type = "output", position = {-0.5, -1.5}}}
        }
    }

    local steelf = data.raw["furnace"]["steel-furnace"]
    steelf.crafting_categories = {"fluid-smelting"}
    steelf.fluid_boxes = {
        {
            production_type = "input",
            pipe_covers = pipecoverspictures(),
            base_area = 10,
            base_level = -1,
            pipe_connections = {{type = "input", position = {0.5, 1.5}}}
        },
        {
            production_type = "output",
            pipe_covers = pipecoverspictures(),
            base_area = 10,
            base_level = 1,
            pipe_connections = {{type = "output", position = {-0.5, -1.5}}}
        }
    }

    local elf = data.raw["furnace"]["electric-furnace"]
    elf.crafting_categories = {"fluid-smelting"}
    elf.fluid_boxes = {
        {
            production_type = "input",
            pipe_picture = assembler2pipepictures(),
            pipe_covers = pipecoverspictures(),
            base_area = 10,
            base_level = -1,
            pipe_connections = {{type = "input", position = {1, 2}}}
        },
        {
            production_type = "output",
            pipe_picture = assembler2pipepictures(),
            pipe_covers = pipecoverspictures(),
            base_area = 10,
            base_level = 1,
            pipe_connections = {{type = "output", position = {-1, -2}}}
        }
    }
end

function fw.add_solidifier()
    data:extend(
        {
            {
                type = "assembling-machine",
                name = "solidifier",
                icon = "__fluidworld__/graphics/icons/solidifier.png",
                icon_size = 32,
                flags = {"placeable-neutral", "placeable-player", "player-creation"},
                minable = {hardness = 0.2, mining_time = 0.5, result = "solidifier"},
                max_health = 400,
                corpse = "big-remnants",
                dying_explosion = "medium-explosion",
                resistances = {
                    {
                        type = "fire",
                        percent = 70
                    }
                },
                fluid_boxes = {
                    {
                        production_type = "input",
                        pipe_picture = assembler3pipepictures(),
                        pipe_covers = pipecoverspictures(),
                        base_area = 10,
                        base_level = -1,
                        pipe_connections = {{type = "input", position = {0, -2}}},
                        secondary_draw_orders = {north = -1}
                    },
                    {
                        production_type = "output",
                        pipe_picture = assembler3pipepictures(),
                        pipe_covers = pipecoverspictures(),
                        base_area = 10,
                        base_level = -1,
                        pipe_connections = {{type = "output", position = {0, 2}}}
                    },
                    off_when_no_fluid_recipe = false
                },
                open_sound = {filename = "__base__/sound/machine-open.ogg", volume = 0.85},
                close_sound = {filename = "__base__/sound/machine-close.ogg", volume = 0.75},
                vehicle_impact_sound = {filename = "__base__/sound/car-metal-impact.ogg", volume = 0.65},
                working_sound = {
                    sound = {
                        {
                            filename = "__base__/sound/assembling-machine-t3-1.ogg",
                            volume = 0.8
                        },
                        {
                            filename = "__base__/sound/assembling-machine-t3-2.ogg",
                            volume = 0.8
                        }
                    },
                    idle_sound = {filename = "__base__/sound/idle1.ogg", volume = 0.6},
                    apparent_volume = 1.5
                },
                collision_box = {{-1.2, -1.2}, {1.2, 1.2}},
                selection_box = {{-1.5, -1.5}, {1.5, 1.5}},
                fast_replaceable_group = "assembling-machine",
                animation = {
                    layers = {
                        {
                            filename = "__fluidworld__/graphics/entity/solidifier/solidifier.png",
                            priority = "high",
                            width = 108,
                            height = 119,
                            frame_count = 32,
                            line_length = 8,
                            shift = util.by_pixel(0, -0.5),
                            hr_version = {
                                filename = "__fluidworld__/graphics/entity/solidifier/hr-solidifier.png",
                                priority = "high",
                                width = 214,
                                height = 237,
                                frame_count = 32,
                                line_length = 8,
                                shift = util.by_pixel(0, -0.75),
                                scale = 0.5
                            }
                        },
                        {
                            filename = "__fluidworld__/graphics/entity/solidifier/solidifier-shadow.png",
                            priority = "high",
                            width = 130,
                            height = 82,
                            frame_count = 32,
                            line_length = 8,
                            draw_as_shadow = true,
                            shift = util.by_pixel(28, 4),
                            hr_version = {
                                filename = "__fluidworld__/graphics/entity/solidifier/hr-solidifier-shadow.png",
                                priority = "high",
                                width = 260,
                                height = 162,
                                frame_count = 32,
                                line_length = 8,
                                draw_as_shadow = true,
                                shift = util.by_pixel(28, 4),
                                scale = 0.5
                            }
                        }
                    }
                },
                crafting_categories = {"solidifying"},
                crafting_speed = 1.25,
                energy_source = {
                    type = "electric",
                    usage_priority = "secondary-input",
                    emissions = 0.03 / 3.5
                },
                energy_usage = "210kW",
                ingredient_count = 6,
                module_specification = {
                    module_slots = 4
                },
                allowed_effects = {"consumption", "speed", "productivity", "pollution"}
            },
            {
                type = "recipe",
                name = "solidifier",
                category = "fluid-crafting",
                enabled = true,
                ingredients = {
                    {type = "fluid", name = "electronic-circuit", amount = 50},
                    {type = "fluid", name = "iron-gear-wheel", amount = 50}
                },
                result = "solidifier"
            },
            {
                type = "item",
                name = "solidifier",
                icon = "__fluidworld__/graphics/icons/solidifier.png",
                icon_size = 32,
                flags = {"goes-to-quickbar"},
                subgroup = "solidifier",
                order = "a[solidifier]",
                place_result = "solidifier",
                stack_size = 50
            }
        }
    )
end

function fw.fine_tune()
    data:extend(
        {
            {
                type = "recipe",
                name = "liquify-used-up-uranium-fuel-cell",
                ingredients = {
                    {"used-up-uranium-fuel-cell", 1}
                },
                results = {
                    {type = "fluid", name = "used-up-uranium-fuel-cell", amount = 10}
                },
                category = "solidifying",
                subgroup = "intermediate-product",
                order = "r[uranium-processing]-a[used-up-uranium-fuel-cell]"
            },
            {
                type = "pipe-to-ground",
                name = "steel-pipe-to-ground",
                icon = "__fluidworld__/graphics/icons/steel-pipe-to-ground.png",
                icon_size = 32,
                flags = {"placeable-neutral", "player-creation"},
                minable = {hardness = 0.2, mining_time = 0.5, result = "steel-pipe-to-ground"},
                max_health = 150,
                corpse = "small-remnants",
                resistances = {
                    {
                        type = "fire",
                        percent = 80
                    },
                    {
                        type = "impact",
                        percent = 40
                    }
                },
                collision_box = {{-0.29, -0.29}, {0.29, 0.2}},
                selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
                fluid_box = {
                    base_area = 1,
                    pipe_covers = fw.pipecoverspictures("steel-"),
                    pipe_connections = {
                        {position = {0, -1}},
                        {
                            position = {0, 1},
                            max_underground_distance = 20
                        }
                    }
                },
                underground_sprite = {
                    filename = "__core__/graphics/arrows/underground-lines.png",
                    priority = "extra-high-no-scale",
                    width = 64,
                    height = 64,
                    scale = 0.5
                },
                vehicle_impact_sound = {filename = "__base__/sound/car-metal-impact.ogg", volume = 0.65},
                pictures = {
                    up = {
                        filename = "__fluidworld__/graphics/entity/steel-pipe-to-ground/steel-pipe-to-ground-up.png",
                        priority = "high",
                        width = 64,
                        height = 64, --, shift = {0.10, -0.04}
                        hr_version = {
                            filename = "__fluidworld__/graphics/entity/steel-pipe-to-ground/hr-steel-pipe-to-ground-up.png",
                            priority = "extra-high",
                            width = 128,
                            height = 128,
                            scale = 0.5
                        }
                    },
                    down = {
                        filename = "__fluidworld__/graphics/entity/steel-pipe-to-ground/steel-pipe-to-ground-down.png",
                        priority = "high",
                        width = 64,
                        height = 64, --, shift = {0.05, 0}
                        hr_version = {
                            filename = "__fluidworld__/graphics/entity/steel-pipe-to-ground/hr-steel-pipe-to-ground-down.png",
                            priority = "extra-high",
                            width = 128,
                            height = 128,
                            scale = 0.5
                        }
                    },
                    left = {
                        filename = "__fluidworld__/graphics/entity/steel-pipe-to-ground/steel-pipe-to-ground-left.png",
                        priority = "high",
                        width = 64,
                        height = 64, --, shift = {-0.12, 0.1}
                        hr_version = {
                            filename = "__fluidworld__/graphics/entity/steel-pipe-to-ground/hr-steel-pipe-to-ground-left.png",
                            priority = "extra-high",
                            width = 128,
                            height = 128,
                            scale = 0.5
                        }
                    },
                    right = {
                        filename = "__fluidworld__/graphics/entity/steel-pipe-to-ground/steel-pipe-to-ground-right.png",
                        priority = "high",
                        width = 64,
                        height = 64, --, shift = {0.1, 0.1}
                        hr_version = {
                            filename = "__fluidworld__/graphics/entity/steel-pipe-to-ground/hr-steel-pipe-to-ground-right.png",
                            priority = "extra-high",
                            width = 128,
                            height = 128,
                            scale = 0.5
                        }
                    }
                }
            },
            {
                type = "item",
                name = "steel-pipe-to-ground",
                icon = "__fluidworld__/graphics/icons/steel-pipe-to-ground.png",
                icon_size = 32,
                flags = {"goes-to-quickbar"},
                subgroup = "energy-pipe-distribution",
                order = "a[pipe]-ba[steel-pipe-to-ground]",
                place_result = "steel-pipe-to-ground",
                stack_size = 50
            },
            {
                type = "recipe",
                name = "steel-pipe-to-ground",
                ingredients = {
                    {type = "fluid", name = "pipe", amount = 100},
                    {type = "fluid", name = "steel-plate", amount = 50}
                },
                result_count = 2,
                result = "steel-pipe-to-ground",
                category = "fluid-crafting",
                enabled = false
            },
            {
                type = "pipe-to-ground",
                name = "plastic-pipe-to-ground",
                icon = "__fluidworld__/graphics/icons/plastic-pipe-to-ground.png",
                icon_size = 32,
                flags = {"placeable-neutral", "player-creation"},
                minable = {hardness = 0.2, mining_time = 0.5, result = "plastic-pipe-to-ground"},
                max_health = 150,
                corpse = "small-remnants",
                resistances = {
                    {
                        type = "fire",
                        percent = 80
                    },
                    {
                        type = "impact",
                        percent = 40
                    }
                },
                collision_box = {{-0.29, -0.29}, {0.29, 0.2}},
                selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
                fluid_box = {
                    base_area = 1,
                    pipe_covers = fw.pipecoverspictures("plastic-"),
                    pipe_connections = {
                        {position = {0, -1}},
                        {
                            position = {0, 1},
                            max_underground_distance = 30
                        }
                    }
                },
                underground_sprite = {
                    filename = "__core__/graphics/arrows/underground-lines.png",
                    priority = "extra-high-no-scale",
                    width = 64,
                    height = 64,
                    scale = 0.5
                },
                vehicle_impact_sound = {filename = "__base__/sound/car-metal-impact.ogg", volume = 0.65},
                pictures = {
                    up = {
                        filename = "__fluidworld__/graphics/entity/plastic-pipe-to-ground/plastic-pipe-to-ground-up.png",
                        priority = "high",
                        width = 64,
                        height = 64, --, shift = {0.10, -0.04}
                        hr_version = {
                            filename = "__fluidworld__/graphics/entity/plastic-pipe-to-ground/hr-plastic-pipe-to-ground-up.png",
                            priority = "extra-high",
                            width = 128,
                            height = 128,
                            scale = 0.5
                        }
                    },
                    down = {
                        filename = "__fluidworld__/graphics/entity/plastic-pipe-to-ground/plastic-pipe-to-ground-down.png",
                        priority = "high",
                        width = 64,
                        height = 64, --, shift = {0.05, 0}
                        hr_version = {
                            filename = "__fluidworld__/graphics/entity/plastic-pipe-to-ground/hr-plastic-pipe-to-ground-down.png",
                            priority = "extra-high",
                            width = 128,
                            height = 128,
                            scale = 0.5
                        }
                    },
                    left = {
                        filename = "__fluidworld__/graphics/entity/plastic-pipe-to-ground/plastic-pipe-to-ground-left.png",
                        priority = "high",
                        width = 64,
                        height = 64, --, shift = {-0.12, 0.1}
                        hr_version = {
                            filename = "__fluidworld__/graphics/entity/plastic-pipe-to-ground/hr-plastic-pipe-to-ground-left.png",
                            priority = "extra-high",
                            width = 128,
                            height = 128,
                            scale = 0.5
                        }
                    },
                    right = {
                        filename = "__fluidworld__/graphics/entity/plastic-pipe-to-ground/plastic-pipe-to-ground-right.png",
                        priority = "high",
                        width = 64,
                        height = 64, --, shift = {0.1, 0.1}
                        hr_version = {
                            filename = "__fluidworld__/graphics/entity/plastic-pipe-to-ground/hr-plastic-pipe-to-ground-right.png",
                            priority = "extra-high",
                            width = 128,
                            height = 128,
                            scale = 0.5
                        }
                    }
                }
            },
            {
                type = "item",
                name = "plastic-pipe-to-ground",
                icon = "__fluidworld__/graphics/icons/plastic-pipe-to-ground.png",
                icon_size = 32,
                flags = {"goes-to-quickbar"},
                subgroup = "energy-pipe-distribution",
                order = "a[pipe]-bb[plastic-pipe-to-ground]",
                place_result = "plastic-pipe-to-ground",
                stack_size = 50
            },
            {
                type = "recipe",
                name = "plastic-pipe-to-ground",
                ingredients = {
                    {type = "fluid", name = "pipe", amount = 100},
                    {type = "fluid", name = "plastic-bar", amount = 50}
                },
                result_count = 2,
                result = "plastic-pipe-to-ground",
                category = "fluid-crafting",
                enabled = false
            }
        }
    )
    local ef = data.raw["technology"]["nuclear-fuel-reprocessing"].effects
    ef[#ef + 1] = {
        type = "unlock-recipe",
        recipe = "liquify-used-up-uranium-fuel-cell"
    }
    local sp = data.raw["technology"]["steel-processing"].effects
    sp[#sp + 1] = {
        type = "unlock-recipe",
        recipe = "steel-pipe-to-ground"
    }
    local p = data.raw["technology"]["plastics"].effects
    p[#p + 1] = {
        type = "unlock-recipe",
        recipe = "plastic-pipe-to-ground"
    }
end

function fw.pipecoverspictures(name)
    return {
        north = {
            layers = {
                {
                    filename = "__fluidworld__/graphics/entity/pipe-covers/" .. name .. "pipe-cover-north.png",
                    priority = "extra-high",
                    width = 64,
                    height = 64,
                    hr_version = {
                        filename = "__fluidworld__/graphics/entity/pipe-covers/hr-" .. name .. "pipe-cover-north.png",
                        priority = "extra-high",
                        width = 128,
                        height = 128,
                        scale = 0.5
                    }
                },
                {
                    filename = "__fluidworld__/graphics/entity/pipe-covers/" .. name .. "pipe-cover-north-shadow.png",
                    priority = "extra-high",
                    width = 64,
                    height = 64,
                    draw_as_shadow = true,
                    hr_version = {
                        filename = "__fluidworld__/graphics/entity/pipe-covers/hr-" ..
                            name .. "pipe-cover-north-shadow.png",
                        priority = "extra-high",
                        width = 128,
                        height = 128,
                        scale = 0.5,
                        draw_as_shadow = true
                    }
                }
            }
        },
        east = {
            layers = {
                {
                    filename = "__fluidworld__/graphics/entity/pipe-covers/" .. name .. "pipe-cover-east.png",
                    priority = "extra-high",
                    width = 64,
                    height = 64,
                    hr_version = {
                        filename = "__fluidworld__/graphics/entity/pipe-covers/hr-" .. name .. "pipe-cover-east.png",
                        priority = "extra-high",
                        width = 128,
                        height = 128,
                        scale = 0.5
                    }
                },
                {
                    filename = "__fluidworld__/graphics/entity/pipe-covers/" .. name .. "pipe-cover-east-shadow.png",
                    priority = "extra-high",
                    width = 64,
                    height = 64,
                    draw_as_shadow = true,
                    hr_version = {
                        filename = "__fluidworld__/graphics/entity/pipe-covers/hr-" ..
                            name .. "pipe-cover-east-shadow.png",
                        priority = "extra-high",
                        width = 128,
                        height = 128,
                        scale = 0.5,
                        draw_as_shadow = true
                    }
                }
            }
        },
        south = {
            layers = {
                {
                    filename = "__fluidworld__/graphics/entity/pipe-covers/" .. name .. "pipe-cover-south.png",
                    priority = "extra-high",
                    width = 64,
                    height = 64,
                    hr_version = {
                        filename = "__fluidworld__/graphics/entity/pipe-covers/hr-" .. name .. "pipe-cover-south.png",
                        priority = "extra-high",
                        width = 128,
                        height = 128,
                        scale = 0.5
                    }
                },
                {
                    filename = "__fluidworld__/graphics/entity/pipe-covers/" .. name .. "pipe-cover-south-shadow.png",
                    priority = "extra-high",
                    width = 64,
                    height = 64,
                    draw_as_shadow = true,
                    hr_version = {
                        filename = "__fluidworld__/graphics/entity/pipe-covers/hr-" ..
                            name .. "pipe-cover-south-shadow.png",
                        priority = "extra-high",
                        width = 128,
                        height = 128,
                        scale = 0.5,
                        draw_as_shadow = true
                    }
                }
            }
        },
        west = {
            layers = {
                {
                    filename = "__fluidworld__/graphics/entity/pipe-covers/" .. name .. "pipe-cover-west.png",
                    priority = "extra-high",
                    width = 64,
                    height = 64,
                    hr_version = {
                        filename = "__fluidworld__/graphics/entity/pipe-covers/hr-" .. name .. "pipe-cover-west.png",
                        priority = "extra-high",
                        width = 128,
                        height = 128,
                        scale = 0.5
                    }
                },
                {
                    filename = "__fluidworld__/graphics/entity/pipe-covers/" .. name .. "pipe-cover-west-shadow.png",
                    priority = "extra-high",
                    width = 64,
                    height = 64,
                    draw_as_shadow = true,
                    hr_version = {
                        filename = "__fluidworld__/graphics/entity/pipe-covers/hr-" ..
                            name .. "pipe-cover-west-shadow.png",
                        priority = "extra-high",
                        width = 128,
                        height = 128,
                        scale = 0.5,
                        draw_as_shadow = true
                    }
                }
            }
        }
    }
end

function fw.start_converting()
    for _, type in pairs(fw.types_to_convert) do
        for _, item in pairs(data.raw[type.type]) do
            fw.convert_item(item)
        end
    end

    for _, rec in pairs(fw.additional_recipies_to_convert) do
        fw.fluidify_recipe(rec)
    end

    fw.update_technologies()

    fw.update_assemblers()
    fw.update_buildings()
    fw.update_furnaces()

    fw.add_solidifier()

    fw.fine_tune()
end

fw.start_converting()
if not fw then
    fw = {}
end

require("prototypes.categories")

fw.items_that_should_not_be_converted = {
    ["coal"] = true,
    ["uranium-ore"] = true,
    ["copper-ore"] = true,
    ["iron-ore"] = true,
    ["stone"] = true,
    ["wood"] = true,
    ["wooden-chest"] = true
}
fw.types_to_convert = {
    {
        type = "item"
    },
    {
        type = "tool"
    },
    {
        type = "ammo"
    },
    {
        type = "armor"
    },
    {
        type = "capsule"
    },
    {
        type = "item-with-entity-data"
    },
    {
        type = "mining-tool"
    },
    {
        type = "repair-tool"
    },
    {
        type = "gun"
    },
    {
        type = "module"
    },
    {
        type = "rail-planner"
    }
}

fw.additional_recipies_to_convert = {
    "basic-oil-processing",
    "advanced-oil-processing",
    "coal-liquefaction",
    "sulfuric-acid",
    "heavy-oil-cracking",
    "light-oil-cracking",
    "solid-fuel-from-light-oil",
    "solid-fuel-from-petroleum-gas",
    "solid-fuel-from-heavy-oil",
    "lubricant",
    "uranium-processing",
    "kovarex-enrichment-process",
    "nuclear-fuel-reprocessing",
}

fw.prototypes_with_solid_variant = {
    {
        name = "rail"
    },
    {
        type = "item",
        except = {
            "iron-plate",
            "copper-plate",
            "steel-plate",
            "sulfur",
            "plastic-bar",
            "iron-stick",
            "iron-gear-wheel",
            "electronic-circuit",
            "advanced-circuit",
            "processing-unit",
            "engine-unit",
            "electric-engine-unit",
            "battery",
            "explosives",
            "flying-robot-frame",
            "uranium-235",
            "uranium-238",
        }
    },
    {
        type = "ammo"
    },
    {
        type = "armor"
    },
    {
        type = "item-with-entity-data"
    },
    {
        type = "capsule"
    },
    {
        type = "mining-tool"
    },
    {
        type = "repair-tool"
    },
    {
        type = "gun"
    },
    {
        type = "module"
    },
    {
        type = "tool"
    },
}

data.raw["recipe"]["cliff-explosives"].ingredients =
{
	{"explosives", 10},
	{"grenade", 1},
	{"iron-plate", 10}
}
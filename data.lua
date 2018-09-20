-- solid-fuel
-- uranium-235
-- uranium-238
-- used-up-uranium-fuel-cell
-- space-science-pack

if not fw then fw = {} end

require("prototypes.categories")

fw.items_that_should_not_be_converted = {
    ["coal"] = 1,
    ["uranium-ore"] = 1,
    ["copper-ore"] = 1,
    ["iron-ore"] = 1,
    ["stone"] = 1
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
    },
}
fw.prototypes_with_solid_variant = {
    {
        name = "iron-chest"
    },
    {
        name = "stone-furnace"
    },
    {
        name = "assembling-machine-3"
    },
    {
        name = "chemical-plant"
    },
    {
        name = "oil-refinery"
    },
    {
        name = ""
    },
    {
        name = "rail"
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
}
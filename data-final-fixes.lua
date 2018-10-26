local tfh = data.raw["technology"]["fluid-handling"].effects
tfh[#tfh + 1] = {
    type = "unlock-recipe",
    recipe = "solid-storage-tank"
}

data:extend({
    {
        type = "recipe",
        name = "solid-solid-fuel",
        category = "solidifying",
        energy_required = 3,
        ingredients = {{type = "fluid", name = "solid-fuel", amount = 10 }},
        results = {{type = "item", name = "solid-fuel", amount = 1 }},
        icon = "__base__/graphics/icons/solid-fuel.png",
        icon_size = 32,
        subgroup = "intermediate-product",
        enabled = false,
        order = "b[m]",
        crafting_machine_tint =
        {
            primary = {r = 0.270, g = 0.122, b = 0.000, a = 0.000}, -- #441f0000
            secondary = {r = 0.735, g = 0.546, b = 0.325, a = 0.000}, -- #bb8b5200
            tertiary = {r = 0.610, g = 0.348, b = 0.000, a = 0.000}, -- #9b580000
        }
    }
})

local top = data.raw["technology"]["oil-processing"].effects
top[#top + 1] = {
    type = "unlock-recipe",
    recipe = "solid-solid-fuel"
}

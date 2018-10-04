function fw.add_categories()
    local new_categories = {}
    for _, category in pairs(data.raw["recipe-category"]) do
        new_categories[#new_categories + 1] = {
            type = "recipe-category",
            name = "fluid-" .. category.name
        }
    end
    data:extend(new_categories)
end

function fw.add_subgroups()
    local new_subgroups = {}
    for _, sg in pairs(data.raw["item-subgroup"]) do
        new_subgroups[#new_subgroups + 1] = {
            type = "item-subgroup",
            name = "fluid-" .. sg.name,
            group = sg.group,
            order = sg.order .. "a"
        }
    end
    data:extend(new_subgroups)
end

fw.add_categories()
fw.add_subgroups()

data:extend(
    {
        --RECIPE CATEGORIES
        {
            type = "recipe-category",
            name = "solidifying"
        },
        --SUBGROUPS
        {
            type = "item-subgroup",
            name = "solidifier",
            group = "production",
            order = "da"
        }
    }
)

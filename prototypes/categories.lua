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

fw.add_categories()

data:extend(
    {
        --RECIPE CATEGORIES
        {
            type = "recipe-category",
            name = "solidifying"
        }
        --SUBGROUPS
    }
)

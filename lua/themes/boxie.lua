local boxie_theme = {}

boxie_theme.base_30 = {
    white = "#CFD2FF",
    darker_black = "#0A0A14",
    black = "#0A0A14",
    black2 = "#0E0E1C",
    one_bg = "#0E0E1C",
    one_bg2 = "#191932",
    one_bg3 = "#2A3340",
    grey = "#2A3340",
    grey_fg = "#40405A",
    grey_fg2 = "#4D576B",
    light_grey = "#6E7A8A",
    red = "#C83232",
    baby_pink = "#FF7A5A",
    pink = "#FF7A5A",
    line = "#191932",
    green = "#75BA8E",
    vibrant_green = "#C8D8B0",
    nord_blue = "#8FB0FF",
    blue = "#3D6CFF",
    yellow = "#FFC24A",
    sun = "#FFC24A",
    purple = "#5000FF",
    dark_purple = "#3200A0",
    teal = "#75BA8E",
    orange = "#FF7A5A",
    cyan = "#8FB0FF",
    statusline_bg = "#0E0E1C",
    lightbg = "#191932",
    pmenu_bg = "#3D6CFF",
    folder_bg = "#8FB0FF",
}

boxie_theme.base_16 = {
    base00 = "#0A0A14",
    base01 = "#0E0E1C",
    base02 = "#191932",
    base03 = "#6E7A8A",
    base04 = "#4D576B",
    base05 = "#CFD2FF",
    base06 = "#EAF0FF",
    base07 = "#FFFFFF",
    base08 = "#75BA8E",
    base09 = "#3D6CFF",
    base0A = "#75BA8E",
    base0B = "#3D6CFF",
    base0C = "#3D6CFF",
    base0D = "#75BA8E",
    base0E = "#75BA8E",
    base0F = "#C83232",
}

boxie_theme.polish_hl = {
    defaults = {
        Comment = { fg = "#6E7A8A", italic = true },
        Cursor = { fg = "#0A0A14", bg = "#75BA8E" },
        lCursor = { fg = "#0A0A14", bg = "#75BA8E" },
        CursorLine = { bg = "#0E0E1C" },
        Visual = { bg = "#191932" },
        Search = { fg = "#0A0A14", bg = "#FFC24A" },
        IncSearch = { fg = "#0A0A14", bg = "#FF7A5A" },
        WinSeparator = { fg = "#3200A0" },
        FloatBorder = { fg = "#3200A0" },
    },
    treesitter = {
        ["@label"] = { fg = "#75BA8E", bold = true },
        ["@variable"] = { fg = "#75BA8E" },
        ["@variable.builtin"] = { fg = "#75BA8E" },
        ["@keyword"] = { fg = "#75BA8E" },
        ["@keyword.directive"] = { fg = "#75BA8E" },
        ["@function"] = { fg = "#75BA8E" },
        ["@function.builtin"] = { fg = "#75BA8E" },
        ["@operator"] = { fg = "#75BA8E" },
        ["@number"] = { fg = "#3D6CFF" },
        ["@number.float"] = { fg = "#3D6CFF" },
        ["@string"] = { fg = "#3D6CFF" },
        ["@character"] = { fg = "#3D6CFF" },
        ["@boolean"] = { fg = "#3D6CFF" },
        ["@constant"] = { fg = "#3D6CFF" },
        ["@constant.builtin"] = { fg = "#3D6CFF" },
    },
}

boxie_theme.type = "dark"

boxie_theme = require("base46").override_theme(boxie_theme, "boxie")

return boxie_theme

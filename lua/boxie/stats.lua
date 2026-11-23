local err = require("boxie.err")

local boxie_stats = {
    BOXIE_STATS_DIR = "boxie",
    BOXIE_STATS_FILE = "mode_time.txt",
    BOXIE_STATS_TEMPORARY_EXT = ".tmp",
    BOXIE_STATS_DATA = "data",
    BOXIE_STATS_DAY_FMT = "!%Y-%m-%d",
    BOXIE_STATS_LN_FMT = "%s normal %d visual %d insert %d\n",
    BOXIE_STATS_LN_PATTERN = "^(%S+) normal (%d+) visual (%d+) insert (%d+)$",
    BOXIE_STATS_LN_SPLIT_PATTERN = "[^\n]+",
    BOXIE_STATS_RD_MODE = "rb",
    BOXIE_STATS_WR_MODE = "wb",
    BOXIE_STATS_RD_ALL = "a",
    BOXIE_STATS_MKDIR_PARENT = "p",
    BOXIE_STATS_FLUSH_PERIOD = 60000,
    BOXIE_STATS_VIM_TRUE = 1,
    BOXIE_STATS_MODE_FIRST = 1,
    BOXIE_STATS_EVENT_MODE = "ModeChanged",
    BOXIE_STATS_EVENT_FOCUS_LOST = "FocusLost",
    BOXIE_STATS_EVENT_FOCUS_GAINED = "FocusGained",
    BOXIE_STATS_EVENT_LEAVE = "VimLeavePre",
    BOXIE_STATS_CLASS_NONE = "",
    BOXIE_STATS_CLASS_NORMAL = "normal",
    BOXIE_STATS_CLASS_VISUAL = "visual",
    BOXIE_STATS_CLASS_INSERT = "insert",
    BOXIE_STATS_MODE_CLASS = {
        ["n"] = "normal",
        ["v"] = "visual",
        ["V"] = "visual",
        ["\22"] = "visual",
        ["s"] = "visual",
        ["S"] = "visual",
        ["\19"] = "visual",
        ["i"] = "insert",
    },
}

function boxie_stats.boxie_stats_path_get(out)
    if out == nil then return err.LDG_ERR_FUNC_ARG_NULL end

    out.dir = vim.fs.joinpath(vim.fn.stdpath(boxie_stats.BOXIE_STATS_DATA), boxie_stats.BOXIE_STATS_DIR)
    out.path = vim.fs.joinpath(out.dir, boxie_stats.BOXIE_STATS_FILE)

    return err.LDG_ERR_AOK
end

function boxie_stats.boxie_stats_class_get(mode, out)
    if mode == nil or out == nil then return err.LDG_ERR_FUNC_ARG_NULL end

    out.class = boxie_stats.BOXIE_STATS_MODE_CLASS[string.sub(mode, boxie_stats.BOXIE_STATS_MODE_FIRST, boxie_stats.BOXIE_STATS_MODE_FIRST)] or boxie_stats.BOXIE_STATS_CLASS_NONE

    return err.LDG_ERR_AOK
end

function boxie_stats.boxie_stats_text_parse(text, out)
    local date = nil
    local normal = nil
    local visual = nil
    local insert = nil

    if text == nil or out == nil then return err.LDG_ERR_FUNC_ARG_NULL end

    out.day = {}

    for ln in string.gmatch(text, boxie_stats.BOXIE_STATS_LN_SPLIT_PATTERN) do
        date, normal, visual, insert = string.match(ln, boxie_stats.BOXIE_STATS_LN_PATTERN)
        if date == nil then return err.LDG_ERR_IO_FMT end

        out.day[date] = { normal = tonumber(normal), visual = tonumber(visual), insert = tonumber(insert) }
    end

    return err.LDG_ERR_AOK
end

function boxie_stats.boxie_stats_text_fmt(day, out)
    local date = {}
    local ln = {}

    if day == nil or out == nil then return err.LDG_ERR_FUNC_ARG_NULL end

    for key in pairs(day) do
        table.insert(date, key)
    end

    table.sort(date)

    for _, key in ipairs(date) do
        table.insert(ln, string.format(boxie_stats.BOXIE_STATS_LN_FMT, key, day[key].normal or 0, day[key].visual or 0, day[key].insert or 0))
    end

    out.text = table.concat(ln)

    return err.LDG_ERR_AOK
end

function boxie_stats.boxie_stats_ld(state)
    local where = { dir = "", path = "" }
    local parsed = { day = {} }
    local file = nil
    local text = nil
    local res = 0

    if state == nil then return err.LDG_ERR_FUNC_ARG_NULL end

    state.day = {}

    res = boxie_stats.boxie_stats_path_get(where)
    if res ~= err.LDG_ERR_AOK then return res end

    if vim.uv.fs_stat(where.path) == nil then return err.LDG_ERR_AOK end

    file = io.open(where.path, boxie_stats.BOXIE_STATS_RD_MODE)
    if file == nil then return err.LDG_ERR_IO_OPEN end

    text = file:read(boxie_stats.BOXIE_STATS_RD_ALL)

    if not file:close() then return err.LDG_ERR_IO_CLOSE end

    if text == nil then return err.LDG_ERR_IO_RD end

    res = boxie_stats.boxie_stats_text_parse(text, parsed)
    if res ~= err.LDG_ERR_AOK then return res end

    state.day = parsed.day

    return err.LDG_ERR_AOK
end

function boxie_stats.boxie_stats_st(state)
    local where = { dir = "", path = "" }
    local formatted = { text = "" }
    local temporary = ""
    local file = nil
    local res = 0

    if state == nil then return err.LDG_ERR_FUNC_ARG_NULL end

    res = boxie_stats.boxie_stats_path_get(where)
    if res ~= err.LDG_ERR_AOK then return res end

    res = boxie_stats.boxie_stats_text_fmt(state.day, formatted)
    if res ~= err.LDG_ERR_AOK then return res end

    if vim.fn.isdirectory(where.dir) ~= boxie_stats.BOXIE_STATS_VIM_TRUE and vim.fn.mkdir(where.dir, boxie_stats.BOXIE_STATS_MKDIR_PARENT) ~= boxie_stats.BOXIE_STATS_VIM_TRUE then return err.LDG_ERR_IO_WR end

    temporary = where.path .. boxie_stats.BOXIE_STATS_TEMPORARY_EXT

    file = io.open(temporary, boxie_stats.BOXIE_STATS_WR_MODE)
    if file == nil then return err.LDG_ERR_IO_OPEN end

    if not file:write(formatted.text) then
        if not file:close() then return err.LDG_ERR_IO_CLOSE end

        return err.LDG_ERR_IO_WR
    end

    if not file:close() then return err.LDG_ERR_IO_CLOSE end

    if not os.rename(temporary, where.path) then return err.LDG_ERR_IO_WR end

    return err.LDG_ERR_AOK
end

function boxie_stats.boxie_stats_time_cum(state)
    local now = 0
    local date = ""

    if state == nil then return err.LDG_ERR_FUNC_ARG_NULL end

    now = vim.uv.now()

    if state.class ~= boxie_stats.BOXIE_STATS_CLASS_NONE then
        date = os.date(boxie_stats.BOXIE_STATS_DAY_FMT)

        if state.day[date] == nil then state.day[date] = { normal = 0, visual = 0, insert = 0 } end

        state.day[date][state.class] = (state.day[date][state.class] or 0) + now - state.since
    end

    state.since = now

    return err.LDG_ERR_AOK
end

function boxie_stats.boxie_stats_class_set(state, mode)
    local class = { class = "" }
    local res = 0

    if state == nil or mode == nil then return err.LDG_ERR_FUNC_ARG_NULL end

    res = boxie_stats.boxie_stats_time_cum(state)
    if res ~= err.LDG_ERR_AOK then return res end

    res = boxie_stats.boxie_stats_class_get(mode, class)
    if res ~= err.LDG_ERR_AOK then return res end

    state.class = class.class

    return err.LDG_ERR_AOK
end

function boxie_stats.boxie_stats_flush(state)
    local res = 0

    if state == nil then return err.LDG_ERR_FUNC_ARG_NULL end

    res = boxie_stats.boxie_stats_time_cum(state)
    if res ~= err.LDG_ERR_AOK then return res end

    return boxie_stats.boxie_stats_st(state)
end

function boxie_stats.boxie_stats_init(state, group)
    local timer = nil
    local res = 0

    if state == nil or group == nil then return err.LDG_ERR_FUNC_ARG_NULL end

    state.class = boxie_stats.BOXIE_STATS_CLASS_NONE
    state.since = vim.uv.now()

    if boxie_stats.boxie_stats_ld(state) ~= err.LDG_ERR_AOK then state.day = {} end

    res = boxie_stats.boxie_stats_class_set(state, vim.api.nvim_get_mode().mode)
    if res ~= err.LDG_ERR_AOK then return res end

    vim.api.nvim_create_autocmd(boxie_stats.BOXIE_STATS_EVENT_MODE, {
        group = group,
        callback = function()
            -- a truthy return deletes the autocmd
            if boxie_stats.boxie_stats_class_set(state, vim.v.event.new_mode) ~= err.LDG_ERR_AOK then return false end

            return false
        end,
    })

    vim.api.nvim_create_autocmd(boxie_stats.BOXIE_STATS_EVENT_FOCUS_LOST, {
        group = group,
        callback = function()
            if boxie_stats.boxie_stats_class_set(state, boxie_stats.BOXIE_STATS_CLASS_NONE) ~= err.LDG_ERR_AOK then return false end

            return false
        end,
    })

    vim.api.nvim_create_autocmd(boxie_stats.BOXIE_STATS_EVENT_FOCUS_GAINED, {
        group = group,
        callback = function()
            if boxie_stats.boxie_stats_class_set(state, vim.api.nvim_get_mode().mode) ~= err.LDG_ERR_AOK then return false end

            return false
        end,
    })

    vim.api.nvim_create_autocmd(boxie_stats.BOXIE_STATS_EVENT_LEAVE, {
        group = group,
        callback = function()
            if boxie_stats.boxie_stats_flush(state) ~= err.LDG_ERR_AOK then return false end

            return false
        end,
    })

    timer = vim.uv.new_timer()
    if timer == nil then return err.LDG_ERR_ALLOC_NULL end

    timer:start(
        boxie_stats.BOXIE_STATS_FLUSH_PERIOD,
        boxie_stats.BOXIE_STATS_FLUSH_PERIOD,
        vim.schedule_wrap(function()
            if boxie_stats.boxie_stats_flush(state) ~= err.LDG_ERR_AOK then return end
        end)
    )

    state.timer = timer

    return err.LDG_ERR_AOK
end

return boxie_stats

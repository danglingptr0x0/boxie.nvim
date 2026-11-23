local err = require("boxie.err")
local asm = require("boxie.asm")
local lsp = require("boxie.lsp")
local cmd = require("boxie.cmd")
local hint = require("boxie.hint")
local notify = require("boxie.notify")
local crosstalk = require("boxie.crosstalk")
local section = require("boxie.section")
local stats = require("boxie.stats")

local boxie = {
    BOXIE_AUGROUP = "boxie",
    BOXIE_ASM_EVENT = "BufWritePost",
    BOXIE_ASM_PATTERN = "*.asm",
    BOXIE_ASM_EXT = "asm",
    BOXIE_ASM_FILETYPE = "nasm",
    BOXIE_CMD_ASM = "BoxieAsm",
    BOXIE_CMD_NEW = "BoxieNew",
    BOXIE_CMD_ASM_DESC = "Assemble the saved file and write the hex",
    BOXIE_CMD_NEW_DESC = "Fill an empty buffer with the program skeleton",
    BOXIE_CURR_BUFF = 0,
    BOXIE_ASM_OK_FMT = "Boxie: hex written; path: %s",
    BOXIE_ASM_FAIL_FMT = "Boxie: assemble failed; src: %s; err: %d",
    BOXIE_ASM_NASM_FAIL_FMT = "Boxie: nasm reported errors; src: %s; count: %d; see the quickfix list",
    BOXIE_ASM_NASM_MISSING_FMT = "Boxie: nasm not found; src: %s",
    BOXIE_LSP_FAIL_FMT = "Boxie: asm-lsp setup failed; step: %s; err: %d",
    BOXIE_LSP_STEP_CONF = "conf",
    BOXIE_LSP_STEP_MASON = "mason",
    BOXIE_LSP_STEP_EN = "enable",
    BOXIE_STATS_FAIL_FMT = "Boxie: mode time tracking failed; err: %d",
    BOXIE_CURR_WIN = 0,
    BOXIE_TREESITTER_LANG = "asm",
    BOXIE_GUICURSOR = "n-v-c-sm:block-Cursor,i-ci-ve:ver25-Cursor,r-cr-o:hor20-Cursor,t:block-blinkon500-blinkoff500-TermCursor",
    BOXIE_TREESITTER_FAIL_TEXT = "Boxie: the treesitter asm parser could not be registered for nasm",
    BOXIE_SECTION_EMPTY = "",
    BOXIE_STATE = { section = {} },
}

function boxie.boxie_section_get()
    local out = { text = "" }
    local window = vim.g.statusline_winid or boxie.BOXIE_CURR_WIN

    if window == boxie.BOXIE_CURR_WIN then window = vim.api.nvim_get_current_win() end

    if section.boxie_section_text_get(boxie.BOXIE_STATE, window, out) ~= err.LDG_ERR_AOK then return boxie.BOXIE_SECTION_EMPTY end

    return out.text
end

function boxie.boxie_asm_buff_assemble(buff, conf)
    local out = { path = "", diag_count = 0 }
    local src = ""
    local res = 0

    if buff == nil or conf == nil then return err.LDG_ERR_FUNC_ARG_NULL end

    src = vim.api.nvim_buf_get_name(buff)

    res = asm.boxie_asm_file_assemble(src, conf, out)

    if res == err.LDG_ERR_INVALID then
        vim.cmd.copen()
        if notify.boxie_notify_put(string.format(boxie.BOXIE_ASM_NASM_FAIL_FMT, src, out.diag_count), vim.log.levels.ERROR) ~= err.LDG_ERR_AOK then return res end
        if hint.boxie_hint_fail_put(conf.state, out.diag_count) ~= err.LDG_ERR_AOK then return res end

        return res
    end

    if res == err.LDG_ERR_NOT_FOUND then
        if notify.boxie_notify_put(string.format(boxie.BOXIE_ASM_NASM_MISSING_FMT, src), vim.log.levels.ERROR) ~= err.LDG_ERR_AOK then return res end

        return res
    end

    if res ~= err.LDG_ERR_AOK then
        if notify.boxie_notify_put(string.format(boxie.BOXIE_ASM_FAIL_FMT, src, res), vim.log.levels.ERROR) ~= err.LDG_ERR_AOK then return res end

        return res
    end

    vim.cmd.cclose()

    res = notify.boxie_notify_put(string.format(boxie.BOXIE_ASM_OK_FMT, out.path), vim.log.levels.INFO)
    if res ~= err.LDG_ERR_AOK then return res end

    res = hint.boxie_hint_ok_put(conf.state, buff)
    if res ~= err.LDG_ERR_AOK then return res end

    if conf.crosstalk ~= false then
        res = crosstalk.boxie_crosstalk_reload_ck(conf)
        if res ~= err.LDG_ERR_AOK then return res end
    end

    return err.LDG_ERR_AOK
end

function boxie.boxie_asm_wr_cb(event, conf)
    if event == nil or conf == nil then return err.LDG_ERR_FUNC_ARG_NULL end

    return boxie.boxie_asm_buff_assemble(event.buf, conf)
end

function boxie.boxie_lsp_init()
    local res = 0

    res = lsp.boxie_lsp_conf_wr()
    if res ~= err.LDG_ERR_AOK then
        res = notify.boxie_notify_put(string.format(boxie.BOXIE_LSP_FAIL_FMT, boxie.BOXIE_LSP_STEP_CONF, res), vim.log.levels.WARN)
        if res ~= err.LDG_ERR_AOK then return res end
    end

    res = lsp.boxie_lsp_pkg_ensure()
    if res ~= err.LDG_ERR_AOK then
        res = notify.boxie_notify_put(string.format(boxie.BOXIE_LSP_FAIL_FMT, boxie.BOXIE_LSP_STEP_MASON, res), vim.log.levels.WARN)
        if res ~= err.LDG_ERR_AOK then return res end
    end

    res = lsp.boxie_lsp_en()
    if res ~= err.LDG_ERR_AOK then
        if notify.boxie_notify_put(string.format(boxie.BOXIE_LSP_FAIL_FMT, boxie.BOXIE_LSP_STEP_EN, res), vim.log.levels.WARN) ~= err.LDG_ERR_AOK then return res end

        return res
    end

    return err.LDG_ERR_AOK
end

function boxie.setup(given)
    local conf = vim.deepcopy(given or {})
    local group = 0
    local res = 0

    conf.state = {}
    res = hint.boxie_hint_state_init(conf.state)
    if res ~= err.LDG_ERR_AOK then return res end

    vim.filetype.add({ extension = { [boxie.BOXIE_ASM_EXT] = boxie.BOXIE_ASM_FILETYPE } })

    if conf.cursor ~= false then vim.o.guicursor = boxie.BOXIE_GUICURSOR end

    if not pcall(vim.treesitter.language.register, boxie.BOXIE_TREESITTER_LANG, boxie.BOXIE_ASM_FILETYPE) then
        res = notify.boxie_notify_put(boxie.BOXIE_TREESITTER_FAIL_TEXT, vim.log.levels.WARN)
        if res ~= err.LDG_ERR_AOK then return res end
    end

    group = vim.api.nvim_create_augroup(boxie.BOXIE_AUGROUP, { clear = true })

    vim.api.nvim_create_autocmd(boxie.BOXIE_ASM_EVENT, {
        group = group,
        pattern = boxie.BOXIE_ASM_PATTERN,
        callback = function(event)
            -- a truthy return deletes the autocmd; failures are reported inside the callback
            if boxie.boxie_asm_wr_cb(event, conf) ~= err.LDG_ERR_AOK then return false end

            return false
        end,
    })

    vim.api.nvim_create_user_command(boxie.BOXIE_CMD_ASM, function()
        if boxie.boxie_asm_buff_assemble(vim.api.nvim_get_current_buf(), conf) ~= err.LDG_ERR_AOK then return end
    end, { desc = boxie.BOXIE_CMD_ASM_DESC })

    vim.api.nvim_create_user_command(boxie.BOXIE_CMD_NEW, function()
        if cmd.boxie_cmd_new_cb() ~= err.LDG_ERR_AOK then return end
    end, { desc = boxie.BOXIE_CMD_NEW_DESC })

    conf.stats = {}
    res = stats.boxie_stats_init(conf.stats, group)
    if res ~= err.LDG_ERR_AOK then
        res = notify.boxie_notify_put(string.format(boxie.BOXIE_STATS_FAIL_FMT, res), vim.log.levels.WARN)
        if res ~= err.LDG_ERR_AOK then return res end
    end

    if conf.lsp ~= false then
        res = boxie.boxie_lsp_init()
        if res ~= err.LDG_ERR_AOK then return res end
    end

    return err.LDG_ERR_AOK
end

return boxie

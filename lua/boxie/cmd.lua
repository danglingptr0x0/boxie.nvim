local err = require("boxie.err")
local notify = require("boxie.notify")

local boxie_cmd = {
    BOXIE_CMD_NEW_FAIL_TEXT = "Boxie: the buffer is not empty",
    BOXIE_CMD_EMPTY_LN_COUNT = 1,
    BOXIE_CMD_CURR_BUFF = 0,
    BOXIE_CMD_CURR_WIN = 0,
    BOXIE_CMD_LN_FIRST = 0,
    BOXIE_CMD_LN_END = -1,
    BOXIE_CMD_TEMPLATE = {
        "bits 16",
        "org 0",
        "start:",
        "",
    },
    BOXIE_CMD_TEMPLATE_CURSOR_ROW = 4,
    BOXIE_CMD_TEMPLATE_CURSOR_COL = 0,
}

function boxie_cmd.boxie_cmd_new_cb()
    local ln = {}
    local res = 0

    ln = vim.api.nvim_buf_get_lines(boxie_cmd.BOXIE_CMD_CURR_BUFF, boxie_cmd.BOXIE_CMD_LN_FIRST, boxie_cmd.BOXIE_CMD_LN_END, false)

    if #ln ~= boxie_cmd.BOXIE_CMD_EMPTY_LN_COUNT or ln[#ln] ~= "" then
        res = notify.boxie_notify_put(boxie_cmd.BOXIE_CMD_NEW_FAIL_TEXT, vim.log.levels.ERROR)
        if res ~= err.LDG_ERR_AOK then return res end

        return err.LDG_ERR_EXISTS
    end

    vim.api.nvim_buf_set_lines(boxie_cmd.BOXIE_CMD_CURR_BUFF, boxie_cmd.BOXIE_CMD_LN_FIRST, boxie_cmd.BOXIE_CMD_LN_END, false, boxie_cmd.BOXIE_CMD_TEMPLATE)
    vim.api.nvim_win_set_cursor(boxie_cmd.BOXIE_CMD_CURR_WIN, { boxie_cmd.BOXIE_CMD_TEMPLATE_CURSOR_ROW, boxie_cmd.BOXIE_CMD_TEMPLATE_CURSOR_COL })

    return err.LDG_ERR_AOK
end

return boxie_cmd

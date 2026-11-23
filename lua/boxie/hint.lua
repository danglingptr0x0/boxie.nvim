local err = require("boxie.err")
local notify = require("boxie.notify")

local boxie_hint = {
    BOXIE_HINT_PERSIST = "persist, Boxie",
    BOXIE_HINT_SCARY = "it looks scary, but it will make sense",
    BOXIE_HINT_PROLOGUE = "the prologue and the epilogue rarely change",
    BOXIE_HINT_ZERO = "don't forget to zero",
    BOXIE_HINT_ENDIAN = "it's little endian",
    BOXIE_HINT_ORDER = "back-to-front",
    BOXIE_HINT_DIAG_MANY = 5,
    BOXIE_HINT_STREAK_MIN = 2,
    BOXIE_HINT_STREAK_STEP = 1,
    BOXIE_HINT_RUN_MIN = 2,
    BOXIE_HINT_NEXT = 1,
    BOXIE_HINT_PREV = 1,
    BOXIE_HINT_LUA_IDX_BASE = 1,
    BOXIE_HINT_LN_FIRST = 0,
    BOXIE_HINT_LN_END = -1,
    BOXIE_HINT_IDX_FIRST = 0,
    BOXIE_HINT_RUN_NONE = "",
    BOXIE_HINT_OP_PUSH = "push",
    BOXIE_HINT_OP_POP = "pop",
    BOXIE_HINT_OP_MOV = "mov",
    BOXIE_HINT_OP_CWD = "cwd",
    BOXIE_HINT_OP_XOR = "xor",
    BOXIE_HINT_OP_SUB = "sub",
    BOXIE_HINT_REG_BP = "bp",
    BOXIE_HINT_REG_DX = "dx",
    BOXIE_HINT_COMMENT_PATTERN = ";.*$",
    BOXIE_HINT_LABEL_PATTERN = "^%s*[%w_.$@?]+:%s*",
    BOXIE_HINT_INSTR_PATTERN = "^%s*([%a]+)%s*(.-)%s*$",
    BOXIE_HINT_DATA_ARG_PATTERN = "^d[wdq]%f[%A]",
    BOXIE_HINT_DATA_OP = { dw = true, dd = true, dq = true },
    BOXIE_HINT_DIV_OP = { div = true, idiv = true },
    BOXIE_HINT_DX_WR_OP = { mul = true, imul = true, div = true, idiv = true },
    BOXIE_HINT_DX_RD_OP = { out = true, cmp = true, test = true, push = true },
    BOXIE_HINT_REG16 = { ax = true, bx = true, cx = true, dx = true, si = true, di = true, bp = true, sp = true },
    BOXIE_HINT_WORD_PATTERN = "^word",
    BOXIE_HINT_DX_SELF_PATTERN = "^dx%s*,%s*dx$",
    BOXIE_HINT_DX_ZERO_PATTERN = "^dx%s*,%s*0+[hx]?0*$",
    BOXIE_HINT_DX_DST_PATTERN = "^dx%s*,",
    BOXIE_HINT_BP_SP_PATTERN = "^bp%s*,%s*sp$",
    BOXIE_HINT_RET_PATTERN = "^ret",
}

function boxie_hint.boxie_hint_state_init(out)
    if out == nil then return err.LDG_ERR_FUNC_ARG_NULL end

    out.fail_streak = 0
    out.fail_seen = err.LDG_TRUTH_FALSE
    out.prologue_shown = err.LDG_TRUTH_FALSE
    out.endian_shown = err.LDG_TRUTH_FALSE

    return err.LDG_ERR_AOK
end

function boxie_hint.boxie_hint_instr_parse(ln, out)
    local text = ""
    local op = nil
    local arg = nil

    if ln == nil or out == nil then return err.LDG_ERR_FUNC_ARG_NULL end

    out.op = ""
    out.arg = ""

    text = string.lower(ln)
    text = string.gsub(text, boxie_hint.BOXIE_HINT_COMMENT_PATTERN, "")
    text = string.gsub(text, boxie_hint.BOXIE_HINT_LABEL_PATTERN, "")

    op, arg = string.match(text, boxie_hint.BOXIE_HINT_INSTR_PATTERN)
    if op == nil then return err.LDG_ERR_EMPTY end

    out.op = op
    out.arg = arg

    return err.LDG_ERR_AOK
end

function boxie_hint.boxie_hint_code_get(buff, out)
    local ln = {}
    local entry = nil

    if buff == nil or out == nil then return err.LDG_ERR_FUNC_ARG_NULL end

    out.instr = {}

    ln = vim.api.nvim_buf_get_lines(buff, boxie_hint.BOXIE_HINT_LN_FIRST, boxie_hint.BOXIE_HINT_LN_END, false)

    for _, text in ipairs(ln) do
        entry = { op = "", arg = "" }
        if boxie_hint.boxie_hint_instr_parse(text, entry) == err.LDG_ERR_AOK then table.insert(out.instr, entry) end
    end

    return err.LDG_ERR_AOK
end

function boxie_hint.boxie_hint_instr_get(code, idx, out)
    if code == nil or idx == nil or out == nil then return err.LDG_ERR_FUNC_ARG_NULL end

    out.instr = code.instr[idx + boxie_hint.BOXIE_HINT_LUA_IDX_BASE]

    if out.instr == nil then return err.LDG_ERR_NOT_FOUND end

    return err.LDG_ERR_AOK
end

function boxie_hint.boxie_hint_prologue_has(code)
    local curr = { instr = nil }
    local next_instr = { instr = nil }
    local prologue = err.LDG_TRUTH_FALSE
    local epilogue = err.LDG_TRUTH_FALSE

    if code == nil then return err.LDG_ERR_FUNC_ARG_NULL end

    for idx = boxie_hint.BOXIE_HINT_IDX_FIRST, #code.instr - 1 do
        if boxie_hint.boxie_hint_instr_get(code, idx, curr) == err.LDG_ERR_AOK and boxie_hint.boxie_hint_instr_get(code, idx + boxie_hint.BOXIE_HINT_NEXT, next_instr) == err.LDG_ERR_AOK then
            if curr.instr.op == boxie_hint.BOXIE_HINT_OP_PUSH and curr.instr.arg == boxie_hint.BOXIE_HINT_REG_BP and next_instr.instr.op == boxie_hint.BOXIE_HINT_OP_MOV and string.match(next_instr.instr.arg, boxie_hint.BOXIE_HINT_BP_SP_PATTERN) ~= nil then prologue = err.LDG_TRUTH_TRUE end

            if curr.instr.op == boxie_hint.BOXIE_HINT_OP_POP and curr.instr.arg == boxie_hint.BOXIE_HINT_REG_BP and string.match(next_instr.instr.op, boxie_hint.BOXIE_HINT_RET_PATTERN) ~= nil then epilogue = err.LDG_TRUTH_TRUE end
        end
    end

    if prologue == err.LDG_TRUTH_TRUE and epilogue == err.LDG_TRUTH_TRUE then return err.LDG_TRUTH_TRUE end

    return err.LDG_TRUTH_FALSE
end

function boxie_hint.boxie_hint_div_wide_is(instr)
    if instr == nil then return err.LDG_ERR_FUNC_ARG_NULL end

    if boxie_hint.BOXIE_HINT_DIV_OP[instr.op] == nil then return err.LDG_TRUTH_FALSE end

    if boxie_hint.BOXIE_HINT_REG16[instr.arg] ~= nil or string.match(instr.arg, boxie_hint.BOXIE_HINT_WORD_PATTERN) ~= nil then return err.LDG_TRUTH_TRUE end

    return err.LDG_TRUTH_FALSE
end

function boxie_hint.boxie_hint_dx_zero_is(instr)
    if instr == nil then return err.LDG_ERR_FUNC_ARG_NULL end

    if instr.op == boxie_hint.BOXIE_HINT_OP_CWD then return err.LDG_TRUTH_TRUE end

    if (instr.op == boxie_hint.BOXIE_HINT_OP_XOR or instr.op == boxie_hint.BOXIE_HINT_OP_SUB) and string.match(instr.arg, boxie_hint.BOXIE_HINT_DX_SELF_PATTERN) ~= nil then return err.LDG_TRUTH_TRUE end

    if instr.op == boxie_hint.BOXIE_HINT_OP_MOV and string.match(instr.arg, boxie_hint.BOXIE_HINT_DX_ZERO_PATTERN) ~= nil then return err.LDG_TRUTH_TRUE end

    return err.LDG_TRUTH_FALSE
end

function boxie_hint.boxie_hint_dx_wr_is(instr)
    if instr == nil then return err.LDG_ERR_FUNC_ARG_NULL end

    if boxie_hint.BOXIE_HINT_DX_WR_OP[instr.op] ~= nil then return err.LDG_TRUTH_TRUE end

    if instr.op == boxie_hint.BOXIE_HINT_OP_POP and instr.arg == boxie_hint.BOXIE_HINT_REG_DX then return err.LDG_TRUTH_TRUE end

    if boxie_hint.BOXIE_HINT_DX_RD_OP[instr.op] == nil and string.match(instr.arg, boxie_hint.BOXIE_HINT_DX_DST_PATTERN) ~= nil then return err.LDG_TRUTH_TRUE end

    return err.LDG_TRUTH_FALSE
end

function boxie_hint.boxie_hint_div_dirty_has(code)
    local curr = { instr = nil }
    local prev = { instr = nil }
    local zeroed = err.LDG_TRUTH_FALSE

    if code == nil then return err.LDG_ERR_FUNC_ARG_NULL end

    for idx = boxie_hint.BOXIE_HINT_IDX_FIRST, #code.instr - 1 do
        if boxie_hint.boxie_hint_instr_get(code, idx, curr) == err.LDG_ERR_AOK and boxie_hint.boxie_hint_div_wide_is(curr.instr) == err.LDG_TRUTH_TRUE then
            zeroed = err.LDG_TRUTH_FALSE

            for back = idx - boxie_hint.BOXIE_HINT_PREV, boxie_hint.BOXIE_HINT_IDX_FIRST, -boxie_hint.BOXIE_HINT_PREV do
                if boxie_hint.boxie_hint_instr_get(code, back, prev) ~= err.LDG_ERR_AOK then break end

                if boxie_hint.boxie_hint_dx_zero_is(prev.instr) == err.LDG_TRUTH_TRUE then
                    zeroed = err.LDG_TRUTH_TRUE
                    break
                end

                if boxie_hint.boxie_hint_dx_wr_is(prev.instr) == err.LDG_TRUTH_TRUE then break end
            end

            if zeroed ~= err.LDG_TRUTH_TRUE then return err.LDG_TRUTH_TRUE end
        end
    end

    return err.LDG_TRUTH_FALSE
end

function boxie_hint.boxie_hint_data_has(code)
    if code == nil then return err.LDG_ERR_FUNC_ARG_NULL end

    for _, instr in ipairs(code.instr) do
        if boxie_hint.BOXIE_HINT_DATA_OP[instr.op] ~= nil or string.match(instr.arg, boxie_hint.BOXIE_HINT_DATA_ARG_PATTERN) ~= nil then return err.LDG_TRUTH_TRUE end
    end

    return err.LDG_TRUTH_FALSE
end

function boxie_hint.boxie_hint_run_same_is(push_run, pop_run)
    if push_run == nil or pop_run == nil then return err.LDG_ERR_FUNC_ARG_NULL end

    if #push_run < boxie_hint.BOXIE_HINT_RUN_MIN or #push_run ~= #pop_run then return err.LDG_TRUTH_FALSE end

    for idx, reg in ipairs(push_run) do
        if pop_run[idx] ~= reg then return err.LDG_TRUTH_FALSE end
    end

    return err.LDG_TRUTH_TRUE
end

function boxie_hint.boxie_hint_order_repeat_has(code)
    local push_run = {}
    local run = {}
    local kind = boxie_hint.BOXIE_HINT_RUN_NONE

    if code == nil then return err.LDG_ERR_FUNC_ARG_NULL end

    for _, instr in ipairs(code.instr) do
        if instr.op ~= kind then
            if kind == boxie_hint.BOXIE_HINT_OP_PUSH then push_run = run end

            if kind == boxie_hint.BOXIE_HINT_OP_POP and boxie_hint.boxie_hint_run_same_is(push_run, run) == err.LDG_TRUTH_TRUE then return err.LDG_TRUTH_TRUE end

            run = {}
            kind = boxie_hint.BOXIE_HINT_RUN_NONE

            if instr.op == boxie_hint.BOXIE_HINT_OP_PUSH or instr.op == boxie_hint.BOXIE_HINT_OP_POP then kind = instr.op end
        end

        if kind ~= boxie_hint.BOXIE_HINT_RUN_NONE then table.insert(run, instr.arg) end
    end

    if kind == boxie_hint.BOXIE_HINT_OP_POP and boxie_hint.boxie_hint_run_same_is(push_run, run) == err.LDG_TRUTH_TRUE then return err.LDG_TRUTH_TRUE end

    return err.LDG_TRUTH_FALSE
end

function boxie_hint.boxie_hint_fail_put(state, diag_count)
    if state == nil or diag_count == nil then return err.LDG_ERR_FUNC_ARG_NULL end

    state.fail_streak = state.fail_streak + boxie_hint.BOXIE_HINT_STREAK_STEP

    if state.fail_streak >= boxie_hint.BOXIE_HINT_STREAK_MIN then
        state.fail_seen = err.LDG_TRUTH_TRUE
        return notify.boxie_notify_put(boxie_hint.BOXIE_HINT_PERSIST, vim.log.levels.INFO)
    end

    if state.fail_seen ~= err.LDG_TRUTH_TRUE or diag_count >= boxie_hint.BOXIE_HINT_DIAG_MANY then
        state.fail_seen = err.LDG_TRUTH_TRUE
        return notify.boxie_notify_put(boxie_hint.BOXIE_HINT_SCARY, vim.log.levels.INFO)
    end

    return err.LDG_ERR_AOK
end

function boxie_hint.boxie_hint_ok_put(state, buff)
    local code = { instr = {} }
    local res = 0

    if state == nil or buff == nil then return err.LDG_ERR_FUNC_ARG_NULL end

    state.fail_streak = 0

    res = boxie_hint.boxie_hint_code_get(buff, code)
    if res ~= err.LDG_ERR_AOK then return res end

    if state.prologue_shown ~= err.LDG_TRUTH_TRUE and boxie_hint.boxie_hint_prologue_has(code) == err.LDG_TRUTH_TRUE then
        state.prologue_shown = err.LDG_TRUTH_TRUE
        res = notify.boxie_notify_put(boxie_hint.BOXIE_HINT_PROLOGUE, vim.log.levels.INFO)
        if res ~= err.LDG_ERR_AOK then return res end
    end

    if boxie_hint.boxie_hint_div_dirty_has(code) == err.LDG_TRUTH_TRUE then
        res = notify.boxie_notify_put(boxie_hint.BOXIE_HINT_ZERO, vim.log.levels.WARN)
        if res ~= err.LDG_ERR_AOK then return res end
    end

    if state.endian_shown ~= err.LDG_TRUTH_TRUE and boxie_hint.boxie_hint_data_has(code) == err.LDG_TRUTH_TRUE then
        state.endian_shown = err.LDG_TRUTH_TRUE
        res = notify.boxie_notify_put(boxie_hint.BOXIE_HINT_ENDIAN, vim.log.levels.INFO)
        if res ~= err.LDG_ERR_AOK then return res end
    end

    if boxie_hint.boxie_hint_order_repeat_has(code) == err.LDG_TRUTH_TRUE then
        res = notify.boxie_notify_put(boxie_hint.BOXIE_HINT_ORDER, vim.log.levels.WARN)
        if res ~= err.LDG_ERR_AOK then return res end
    end

    return err.LDG_ERR_AOK
end

return boxie_hint

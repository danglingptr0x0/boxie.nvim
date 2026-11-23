local err = require("boxie.err")
local instr = require("boxie.instr")

local boxie_section = {
    BOXIE_SECTION_PREFIX = "x86 ASM ",
    BOXIE_SECTION_FIELD_SEP = "; ",
    BOXIE_SECTION_TRUNCATE = "%<",
    BOXIE_SECTION_HOVER_METHOD = "textDocument/hover",
    BOXIE_SECTION_HOVER_PENDING = false,
    BOXIE_SECTION_HOVER_MAX = 80,
    BOXIE_SECTION_HOVER_OP_SEP = ": ",
    BOXIE_SECTION_HOVER_SKIP_PATTERN = "^%s*[#`|%-]",
    BOXIE_SECTION_HOVER_MARK_PATTERN = "[%*_`]",
    BOXIE_SECTION_HOVER_SENTENCE_PATTERN = "^(.-%.)%s",
    BOXIE_SECTION_HOVER_SENTENCE_TAIL = " ",
    BOXIE_SECTION_HOVER_TRIM_PATTERN = "^%s*(.-)%s*$",
    BOXIE_SECTION_HOVER_LN_PATTERN = "[^\n]+",
    BOXIE_SECTION_LF = "\n",
    BOXIE_SECTION_TYPE_STRING = "string",
    BOXIE_SECTION_TYPE_TABLE = "table",
    BOXIE_SECTION_CLIENT_NONE = 0,
    BOXIE_SECTION_FIND_PLAIN_START = 1,
    BOXIE_SECTION_COL_BASE = 1,
    BOXIE_SECTION_NONINSTR_KIND = { header = true, macro = true, constant = true, section = true, padding = true, data = true, reserve = true },
    BOXIE_SECTION_NAME_SEP = ": ",
    BOXIE_SECTION_HIGHLIGHT = "%#St_LspMsg#",
    BOXIE_SECTION_PAD = " ",
    BOXIE_SECTION_FILETYPE = "nasm",
    BOXIE_SECTION_IDX_NONE = 0xFFFFFFFF,
    BOXIE_SECTION_IDX_FIRST = 0,
    BOXIE_SECTION_LUA_IDX_BASE = 1,
    BOXIE_SECTION_STEP = 1,
    BOXIE_SECTION_LN_FIRST = 0,
    BOXIE_SECTION_LN_END = -1,
    BOXIE_SECTION_CURSOR_ROW = 1,
    BOXIE_SECTION_OP_PUSH = "push",
    BOXIE_SECTION_OP_POP = "pop",
    BOXIE_SECTION_OP_MOV = "mov",
    BOXIE_SECTION_OP_SUB = "sub",
    BOXIE_SECTION_OP_LEAVE = "leave",
    BOXIE_SECTION_REG_BP = "bp",
    BOXIE_SECTION_COMMENT_PATTERN = ";.*$",
    BOXIE_SECTION_LABEL_PATTERN = "^%s*([%w_.$@?]+):(.*)$",
    BOXIE_SECTION_INSTR_PATTERN = "^%s*([%%%w_.$@?]+)%s*(.-)%s*$",
    BOXIE_SECTION_BARE_DATA_PATTERN = "^(%a+)%s*(.-)$",
    BOXIE_SECTION_FIRST_WORD_PATTERN = "^([%%%w_.$@?]+)",
    BOXIE_SECTION_SIZED_PATTERN = "^(%a+)%s+(.+)$",
    BOXIE_SECTION_LOCAL_PATTERN = "^%.",
    BOXIE_SECTION_JMP_PATTERN = "^j%a+$",
    BOXIE_SECTION_LOOP_PATTERN = "^loop%a*$",
    BOXIE_SECTION_BP_SP_PATTERN = "^bp%s*,%s*sp$",
    BOXIE_SECTION_SP_BP_PATTERN = "^sp%s*,%s*bp$",
    BOXIE_SECTION_SP_DST_PATTERN = "^sp%s*,",
    BOXIE_SECTION_RET_PATTERN = "^ret",
    BOXIE_SECTION_PAD_ARG_PATTERN = "d[bwdq]%s+0+[hx]?0*%s*$",
    BOXIE_SECTION_HDR_OP = { bits = true, org = true, cpu = true, use16 = true, use32 = true },
    BOXIE_SECTION_CONSTANT_OP = { ["%define"] = true, ["%assign"] = true, ["%xdefine"] = true, equ = true },
    BOXIE_SECTION_SECTION_OP = { section = true, segment = true },
    BOXIE_SECTION_DATA_OP = { db = true, dw = true, dd = true, dq = true, dt = true },
    BOXIE_SECTION_RESERVE_OP = { resb = true, resw = true, resd = true, resq = true },
    BOXIE_SECTION_BARE_OP = { db = true, dw = true, dd = true, dq = true, dt = true, resb = true, resw = true, resd = true, resq = true, times = true, equ = true },
    BOXIE_SECTION_IN_OP = { ["in"] = true, ins = true, insb = true, insw = true },
    BOXIE_SECTION_OUT_OP = { out = true, outs = true, outsb = true, outsw = true },
    BOXIE_SECTION_INT_OP = { int = true, into = true, iret = true },
    BOXIE_SECTION_IF_OP = { cli = true, sti = true },
    BOXIE_SECTION_PUSH_OP = { push = true, pusha = true, pushf = true },
    BOXIE_SECTION_POP_OP = { pop = true, popa = true, popf = true },
    BOXIE_SECTION_JMP_SIZE = { short = true, near = true, far = true },
    BOXIE_SECTION_MACRO_OPEN = "%macro",
    BOXIE_SECTION_MACRO_CLOSE = "%endmacro",
    BOXIE_SECTION_TIMES = "times",
    BOXIE_SECTION_CALL = "call",
    BOXIE_SECTION_HLT = "hlt",
    BOXIE_SECTION_KIND_HDR = "header",
    BOXIE_SECTION_KIND_MACRO = "macro",
    BOXIE_SECTION_KIND_CONSTANT = "constant",
    BOXIE_SECTION_KIND_SECTION = "section",
    BOXIE_SECTION_KIND_PAD = "padding",
    BOXIE_SECTION_KIND_DATA = "data",
    BOXIE_SECTION_KIND_RESERVE = "reserve",
    BOXIE_SECTION_KIND_PROLOGUE = "prologue",
    BOXIE_SECTION_KIND_EPILOGUE = "epilogue",
    BOXIE_SECTION_KIND_IN = "port input",
    BOXIE_SECTION_KIND_OUT = "port output",
    BOXIE_SECTION_KIND_INT = "interrupt",
    BOXIE_SECTION_KIND_IF = "interrupt flag",
    BOXIE_SECTION_KIND_HLT = "halt",
    BOXIE_SECTION_KIND_CALL = "call",
    BOXIE_SECTION_KIND_SAVE = "stack save",
    BOXIE_SECTION_KIND_RESTORE = "stack restore",
    BOXIE_SECTION_KIND_LOOP = "loop",
    BOXIE_SECTION_KIND_BODY = "body",
    BOXIE_SECTION_KIND_ENTRY = "entry",
    BOXIE_SECTION_KIND_CODE = "code",
}

function boxie_section.boxie_section_ln_parse(raw, out)
    local text = ""
    local label = nil
    local rest = nil
    local op = nil
    local arg = nil
    local inner_op = nil
    local inner_arg = nil

    if raw == nil or out == nil then return err.LDG_ERR_FUNC_ARG_NULL end

    out.label = ""
    out.op = ""
    out.op_raw = ""
    out.arg = ""
    out.arg_raw = ""

    text = string.gsub(raw, boxie_section.BOXIE_SECTION_COMMENT_PATTERN, "")

    label, rest = string.match(text, boxie_section.BOXIE_SECTION_LABEL_PATTERN)
    if label ~= nil then
        out.label = label
        text = rest
    end

    op, arg = string.match(text, boxie_section.BOXIE_SECTION_INSTR_PATTERN)
    if op == nil then return err.LDG_ERR_AOK end

    inner_op, inner_arg = string.match(arg, boxie_section.BOXIE_SECTION_BARE_DATA_PATTERN)
    if out.label == "" and inner_op ~= nil and boxie_section.BOXIE_SECTION_BARE_OP[string.lower(inner_op)] ~= nil then
        out.label = op
        op = inner_op
        arg = inner_arg
    end

    out.op = string.lower(op)
    out.op_raw = op
    out.arg = string.lower(arg)
    out.arg_raw = arg

    return err.LDG_ERR_AOK
end

function boxie_section.boxie_section_word_get(arg, out)
    local first = nil
    local rest = nil
    local word = nil

    if arg == nil or out == nil then return err.LDG_ERR_FUNC_ARG_NULL end

    out.word = ""

    first, rest = string.match(arg, boxie_section.BOXIE_SECTION_SIZED_PATTERN)
    if first ~= nil and boxie_section.BOXIE_SECTION_JMP_SIZE[string.lower(first)] ~= nil then arg = rest end

    word = string.match(arg, boxie_section.BOXIE_SECTION_FIRST_WORD_PATTERN)
    if word == nil then return err.LDG_ERR_EMPTY end

    out.word = word

    return err.LDG_ERR_AOK
end

function boxie_section.boxie_section_instr_step_get(code, from, dir, out)
    local idx = 0

    if code == nil or from == nil or dir == nil or out == nil then return err.LDG_ERR_FUNC_ARG_NULL end

    out.idx = boxie_section.BOXIE_SECTION_IDX_NONE
    idx = from + dir

    while idx >= 0 and idx < code.ln_count do
        if code.ln[idx].op ~= "" then
            out.idx = idx
            return err.LDG_ERR_AOK
        end

        idx = idx + dir
    end

    return err.LDG_ERR_NOT_FOUND
end

function boxie_section.boxie_section_code_get(buff, out)
    local raw = {}
    local ln = nil
    local label_near = ""
    local glob_near = ""
    local macro_name = ""
    local res = 0

    if buff == nil or out == nil then return err.LDG_ERR_FUNC_ARG_NULL end

    out.ln = {}
    out.ln_count = 0
    out.label = {}
    out.near_label = {}
    out.near_glob = {}
    out.macro = {}
    out.op_col = {}
    out.first_glob = ""

    raw = vim.api.nvim_buf_get_lines(buff, boxie_section.BOXIE_SECTION_LN_FIRST, boxie_section.BOXIE_SECTION_LN_END, false)
    out.ln_count = #raw

    for idx = boxie_section.BOXIE_SECTION_IDX_FIRST, out.ln_count - 1 do
        ln = { label = "", op = "", op_raw = "", arg = "", arg_raw = "" }

        res = boxie_section.boxie_section_ln_parse(raw[idx + boxie_section.BOXIE_SECTION_LUA_IDX_BASE], ln)
        if res ~= err.LDG_ERR_AOK then return res end

        out.ln[idx] = ln

        if ln.op ~= "" then
            local at = string.find(string.lower(raw[idx + boxie_section.BOXIE_SECTION_LUA_IDX_BASE]), ln.op, boxie_section.BOXIE_SECTION_FIND_PLAIN_START, true)
            if at ~= nil then out.op_col[idx] = at - boxie_section.BOXIE_SECTION_COL_BASE end
        end

        if ln.label ~= "" then
            label_near = ln.label
            if out.label[ln.label] == nil then out.label[ln.label] = {} end
            table.insert(out.label[ln.label], idx)

            if string.match(ln.label, boxie_section.BOXIE_SECTION_LOCAL_PATTERN) == nil then
                glob_near = ln.label
                if out.first_glob == "" then out.first_glob = ln.label end
            end
        end

        if ln.op == boxie_section.BOXIE_SECTION_MACRO_OPEN then
            local word = { word = "" }
            if boxie_section.boxie_section_word_get(ln.arg_raw, word) == err.LDG_ERR_AOK then macro_name = word.word end
        end

        out.near_label[idx] = label_near
        out.near_glob[idx] = glob_near
        out.macro[idx] = macro_name

        if ln.op == boxie_section.BOXIE_SECTION_MACRO_CLOSE then macro_name = "" end
    end

    return err.LDG_ERR_AOK
end

function boxie_section.boxie_section_frame_mark(code, out)
    local next_instr = { idx = 0 }
    local after = { idx = 0 }
    local prev = { idx = 0 }
    local ln = nil

    if code == nil or out == nil then return err.LDG_ERR_FUNC_ARG_NULL end

    out.prologue = {}
    out.epilogue = {}
    out.prologue_start = {}

    for idx = boxie_section.BOXIE_SECTION_IDX_FIRST, code.ln_count - 1 do
        ln = code.ln[idx]

        if ln.op == boxie_section.BOXIE_SECTION_OP_PUSH and ln.arg == boxie_section.BOXIE_SECTION_REG_BP and boxie_section.boxie_section_instr_step_get(code, idx, boxie_section.BOXIE_SECTION_STEP, next_instr) == err.LDG_ERR_AOK then
            if code.ln[next_instr.idx].op == boxie_section.BOXIE_SECTION_OP_MOV and string.match(code.ln[next_instr.idx].arg, boxie_section.BOXIE_SECTION_BP_SP_PATTERN) ~= nil then
                out.prologue[idx] = err.LDG_TRUTH_TRUE
                out.prologue[next_instr.idx] = err.LDG_TRUTH_TRUE
                table.insert(out.prologue_start, idx)

                if boxie_section.boxie_section_instr_step_get(code, next_instr.idx, boxie_section.BOXIE_SECTION_STEP, after) == err.LDG_ERR_AOK and code.ln[after.idx].op == boxie_section.BOXIE_SECTION_OP_SUB and string.match(code.ln[after.idx].arg, boxie_section.BOXIE_SECTION_SP_DST_PATTERN) ~= nil then out.prologue[after.idx] = err.LDG_TRUTH_TRUE end
            end
        end

        if ln.op == boxie_section.BOXIE_SECTION_OP_POP and ln.arg == boxie_section.BOXIE_SECTION_REG_BP and boxie_section.boxie_section_instr_step_get(code, idx, boxie_section.BOXIE_SECTION_STEP, next_instr) == err.LDG_ERR_AOK then
            if string.match(code.ln[next_instr.idx].op, boxie_section.BOXIE_SECTION_RET_PATTERN) ~= nil then
                out.epilogue[idx] = err.LDG_TRUTH_TRUE
                out.epilogue[next_instr.idx] = err.LDG_TRUTH_TRUE

                if boxie_section.boxie_section_instr_step_get(code, idx, -boxie_section.BOXIE_SECTION_STEP, prev) == err.LDG_ERR_AOK then
                    if code.ln[prev.idx].op == boxie_section.BOXIE_SECTION_OP_LEAVE or (code.ln[prev.idx].op == boxie_section.BOXIE_SECTION_OP_MOV and string.match(code.ln[prev.idx].arg, boxie_section.BOXIE_SECTION_SP_BP_PATTERN) ~= nil) then out.epilogue[prev.idx] = err.LDG_TRUTH_TRUE end
                end
            end
        end
    end

    return err.LDG_ERR_AOK
end

function boxie_section.boxie_section_label_ln_get(code, name, before, out)
    local hit = nil

    if code == nil or name == nil or before == nil or out == nil then return err.LDG_ERR_FUNC_ARG_NULL end

    out.idx = boxie_section.BOXIE_SECTION_IDX_NONE
    hit = code.label[name]

    if hit == nil then return err.LDG_ERR_NOT_FOUND end

    for _, at in ipairs(hit) do
        if at <= before then out.idx = at end
    end

    if out.idx == boxie_section.BOXIE_SECTION_IDX_NONE then return err.LDG_ERR_NOT_FOUND end

    return err.LDG_ERR_AOK
end

function boxie_section.boxie_section_proc_mark(code, frame, out)
    local name = ""
    local hd = { idx = 0 }
    local first = 0
    local last = 0

    if code == nil or frame == nil or out == nil then return err.LDG_ERR_FUNC_ARG_NULL end

    out.proc = {}

    for _, start in ipairs(frame.prologue_start) do
        name = code.near_glob[start]
        first = start

        if name ~= "" and boxie_section.boxie_section_label_ln_get(code, name, start, hd) == err.LDG_ERR_AOK then first = hd.idx end

        last = code.ln_count - 1

        for idx = start, code.ln_count - 1 do
            if frame.epilogue[idx] == err.LDG_TRUTH_TRUE and string.match(code.ln[idx].op, boxie_section.BOXIE_SECTION_RET_PATTERN) ~= nil then
                last = idx
                break
            end
        end

        for idx = first, last do
            out.proc[idx] = name
        end
    end

    return err.LDG_ERR_AOK
end

function boxie_section.boxie_section_loop_mark(code, out)
    local span = {}
    local word = { word = "" }
    local hd = { idx = 0 }
    local ln = nil

    if code == nil or out == nil then return err.LDG_ERR_FUNC_ARG_NULL end

    out.loop = {}

    for idx = boxie_section.BOXIE_SECTION_IDX_FIRST, code.ln_count - 1 do
        ln = code.ln[idx]

        if (string.match(ln.op, boxie_section.BOXIE_SECTION_JMP_PATTERN) ~= nil or string.match(ln.op, boxie_section.BOXIE_SECTION_LOOP_PATTERN) ~= nil) and boxie_section.boxie_section_word_get(ln.arg_raw, word) == err.LDG_ERR_AOK then
            if boxie_section.boxie_section_label_ln_get(code, word.word, idx, hd) == err.LDG_ERR_AOK then table.insert(span, { first = hd.idx, last = idx, name = word.word }) end
        end
    end

    table.sort(span, function(lhs, rhs) return lhs.last - lhs.first > rhs.last - rhs.first end)

    for _, entry in ipairs(span) do
        for idx = entry.first, entry.last do
            out.loop[idx] = entry.name
        end
    end

    return err.LDG_ERR_AOK
end

function boxie_section.boxie_section_region_get(code, mark, idx, out)
    if code == nil or mark == nil or idx == nil or out == nil then return err.LDG_ERR_FUNC_ARG_NULL end

    out.kind = boxie_section.BOXIE_SECTION_KIND_CODE
    out.name = code.near_label[idx]

    if mark.loop[idx] ~= nil then
        out.kind = boxie_section.BOXIE_SECTION_KIND_LOOP
        out.name = mark.loop[idx]
        return err.LDG_ERR_AOK
    end

    if mark.proc[idx] ~= nil then
        out.kind = boxie_section.BOXIE_SECTION_KIND_BODY
        out.name = mark.proc[idx]
        return err.LDG_ERR_AOK
    end

    if code.near_label[idx] == "" then
        out.kind = boxie_section.BOXIE_SECTION_KIND_HDR
        out.name = ""
        return err.LDG_ERR_AOK
    end

    if code.near_glob[idx] == code.first_glob then out.kind = boxie_section.BOXIE_SECTION_KIND_ENTRY end

    return err.LDG_ERR_AOK
end

function boxie_section.boxie_section_kind_get(code, mark, idx, out)
    local ln = nil
    local region = { kind = "", name = "" }
    local word = { word = "" }
    local proc_name = ""
    local res = 0

    if code == nil or mark == nil or idx == nil or out == nil then return err.LDG_ERR_FUNC_ARG_NULL end

    res = boxie_section.boxie_section_region_get(code, mark, idx, region)
    if res ~= err.LDG_ERR_AOK then return res end

    out.kind = region.kind
    out.name = region.name

    ln = code.ln[idx]
    proc_name = mark.proc[idx] or code.near_glob[idx]

    if boxie_section.boxie_section_word_get(ln.arg_raw, word) ~= err.LDG_ERR_AOK then word.word = "" end

    if code.macro[idx] ~= "" then
        out.kind = boxie_section.BOXIE_SECTION_KIND_MACRO
        out.name = code.macro[idx]
    elseif ln.op == "" then
        return err.LDG_ERR_AOK
    elseif boxie_section.BOXIE_SECTION_HDR_OP[ln.op] ~= nil then
        out.kind = boxie_section.BOXIE_SECTION_KIND_HDR
        out.name = ""
    elseif boxie_section.BOXIE_SECTION_CONSTANT_OP[ln.op] ~= nil then
        out.kind = boxie_section.BOXIE_SECTION_KIND_CONSTANT
        out.name = ln.label ~= "" and ln.label or word.word
    elseif boxie_section.BOXIE_SECTION_SECTION_OP[ln.op] ~= nil then
        out.kind = boxie_section.BOXIE_SECTION_KIND_SECTION
        out.name = word.word
    elseif ln.op == boxie_section.BOXIE_SECTION_TIMES then
        out.kind = string.match(ln.arg, boxie_section.BOXIE_SECTION_PAD_ARG_PATTERN) ~= nil and boxie_section.BOXIE_SECTION_KIND_PAD or boxie_section.BOXIE_SECTION_KIND_DATA
        out.name = ln.label ~= "" and ln.label or code.near_label[idx]
    elseif boxie_section.BOXIE_SECTION_DATA_OP[ln.op] ~= nil then
        out.kind = boxie_section.BOXIE_SECTION_KIND_DATA
        out.name = ln.label ~= "" and ln.label or code.near_label[idx]
    elseif boxie_section.BOXIE_SECTION_RESERVE_OP[ln.op] ~= nil then
        out.kind = boxie_section.BOXIE_SECTION_KIND_RESERVE
        out.name = ln.label ~= "" and ln.label or code.near_label[idx]
    elseif mark.prologue[idx] == err.LDG_TRUTH_TRUE then
        out.kind = boxie_section.BOXIE_SECTION_KIND_PROLOGUE
        out.name = proc_name
    elseif mark.epilogue[idx] == err.LDG_TRUTH_TRUE then
        out.kind = boxie_section.BOXIE_SECTION_KIND_EPILOGUE
        out.name = proc_name
    elseif boxie_section.BOXIE_SECTION_IN_OP[ln.op] ~= nil then
        out.kind = boxie_section.BOXIE_SECTION_KIND_IN
    elseif boxie_section.BOXIE_SECTION_OUT_OP[ln.op] ~= nil then
        out.kind = boxie_section.BOXIE_SECTION_KIND_OUT
    elseif boxie_section.BOXIE_SECTION_INT_OP[ln.op] ~= nil then
        out.kind = boxie_section.BOXIE_SECTION_KIND_INT
        out.name = ln.arg
    elseif boxie_section.BOXIE_SECTION_IF_OP[ln.op] ~= nil then
        out.kind = boxie_section.BOXIE_SECTION_KIND_IF
        out.name = ln.op
    elseif ln.op == boxie_section.BOXIE_SECTION_HLT then
        out.kind = boxie_section.BOXIE_SECTION_KIND_HLT
    elseif ln.op == boxie_section.BOXIE_SECTION_CALL then
        out.kind = boxie_section.BOXIE_SECTION_KIND_CALL
        out.name = word.word
    elseif boxie_section.BOXIE_SECTION_PUSH_OP[ln.op] ~= nil then
        out.kind = boxie_section.BOXIE_SECTION_KIND_SAVE
    elseif boxie_section.BOXIE_SECTION_POP_OP[ln.op] ~= nil then
        out.kind = boxie_section.BOXIE_SECTION_KIND_RESTORE
    end

    return err.LDG_ERR_AOK
end

function boxie_section.boxie_section_text_build(buff, out)
    local code = {}
    local frame = {}
    local proc = {}
    local loop = {}
    local mark = {}
    local kind = { kind = "", name = "" }
    local desc = { text = "" }
    local res = 0

    if buff == nil or out == nil then return err.LDG_ERR_FUNC_ARG_NULL end

    out.text = {}
    out.hover = {}

    res = boxie_section.boxie_section_code_get(buff, code)
    if res ~= err.LDG_ERR_AOK then return res end

    res = boxie_section.boxie_section_frame_mark(code, frame)
    if res ~= err.LDG_ERR_AOK then return res end

    res = boxie_section.boxie_section_proc_mark(code, frame, proc)
    if res ~= err.LDG_ERR_AOK then return res end

    res = boxie_section.boxie_section_loop_mark(code, loop)
    if res ~= err.LDG_ERR_AOK then return res end

    mark = { prologue = frame.prologue, epilogue = frame.epilogue, proc = proc.proc, loop = loop.loop }

    for idx = boxie_section.BOXIE_SECTION_IDX_FIRST, code.ln_count - 1 do
        res = boxie_section.boxie_section_kind_get(code, mark, idx, kind)
        if res ~= err.LDG_ERR_AOK then return res end

        out.text[idx] = boxie_section.BOXIE_SECTION_PREFIX .. kind.kind
        if kind.name ~= "" then out.text[idx] = out.text[idx] .. boxie_section.BOXIE_SECTION_NAME_SEP .. kind.name end

        if code.ln[idx].op ~= "" and boxie_section.BOXIE_SECTION_NONINSTR_KIND[kind.kind] == nil then
            if instr.boxie_instr_text_get(code.ln[idx].op, code.ln[idx].op_raw, desc) == err.LDG_ERR_AOK then
                out.text[idx] = out.text[idx] .. boxie_section.BOXIE_SECTION_FIELD_SEP .. desc.text
            elseif code.op_col[idx] ~= nil then
                out.hover[idx] = { op = code.ln[idx].op, op_raw = code.ln[idx].op_raw, col = code.op_col[idx] }
            end
        end
    end

    return err.LDG_ERR_AOK
end

function boxie_section.boxie_section_text_get(state, window, out)
    local buff = 0
    local tick = 0
    local cache = nil
    local built = { text = {}, hover = {} }
    local row = 0
    local text = ""
    local hover = nil
    local res = 0

    if state == nil or window == nil or out == nil then return err.LDG_ERR_FUNC_ARG_NULL end

    out.text = ""

    if not vim.api.nvim_win_is_valid(window) then return err.LDG_ERR_FUNC_ARG_INVALID end

    buff = vim.api.nvim_win_get_buf(window)

    if vim.bo[buff].filetype ~= boxie_section.BOXIE_SECTION_FILETYPE then return err.LDG_ERR_AOK end

    if state.section == nil then state.section = {} end

    tick = vim.api.nvim_buf_get_changedtick(buff)
    cache = state.section[buff]

    if cache == nil or cache.tick ~= tick then
        res = boxie_section.boxie_section_text_build(buff, built)
        if res ~= err.LDG_ERR_AOK then return res end

        cache = { tick = tick, text = built.text, hover = built.hover }
        state.section[buff] = cache
    end

    row = vim.api.nvim_win_get_cursor(window)[boxie_section.BOXIE_SECTION_CURSOR_ROW] - boxie_section.BOXIE_SECTION_LUA_IDX_BASE

    if cache.text[row] == nil then return err.LDG_ERR_AOK end

    text = cache.text[row]

    if cache.hover[row] ~= nil then
        if state.hover == nil then state.hover = {} end

        hover = state.hover[cache.hover[row].op_raw]

        if hover == nil then
            if boxie_section.boxie_section_hover_req_send(state, buff, row, cache.hover[row]) ~= err.LDG_ERR_AOK then hover = nil end
        elseif hover ~= boxie_section.BOXIE_SECTION_HOVER_PENDING and hover ~= "" then
            text = text .. boxie_section.BOXIE_SECTION_FIELD_SEP .. hover
        end
    end

    out.text = boxie_section.BOXIE_SECTION_HIGHLIGHT .. boxie_section.BOXIE_SECTION_TRUNCATE .. boxie_section.BOXIE_SECTION_PAD .. text .. boxie_section.BOXIE_SECTION_PAD

    return err.LDG_ERR_AOK
end

function boxie_section.boxie_section_hover_text_get(content, out)
    local raw = ""
    local ln = ""
    local sentence = nil

    if out == nil then return err.LDG_ERR_FUNC_ARG_NULL end

    out.text = ""

    if type(content) == boxie_section.BOXIE_SECTION_TYPE_STRING then raw = content end
    if type(content) == boxie_section.BOXIE_SECTION_TYPE_TABLE and type(content.value) == boxie_section.BOXIE_SECTION_TYPE_STRING then raw = content.value end
    if type(content) == boxie_section.BOXIE_SECTION_TYPE_TABLE and content.value == nil then
        for _, part in ipairs(content) do
            if type(part) == boxie_section.BOXIE_SECTION_TYPE_STRING then raw = raw .. part .. boxie_section.BOXIE_SECTION_LF end
            if type(part) == boxie_section.BOXIE_SECTION_TYPE_TABLE and type(part.value) == boxie_section.BOXIE_SECTION_TYPE_STRING then raw = raw .. part.value .. boxie_section.BOXIE_SECTION_LF end
        end
    end

    for candidate in string.gmatch(raw, boxie_section.BOXIE_SECTION_HOVER_LN_PATTERN) do
        if string.match(candidate, boxie_section.BOXIE_SECTION_HOVER_SKIP_PATTERN) == nil then
            ln = string.gsub(candidate, boxie_section.BOXIE_SECTION_HOVER_MARK_PATTERN, "")
            ln = string.match(ln, boxie_section.BOXIE_SECTION_HOVER_TRIM_PATTERN)
            if ln ~= nil and ln ~= "" then break end
        end
    end

    if ln == nil or ln == "" then return err.LDG_ERR_EMPTY end

    sentence = string.match(ln .. boxie_section.BOXIE_SECTION_HOVER_SENTENCE_TAIL, boxie_section.BOXIE_SECTION_HOVER_SENTENCE_PATTERN)
    if sentence ~= nil then ln = sentence end

    out.text = string.sub(ln, boxie_section.BOXIE_SECTION_LUA_IDX_BASE, boxie_section.BOXIE_SECTION_HOVER_MAX)

    return err.LDG_ERR_AOK
end

function boxie_section.boxie_section_hover_req_send(state, buff, row, want)
    local param = nil

    if state == nil or buff == nil or row == nil or want == nil then return err.LDG_ERR_FUNC_ARG_NULL end

    if #vim.lsp.get_clients({ bufnr = buff }) == boxie_section.BOXIE_SECTION_CLIENT_NONE then return err.LDG_ERR_NOT_FOUND end

    param = { textDocument = { uri = vim.uri_from_bufnr(buff) }, position = { line = row, character = want.col } }
    state.hover[want.op_raw] = boxie_section.BOXIE_SECTION_HOVER_PENDING

    vim.lsp.buf_request(buff, boxie_section.BOXIE_SECTION_HOVER_METHOD, param, function(fault, res)
        local found = { text = "" }

        state.hover[want.op_raw] = ""

        if fault == nil and res ~= nil and boxie_section.boxie_section_hover_text_get(res.contents, found) == err.LDG_ERR_AOK then state.hover[want.op_raw] = want.op_raw .. boxie_section.BOXIE_SECTION_HOVER_OP_SEP .. found.text end

        vim.schedule(function() vim.cmd.redrawstatus() end)
    end)

    return err.LDG_ERR_AOK
end

return boxie_section

local err = require("boxie.err")

local boxie_asm = {
    BOXIE_ASM_IMG_SIZE = 0x10000,
    BOXIE_ASM_RST_VEC_OFF = 0xFFF0,
    BOXIE_ASM_RST_JMP = { 0xEA, 0x00, 0x00, 0x00, 0xF0 },
    BOXIE_ASM_PAD_BYTE = 0x00,
    BOXIE_ASM_LUA_IDX_BASE = 1,
    BOXIE_ASM_HEX_HDR_LN = 1,
    BOXIE_ASM_HEX_ORIG = "@F0000",
    BOXIE_ASM_HEX_BYTE_FMT = "%02x",
    BOXIE_ASM_HEX_LF = "\n",
    BOXIE_ASM_HEX_EXT = ".hex",
    BOXIE_ASM_TEMPORARY_EXT = ".tmp",
    BOXIE_ASM_BIN_EXT = ".bin",
    BOXIE_ASM_NASM = "nasm",
    BOXIE_ASM_NASM_FMT_FLAG = "-f",
    BOXIE_ASM_NASM_FMT = "bin",
    BOXIE_ASM_NASM_OUT_FLAG = "-o",
    BOXIE_ASM_NASM_OK = 0,
    BOXIE_ASM_RD_MODE = "rb",
    BOXIE_ASM_WR_MODE = "wb",
    BOXIE_ASM_RD_ALL = "a",
    BOXIE_ASM_STEM_MOD = ":t:r",
    BOXIE_ASM_DIR_MOD = ":p:h",
    BOXIE_ASM_QUICKFIX_REPLACE = "r",
    BOXIE_ASM_QUICKFIX_OK = 0,
    BOXIE_ASM_QUICKFIX_TITLE = "nasm",
    BOXIE_ASM_QUICKFIX_ERRORFORMAT = "%f:%l: %t%*[a-z]: %m",
}

function boxie_asm.boxie_asm_nasm_run(src_path, bin_path, out)
    local ok = false
    local proc = nil
    local run = nil

    if src_path == nil or bin_path == nil or out == nil then return err.LDG_ERR_FUNC_ARG_NULL end

    out.code = 0
    out.ln = {}

    ok, proc = pcall(vim.system, { boxie_asm.BOXIE_ASM_NASM, boxie_asm.BOXIE_ASM_NASM_FMT_FLAG, boxie_asm.BOXIE_ASM_NASM_FMT, boxie_asm.BOXIE_ASM_NASM_OUT_FLAG, bin_path, src_path }, { text = true })
    if not ok then return err.LDG_ERR_NOT_FOUND end

    run = proc:wait()
    out.code = run.code
    out.ln = vim.split(run.stderr or "", boxie_asm.BOXIE_ASM_HEX_LF, { trimempty = true })

    if run.code ~= boxie_asm.BOXIE_ASM_NASM_OK then return err.LDG_ERR_INVALID end

    return err.LDG_ERR_AOK
end

function boxie_asm.boxie_asm_quickfix_set(ln)
    if ln == nil then return err.LDG_ERR_FUNC_ARG_NULL end

    if vim.fn.setqflist({}, boxie_asm.BOXIE_ASM_QUICKFIX_REPLACE, { title = boxie_asm.BOXIE_ASM_QUICKFIX_TITLE, lines = ln, efm = boxie_asm.BOXIE_ASM_QUICKFIX_ERRORFORMAT }) ~= boxie_asm.BOXIE_ASM_QUICKFIX_OK then return err.LDG_ERR_INVALID end

    return err.LDG_ERR_AOK
end

function boxie_asm.boxie_asm_bin_rd(path, out)
    local file = nil
    local buff = nil

    if path == nil or out == nil then return err.LDG_ERR_FUNC_ARG_NULL end

    out.buff = ""

    file = io.open(path, boxie_asm.BOXIE_ASM_RD_MODE)
    if file == nil then return err.LDG_ERR_IO_OPEN end

    buff = file:read(boxie_asm.BOXIE_ASM_RD_ALL)

    if not file:close() then return err.LDG_ERR_IO_CLOSE end

    if buff == nil then return err.LDG_ERR_IO_RD end

    out.buff = buff

    return err.LDG_ERR_AOK
end

function boxie_asm.boxie_asm_img_build(buff, out)
    local len = 0

    if buff == nil or out == nil then return err.LDG_ERR_FUNC_ARG_NULL end

    out.img = {}
    len = #buff

    if len == 0 then return err.LDG_ERR_EMPTY end

    if len > boxie_asm.BOXIE_ASM_RST_VEC_OFF then return err.LDG_ERR_OVERFLOW end

    for idx = 0, boxie_asm.BOXIE_ASM_IMG_SIZE - 1 do
        out.img[idx] = boxie_asm.BOXIE_ASM_PAD_BYTE
    end

    for idx = 0, len - 1 do
        out.img[idx] = string.byte(buff, idx + boxie_asm.BOXIE_ASM_LUA_IDX_BASE)
    end

    for idx = 0, #boxie_asm.BOXIE_ASM_RST_JMP - 1 do
        out.img[boxie_asm.BOXIE_ASM_RST_VEC_OFF + idx] = boxie_asm.BOXIE_ASM_RST_JMP[idx + boxie_asm.BOXIE_ASM_LUA_IDX_BASE]
    end

    return err.LDG_ERR_AOK
end

function boxie_asm.boxie_asm_hex_fmt(img, out)
    local ln = {}

    if img == nil or out == nil then return err.LDG_ERR_FUNC_ARG_NULL end

    out.text = ""
    ln[boxie_asm.BOXIE_ASM_LUA_IDX_BASE] = boxie_asm.BOXIE_ASM_HEX_ORIG

    for idx = 0, boxie_asm.BOXIE_ASM_IMG_SIZE - 1 do
        ln[idx + boxie_asm.BOXIE_ASM_LUA_IDX_BASE + boxie_asm.BOXIE_ASM_HEX_HDR_LN] = string.format(boxie_asm.BOXIE_ASM_HEX_BYTE_FMT, img[idx])
    end

    out.text = table.concat(ln, boxie_asm.BOXIE_ASM_HEX_LF) .. boxie_asm.BOXIE_ASM_HEX_LF

    return err.LDG_ERR_AOK
end

function boxie_asm.boxie_asm_hex_path_get(src_path, hex_dir, out)
    local dir = ""
    local stem = ""

    if src_path == nil or out == nil then return err.LDG_ERR_FUNC_ARG_NULL end

    out.path = ""
    stem = vim.fn.fnamemodify(src_path, boxie_asm.BOXIE_ASM_STEM_MOD)

    if stem == "" then return err.LDG_ERR_FUNC_ARG_INVALID end

    dir = hex_dir
    if dir == nil then dir = vim.fn.fnamemodify(src_path, boxie_asm.BOXIE_ASM_DIR_MOD) end

    out.path = vim.fs.joinpath(dir, stem .. boxie_asm.BOXIE_ASM_HEX_EXT)

    return err.LDG_ERR_AOK
end

function boxie_asm.boxie_asm_hex_wr(path, text)
    local temporary = ""
    local file = nil

    if path == nil or text == nil then return err.LDG_ERR_FUNC_ARG_NULL end

    temporary = path .. boxie_asm.BOXIE_ASM_TEMPORARY_EXT

    file = io.open(temporary, boxie_asm.BOXIE_ASM_WR_MODE)
    if file == nil then return err.LDG_ERR_IO_OPEN end

    if not file:write(text) then
        if not file:close() then return err.LDG_ERR_IO_CLOSE end

        return err.LDG_ERR_IO_WR
    end

    if not file:close() then return err.LDG_ERR_IO_CLOSE end

    if not os.rename(temporary, path) then return err.LDG_ERR_IO_WR end

    return err.LDG_ERR_AOK
end

function boxie_asm.boxie_asm_file_assemble(src_path, conf, out)
    local nasm = { code = 0, ln = {} }
    local bin = { buff = "" }
    local img = { img = {} }
    local hex = { text = "" }
    local dst = { path = "" }
    local bin_path = ""
    local res = 0

    if src_path == nil or conf == nil or out == nil then return err.LDG_ERR_FUNC_ARG_NULL end

    out.path = ""
    out.diag_count = 0
    bin_path = vim.fn.tempname() .. boxie_asm.BOXIE_ASM_BIN_EXT

    res = boxie_asm.boxie_asm_nasm_run(src_path, bin_path, nasm)
    if res == err.LDG_ERR_NOT_FOUND then return res end

    out.diag_count = #nasm.ln

    if res ~= err.LDG_ERR_AOK then
        if boxie_asm.boxie_asm_quickfix_set(nasm.ln) ~= err.LDG_ERR_AOK then return res end

        return res
    end

    res = boxie_asm.boxie_asm_quickfix_set(nasm.ln)
    if res ~= err.LDG_ERR_AOK then return res end

    res = boxie_asm.boxie_asm_bin_rd(bin_path, bin)
    if res ~= err.LDG_ERR_AOK then return res end

    res = boxie_asm.boxie_asm_img_build(bin.buff, img)
    if res ~= err.LDG_ERR_AOK then return res end

    res = boxie_asm.boxie_asm_hex_fmt(img.img, hex)
    if res ~= err.LDG_ERR_AOK then return res end

    res = boxie_asm.boxie_asm_hex_path_get(src_path, conf.hex_dir, dst)
    if res ~= err.LDG_ERR_AOK then return res end

    res = boxie_asm.boxie_asm_hex_wr(dst.path, hex.text)
    if res ~= err.LDG_ERR_AOK then return res end

    out.path = dst.path

    return err.LDG_ERR_AOK
end

return boxie_asm

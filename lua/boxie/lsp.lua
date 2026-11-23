local err = require("boxie.err")
local notify = require("boxie.notify")

local boxie_lsp = {
    BOXIE_LSP_NAME = "asm_lsp",
    BOXIE_LSP_MASON_PKG = "asm-lsp",
    BOXIE_LSP_MASON_REGISTRY = "mason-registry",
    BOXIE_LSP_LSPCONFIG = "lspconfig",
    BOXIE_LSP_FILETYPE = { "nasm", "asm" },
    BOXIE_LSP_CONF_SUBDIR = "asm-lsp",
    BOXIE_LSP_CONF_FILE = ".asm-lsp.toml",
    BOXIE_LSP_CONF_TEXT = "[default_config]\nversion = \"0.10.0\"\nassembler = \"nasm\"\ninstruction_set = \"x86\"\n\n[default_config.opts]\ncompiler = \"nasm\"\ncompile_flags_txt = []\ndiagnostics = true\ndefault_diagnostics = false\n",
    BOXIE_LSP_XDG_FALLBACK = ".config",
    BOXIE_LSP_MKDIR_PARENT = "p",
    BOXIE_LSP_WR_MODE = "wb",
    BOXIE_LSP_VIM_TRUE = 1,
    BOXIE_LSP_PKG_MISSING_FMT = "Boxie: Mason has no package; pkg: %s",
    BOXIE_LSP_PKG_INSTALL_FMT = "Boxie: installing through Mason; pkg: %s",
}

function boxie_lsp.boxie_lsp_pkg_ensure()
    local ok = false
    local registry = nil

    ok, registry = pcall(require, boxie_lsp.BOXIE_LSP_MASON_REGISTRY)
    if not ok then return err.LDG_ERR_NOT_FOUND end

    registry.refresh(function()
        local pkg_ok = false
        local pkg = nil

        pkg_ok, pkg = pcall(registry.get_package, boxie_lsp.BOXIE_LSP_MASON_PKG)

        if not pkg_ok then
            if notify.boxie_notify_put(string.format(boxie_lsp.BOXIE_LSP_PKG_MISSING_FMT, boxie_lsp.BOXIE_LSP_MASON_PKG), vim.log.levels.WARN) ~= err.LDG_ERR_AOK then return end
            return
        end

        if pkg:is_installed() then return end

        if notify.boxie_notify_put(string.format(boxie_lsp.BOXIE_LSP_PKG_INSTALL_FMT, boxie_lsp.BOXIE_LSP_MASON_PKG), vim.log.levels.INFO) ~= err.LDG_ERR_AOK then return end
        pkg:install()
    end)

    return err.LDG_ERR_AOK
end

function boxie_lsp.boxie_lsp_conf_wr()
    local base = ""
    local dir = ""
    local path = ""
    local file = nil

    base = vim.env.XDG_CONFIG_HOME
    if base == nil or base == "" then base = vim.fs.joinpath(vim.env.HOME, boxie_lsp.BOXIE_LSP_XDG_FALLBACK) end

    dir = vim.fs.joinpath(base, boxie_lsp.BOXIE_LSP_CONF_SUBDIR)
    path = vim.fs.joinpath(dir, boxie_lsp.BOXIE_LSP_CONF_FILE)

    if vim.uv.fs_stat(path) ~= nil then return err.LDG_ERR_AOK end

    if vim.fn.mkdir(dir, boxie_lsp.BOXIE_LSP_MKDIR_PARENT) ~= boxie_lsp.BOXIE_LSP_VIM_TRUE then return err.LDG_ERR_IO_WR end

    file = io.open(path, boxie_lsp.BOXIE_LSP_WR_MODE)
    if file == nil then return err.LDG_ERR_IO_OPEN end

    if not file:write(boxie_lsp.BOXIE_LSP_CONF_TEXT) then
        if not file:close() then return err.LDG_ERR_IO_CLOSE end

        return err.LDG_ERR_IO_WR
    end

    if not file:close() then return err.LDG_ERR_IO_CLOSE end

    return err.LDG_ERR_AOK
end

function boxie_lsp.boxie_lsp_en()
    local ok = false
    local lspconfig = nil

    ok, lspconfig = pcall(require, boxie_lsp.BOXIE_LSP_LSPCONFIG)
    if not ok then return err.LDG_ERR_NOT_FOUND end

    if vim.lsp.config ~= nil and vim.lsp.enable ~= nil then
        vim.lsp.config(boxie_lsp.BOXIE_LSP_NAME, { filetypes = boxie_lsp.BOXIE_LSP_FILETYPE })
        vim.lsp.enable(boxie_lsp.BOXIE_LSP_NAME)
        return err.LDG_ERR_AOK
    end

    lspconfig[boxie_lsp.BOXIE_LSP_NAME].setup({ filetypes = boxie_lsp.BOXIE_LSP_FILETYPE })

    return err.LDG_ERR_AOK
end

return boxie_lsp

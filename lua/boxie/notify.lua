local err = require("boxie.err")

local boxie_notify = {
    BOXIE_NOTIFY_TITLE = "Boxie",
    BOXIE_NOTIFY_TIMEOUT = 15000,
}

function boxie_notify.boxie_notify_put(msg, lvl)
    if msg == nil or lvl == nil then return err.LDG_ERR_FUNC_ARG_NULL end

    vim.schedule(function() vim.notify(msg, lvl, { title = boxie_notify.BOXIE_NOTIFY_TITLE, timeout = boxie_notify.BOXIE_NOTIFY_TIMEOUT }) end)

    return err.LDG_ERR_AOK
end

return boxie_notify

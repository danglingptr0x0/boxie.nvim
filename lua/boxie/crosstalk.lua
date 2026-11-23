local err = require("boxie.err")
local notify = require("boxie.notify")

local boxie_crosstalk = {
    BOXIE_CROSSTALK_LOG_DEFAULT = "/mnt/c/Program Files (x86)/Steam/steamapps/common/crosstalk/crosstalk.log",
    BOXIE_CROSSTALK_TASKLIST = "tasklist.exe",
    BOXIE_CROSSTALK_TASKLIST_FILTER_FLAG = "/FI",
    BOXIE_CROSSTALK_TASKLIST_FILTER = "IMAGENAME eq crosstalk.exe",
    BOXIE_CROSSTALK_TASKLIST_NO_HDR_FLAG = "/NH",
    BOXIE_CROSSTALK_EXE = "crosstalk.exe",
    BOXIE_CROSSTALK_GREP = "grep",
    BOXIE_CROSSTALK_GREP_TEXT_FLAG = "-a",
    BOXIE_CROSSTALK_GREP_FIXED_FLAG = "-F",
    BOXIE_CROSSTALK_GREP_PATTERN_FLAG = "-e",
    BOXIE_CROSSTALK_RELOAD_OK = "fpga: mem reloaded from disk",
    BOXIE_CROSSTALK_RELOAD_FAIL = "fpga: mem reload failed",
    BOXIE_CROSSTALK_TIMESTAMP_PATTERN = "^(%d+)",
    BOXIE_CROSSTALK_LN_PATTERN = "[^\n]+",
    BOXIE_CROSSTALK_EXIT_OK = 0,
    BOXIE_CROSSTALK_GREP_NO_MATCH = 1,
    BOXIE_CROSSTALK_POLL_PERIOD = 500,
    BOXIE_CROSSTALK_POLL_MAX = 6,
    BOXIE_CROSSTALK_POLL_STEP = 1,
    BOXIE_CROSSTALK_POLL_FIRST = 0,
    BOXIE_CROSSTALK_SLACK = 1000,
    BOXIE_CROSSTALK_MS_PER_SEC = 1000,
    BOXIE_CROSSTALK_US_PER_MS = 1000,
    BOXIE_CROSSTALK_FIND_PLAIN_START = 1,
    BOXIE_CROSSTALK_HIT_NONE = 0,
    BOXIE_CROSSTALK_HIT_OK = 1,
    BOXIE_CROSSTALK_HIT_FAIL = 2,
    BOXIE_CROSSTALK_NOT_RUNNING_TEXT = "Boxie: Crosstalk is not running; the hex is ready for it",
    BOXIE_CROSSTALK_RELOADED_TEXT = "Boxie: Crosstalk reloaded the hex; reset to run it (poke btnrst 0, poke btnrst 1)",
    BOXIE_CROSSTALK_RELOAD_FAIL_TEXT = "Boxie: Crosstalk could not load the hex; see crosstalk.log",
    BOXIE_CROSSTALK_PENDING_TEXT = "Boxie: Crosstalk has not reloaded the hex yet",
    BOXIE_CROSSTALK_NO_LOG_FMT = "Boxie: no crosstalk.log; path: %s",
}

function boxie_crosstalk.boxie_crosstalk_now_get(out)
    local whole = 0
    local fraction = 0

    if out == nil then return err.LDG_ERR_FUNC_ARG_NULL end

    whole, fraction = vim.uv.gettimeofday()
    if whole == nil then return err.LDG_ERR_INVALID end

    out.time = whole * boxie_crosstalk.BOXIE_CROSSTALK_MS_PER_SEC + math.floor(fraction / boxie_crosstalk.BOXIE_CROSSTALK_US_PER_MS)

    return err.LDG_ERR_AOK
end

function boxie_crosstalk.boxie_crosstalk_hit_get(text, wr_time, out)
    local timestamp = nil

    if text == nil or wr_time == nil or out == nil then return err.LDG_ERR_FUNC_ARG_NULL end

    out.hit = boxie_crosstalk.BOXIE_CROSSTALK_HIT_NONE

    for ln in string.gmatch(text, boxie_crosstalk.BOXIE_CROSSTALK_LN_PATTERN) do
        timestamp = tonumber(string.match(ln, boxie_crosstalk.BOXIE_CROSSTALK_TIMESTAMP_PATTERN))

        if timestamp ~= nil and timestamp + boxie_crosstalk.BOXIE_CROSSTALK_SLACK >= wr_time then
            if string.find(ln, boxie_crosstalk.BOXIE_CROSSTALK_RELOAD_FAIL, boxie_crosstalk.BOXIE_CROSSTALK_FIND_PLAIN_START, true) ~= nil then out.hit = boxie_crosstalk.BOXIE_CROSSTALK_HIT_FAIL end

            if string.find(ln, boxie_crosstalk.BOXIE_CROSSTALK_RELOAD_OK, boxie_crosstalk.BOXIE_CROSSTALK_FIND_PLAIN_START, true) ~= nil then out.hit = boxie_crosstalk.BOXIE_CROSSTALK_HIT_OK end
        end
    end

    return err.LDG_ERR_AOK
end

function boxie_crosstalk.boxie_crosstalk_log_poll(log_path, wr_time, attempt)
    local ok = false

    if log_path == nil or wr_time == nil or attempt == nil then return err.LDG_ERR_FUNC_ARG_NULL end

    ok = pcall(vim.system, { boxie_crosstalk.BOXIE_CROSSTALK_GREP, boxie_crosstalk.BOXIE_CROSSTALK_GREP_TEXT_FLAG, boxie_crosstalk.BOXIE_CROSSTALK_GREP_FIXED_FLAG, boxie_crosstalk.BOXIE_CROSSTALK_GREP_PATTERN_FLAG, boxie_crosstalk.BOXIE_CROSSTALK_RELOAD_OK, boxie_crosstalk.BOXIE_CROSSTALK_GREP_PATTERN_FLAG, boxie_crosstalk.BOXIE_CROSSTALK_RELOAD_FAIL, log_path }, { text = true }, function(run)
        local found = { hit = boxie_crosstalk.BOXIE_CROSSTALK_HIT_NONE }

        if run.code ~= boxie_crosstalk.BOXIE_CROSSTALK_EXIT_OK and run.code ~= boxie_crosstalk.BOXIE_CROSSTALK_GREP_NO_MATCH then
            if notify.boxie_notify_put(string.format(boxie_crosstalk.BOXIE_CROSSTALK_NO_LOG_FMT, log_path), vim.log.levels.WARN) ~= err.LDG_ERR_AOK then return end
            return
        end

        if boxie_crosstalk.boxie_crosstalk_hit_get(run.stdout or "", wr_time, found) ~= err.LDG_ERR_AOK then return end

        if found.hit == boxie_crosstalk.BOXIE_CROSSTALK_HIT_OK then
            if notify.boxie_notify_put(boxie_crosstalk.BOXIE_CROSSTALK_RELOADED_TEXT, vim.log.levels.INFO) ~= err.LDG_ERR_AOK then return end
            return
        end

        if found.hit == boxie_crosstalk.BOXIE_CROSSTALK_HIT_FAIL then
            if notify.boxie_notify_put(boxie_crosstalk.BOXIE_CROSSTALK_RELOAD_FAIL_TEXT, vim.log.levels.ERROR) ~= err.LDG_ERR_AOK then return end
            return
        end

        if attempt + boxie_crosstalk.BOXIE_CROSSTALK_POLL_STEP >= boxie_crosstalk.BOXIE_CROSSTALK_POLL_MAX then
            if notify.boxie_notify_put(boxie_crosstalk.BOXIE_CROSSTALK_PENDING_TEXT, vim.log.levels.INFO) ~= err.LDG_ERR_AOK then return end
            return
        end

        vim.defer_fn(function()
            if boxie_crosstalk.boxie_crosstalk_log_poll(log_path, wr_time, attempt + boxie_crosstalk.BOXIE_CROSSTALK_POLL_STEP) ~= err.LDG_ERR_AOK then return end
        end, boxie_crosstalk.BOXIE_CROSSTALK_POLL_PERIOD)
    end)

    if not ok then return err.LDG_ERR_NOT_FOUND end

    return err.LDG_ERR_AOK
end

function boxie_crosstalk.boxie_crosstalk_reload_ck(conf)
    local now = { time = 0 }
    local log_path = ""
    local ok = false
    local res = 0

    if conf == nil then return err.LDG_ERR_FUNC_ARG_NULL end

    res = boxie_crosstalk.boxie_crosstalk_now_get(now)
    if res ~= err.LDG_ERR_AOK then return res end

    log_path = conf.crosstalk_log or boxie_crosstalk.BOXIE_CROSSTALK_LOG_DEFAULT

    ok = pcall(vim.system, { boxie_crosstalk.BOXIE_CROSSTALK_TASKLIST, boxie_crosstalk.BOXIE_CROSSTALK_TASKLIST_FILTER_FLAG, boxie_crosstalk.BOXIE_CROSSTALK_TASKLIST_FILTER, boxie_crosstalk.BOXIE_CROSSTALK_TASKLIST_NO_HDR_FLAG }, { text = true }, function(run)
        if run.code ~= boxie_crosstalk.BOXIE_CROSSTALK_EXIT_OK or string.find(string.lower(run.stdout or ""), boxie_crosstalk.BOXIE_CROSSTALK_EXE, boxie_crosstalk.BOXIE_CROSSTALK_FIND_PLAIN_START, true) == nil then
            if notify.boxie_notify_put(boxie_crosstalk.BOXIE_CROSSTALK_NOT_RUNNING_TEXT, vim.log.levels.INFO) ~= err.LDG_ERR_AOK then return end
            return
        end

        if boxie_crosstalk.boxie_crosstalk_log_poll(log_path, now.time, boxie_crosstalk.BOXIE_CROSSTALK_POLL_FIRST) ~= err.LDG_ERR_AOK then return end
    end)

    if not ok then return err.LDG_ERR_NOT_FOUND end

    return err.LDG_ERR_AOK
end

return boxie_crosstalk

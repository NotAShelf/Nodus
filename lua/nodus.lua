local nodus = {}
local api = vim.api
local fn = vim.fn
local log = vim.log
local ui = vim.ui
local loop = vim.loop
local match_id = nil

--- User-defined configuration options for Nodus. The defaults should
--- be sufficient for most users, but can be customized using the `setup`
--- table in your configuration.
--- @type table
--- @class config
--- @field protocols string[]: Protocol identifiers to match links by
--- @field highlight_group string: Highlight group for matched links
--- @field ft string[]: File types for which matching will be enabled
nodus.config = {
    protocols = { "http://", "https://" },
    highlight_group = "NodusLinkHighlight",
    ft = { "text", "md", "markdown" }
}

--- Debounce a given function, ensuring that it is called only after
--- a specified delay.
--- @type function
--- @param fun function: The function to debounce
--- @param ms number: The debounce delay in milliseconds
--- @return function: The debounced function
local function debounce(fun, ms)
    local timer = loop.new_timer()
    return function()
        timer:stop()
        timer:start(ms, 0, vim.schedule_wrap(function() fun() end))
    end
end

--- Setup function for the plugin
--- @type function
--- @param user_config config: User-defined configuration options
--- @return nil
--- @see nodus.config
function nodus.setup(user_config)
    nodus.config = vim.tbl_extend("force", nodus.config, user_config or {})
    api.nvim_command("highlight " .. nodus.config.highlight_group .. " gui=underline")
    api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
        pattern = '*',
        group = api.nvim_create_augroup('NodusLinkOpener', {}),
        callback = debounce(function()
            require('nodus').highlight_link_under_cursor()
        end, 190) -- 190ms debounce delay
    })
end

--- Get the word currently under the cursor
--- @type function
--- @return string: The word under the cursor
--- @see is_filetype_allowed
local function get_word_under_cursor()
    local _, col = unpack(api.nvim_win_get_cursor(0))
    local line = api.nvim_get_current_line()
    local start_col = col
    local end_col = col
    -- expand left to the start of the word
    while start_col > 0 and line:sub(start_col, start_col):match("%S") do
        start_col = start_col - 1
    end
    start_col = start_col + 1
    -- expand right to the end of the word
    while end_col <= #line and line:sub(end_col, end_col):match("%S") do
        end_col = end_col + 1
    end
    return line:sub(start_col, end_col - 1)
end

--- Check if the filetype for the current buffer is in the list of allowed filetypes
--- for link opening and highlighting.
--- @type function
--- @return boolean true: if the filetype is allowed, false otherwise
--- @return string: The filetype of the current buffer, returned regardless of status
local function is_filetype_allowed()
    local ft = api.nvim_buf_get_option(0, 'filetype')
    for _, allowed_ft in ipairs(nodus.config.ft) do
        if ft == allowed_ft then
            return true, ft
        end
    end
    return false, ft
end

--- Match links that fit the criteria of a matching link and open them using
--- `vim.ui.open()` when the function is called. If the target link is *not*
--- an URL that can be opened, then return an error with the INFO log level.
--- @type function
--- @return nil
--- @see vim.ui.open
function nodus.open_link_under_cursor()
    local allowed, ft = is_filetype_allowed()
    if not allowed then
        vim.notify("Link opening is not supported for this file type: " .. ft, log.levels.INFO)
        return
    end
    -- open link only if it is inside < > and starts with a valid protocol
    local word = get_word_under_cursor()
    if word:match("^<http[s]?://[^>]+>$") then
        local link = word:sub(2, -2)
        ui.open(link)
    else
        vim.notify("No valid link under the cursor", log.levels.INFO)
    end
end

--- Highlight valid links under the cursor if the current buffer is in the list of
--- allowed filetypes. This should help the user tell what is a valid link that
--- can be opened, and what is not. The highlight group can be customized using
--- the `highlight_group` configuration option in the `setup` table.
--- @return nil
function nodus.highlight_link_under_cursor()
    if not is_filetype_allowed() then
        -- clear any previous match if it exists
        if match_id ~= nil then
            fn.matchdelete(match_id)
            match_id = nil
        end
        return
    end
    local word = get_word_under_cursor()
    -- clear any previous match if it exists
    if match_id ~= nil then
        fn.matchdelete(match_id)
        match_id = nil
    end
    -- only highlight if the word is a valid link inside < >
    if word:match("^<http[s]?://[^>]+>$") then
        match_id = fn.matchadd(nodus.config.highlight_group, "\\V" .. fn.escape(word, "\\"))
    end
end

return nodus

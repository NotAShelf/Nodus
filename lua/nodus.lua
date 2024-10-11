local M = {}
local api = vim.api
local fn = vim.fn
local log = vim.log
local match_id = nil

-- default configuration
M.config = {
    opener_path = "xdg-open",               -- default path to xdg-open, mainly for Nix users :)
    protocols = { "http://", "https://" },  -- default protocols to match
    highlight_group = "NodusLinkHighlight", -- highlight group for matching links
    ft = { "text", "md", "markdown" }       -- file types for which matching will be enabled
}

function M.setup(user_config)
    M.config = vim.tbl_extend("force", M.config, user_config or {})
    api.nvim_command("highlight " .. M.config.highlight_group .. " gui=underline")

    api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
        pattern = '*',
        group = api.nvim_create_augroup('NodusLinkOpener', {}),
        callback = function()
            require('nodus').highlight_link_under_cursor()
        end,
    })
end

local function open_link(link)
    fn.jobstart({ M.config.opener_path, link }, { detach = true })
end

-- Get the word under the cursor.
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

-- Check if the current filetype is allowed for link opening and highlighting
-- by checking if it is in the list of allowed filetypes. If it is not, return
-- false, otherwise return true.
local function is_filetype_allowed()
    local ft = api.nvim_buf_get_option(0, 'filetype')
    for _, allowed_ft in ipairs(M.config.ft) do
        if ft == allowed_ft then
            return true, ft
        end
    end
    return false, ft
end

-- Match links that fit our criteria and open them using open_link() when the
-- function is called. If the target link is *not* an URL that can be opened,
-- then return an error with the INFO log level.
function M.open_link_under_cursor()
    local allowed, ft = is_filetype_allowed()
    if not allowed then
        vim.notify("Link opening is not supported for this file type: " .. ft, log.levels.INFO)
        return
    end

    -- Open link only if it is inside < > and starts with a valid protocol
    local word = get_word_under_cursor()
    if word:match("^<http[s]?://[^>]+>$") then
        local link = word:sub(2, -2)
        open_link(link)
    else
        vim.notify("No valid link under the cursor", log.levels.INFO)
    end
end

-- Also implement highlighting for valid links. This should help the user tell
-- what is a valid link that can be opened, and what is not.
function M.highlight_link_under_cursor()
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
        match_id = fn.matchadd(M.config.highlight_group, "\\V" .. fn.escape(word, "\\"))
    end
end

return M

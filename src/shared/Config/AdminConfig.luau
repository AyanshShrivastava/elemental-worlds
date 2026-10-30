--!strict
--[[
    Elemental Worlds: Admin & Owner Permission Configuration
    Owner identification by immutable numeric UserId (6225357795).
    Strict separation between Owner powers and Admin management commands.
]]

local AdminConfig = {
    -- Owner numeric UserId (coolzgamer9)
    OWNER_USER_ID = 6225357795 :: number,

    -- Initial Admin Allowlist (by username, resolved to UserIds at runtime)
    INITIAL_ADMIN_USERNAMES = {
        -- Add admin usernames here (e.g., "AdminUser1")
    } :: { string },

    -- Owner-only commands (cannot be executed by admins)
    OWNER_ONLY_COMMANDS = {
        ["/ban"] = true,
        ["/unban"] = true,
        ["/kick"] = true,
        ["/addadmin"] = true,
        ["/removeadmin"] = true,
        ["/setrng"] = true,
        ["/resetrng"] = true,
        ["/testrng"] = true,
        ["/kill"] = true,
        ["/tp"] = true,
        ["/bring"] = true,
        ["/setcharges"] = true,
    } :: { [string]: boolean },

    -- Admin-permitted commands
    ADMIN_COMMANDS = {
        ["/givelevel"] = true,
        ["/removelevel"] = true,
        ["/setlevel"] = true,
        ["/givecharges"] = true,
        ["/removecharges"] = true,
        ["/giveelement"] = true,
        ["/removeelement"] = true,
        ["/giveitem"] = true,
        ["/removeitem"] = true,
        ["/givespins"] = true,
        ["/heal"] = true,
        ["/raid"] = true,
        ["/event"] = true,
        ["/announce"] = true,
    } :: { [string]: boolean },
}

return table.freeze(AdminConfig)

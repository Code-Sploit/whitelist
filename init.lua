local whitelist = {}
local admin_name = minetest.settings:get("name")
local worlddir = minetest.get_worldpath()

local WFILENAME = "/whitelist.txt"

local function load_whitelist()
	local wfile, err = io.open(worlddir .. WFILENAME, "r")

	if err then
		return
	end
	
	for line in wfile:lines() do
		whitelist[line] = true
	end
	
	wfile:close()
end

local function save_whitelist()
	local wfile, err = io.open(worlddir .. WFILENAME, "w")

	if err then
		return
	end

	for entry in pairs(whitelist) do
		wfile:write(entry .. "\n")
	end

	wfile:close()
end

load_whitelist()

minetest.register_on_prejoinplayer(function(name, ip)
	if not minetest.settings:get_bool("enable_whitelist") then
		return
	end

	if name == "singleplayer" or name == admin_name or whitelist[name] or whitelist[ip] then
		return
	end

	local whitelist_error_message = minetest.settings:get("whitelist_error_message") or "You are not whitelisted!"

	return whitelist_error_message
end)

minetest.register_privilege("whitelist", {
	description = "Allows to use /whitelist.",
	give_to_singleplayer = false,
	give_to_admin = true
})

minetest.register_chatcommand("whitelist", {
	params = "{add|del} <nick|ip> | {on|off}",
	help = "Manipulate the whitelist. (Requires the whitelist privilege)",
	privs = {whitelist = true},
	
	func = function(name, param)
		local action = param:split(" ")[1]
		local target

		if action ~= "on" and action ~= "off" and action ~= "list" then
			target = param:split(" ")[2]
		end

		if action == "add" then
			if whitelist[target] then
				return false, target .. " is already on the whitelist."
			end

			whitelist[target] = true
			
			save_whitelist()

			return true, "Added " .. target .. " to the whitelist."
		elseif action == "remove" then
			if not whitelist[target] then
				return false, target .. " is not on the whitelist."
			end
			
			whitelist[target] = nil
			
			save_whitelist()
			
			return true, "Removed " .. target .. " from the whitelist."
		elseif action == "on" then
			if minetest.settings:get_bool("enable_whitelist") then
				return false, "Whitelist is already enabled!"
			end

			minetest.settings:set_bool("enable_whitelist", true)

			return true, "Enabled the whitelist"
		elseif action == "off" then
			if not minetest.settings:get_bool("enable_whitelist") then
				return false, "Whitelist is already disabled!"
			end

			minetest.settings:set_bool("enable_whitelist", false)

			return true, "Disabled the whitelist!"
		elseif action == "list" then
			local whitelisted_count = 0
			local string_to_return = ""

			for entry in pairs(whitelist) do
				if whitelist == nil then
					break
				end

				whitelisted_count = whitelisted_count + 1

				string_to_return = string_to_return .. entry .. ", "
			end

			string_to_return = string_to_return:sub(1, -3)

			return true, "There are currently " .. tostring(whitelisted_count) .. " people whitelisted: " .. string_to_return
		else
			return false, "Invalid action."
		end
	end,
})

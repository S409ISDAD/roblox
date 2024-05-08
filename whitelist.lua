--// Parcel Whitelist SDK
--// Written by charlie.#3333 (https://charliea.dev - charliewithadot)
--// Updated: 09/12/2023 @ 10:41

--// Note: This is a LuaU script; it will not run in a regular Lua interpreter!

local httpService = game:GetService("HttpService")
local groupService = game:GetService("GroupService")
local runService = game:GetService("RunService")
local apiUrl = "https://whitelist.parcelroblox.com/v1/check"
local module = {}

-- Resolve the owner's id from the current place
--
-- returns number: The current place owner's id
function module:ResolveCurrentOwnerId(): number
	if game.CreatorType == Enum.CreatorType.Group then
		return groupService:GetGroupInfoAsync(game.CreatorId).Owner.Id
	else
		return game.CreatorId
	end
end

-- Returns true if the specified user (or game owner, if a user id isn't specified) owns a copy of a specific product
--
-- hubId (string): The target hub id
-- productId (string): The target product id
-- targetUserId (number?): The id of the Roblox user to check. If blank/nil/empty, the current game's owners's id will be used
--
-- returns boolean: true if the user owns the product, otherwise false
function module:Whitelist(hubId: string, productId: string, targetUserId: number?): boolean
	if typeof(hubId) ~= "string" then error("[Parcel Whitelist SDK]: hubId must be a string") end
	if typeof(productId) ~= "string" then error("[Parcel Whitelist SDK]: productId must be a string") end
	
	if runService:IsClient() then error("[Parcel Whitelist SDK]: The whitelist SDK does not work on the client/in LocalScripts") end
	
	if typeof(targetUserId) == "nil" then
		targetUserId = module:ResolveCurrentOwnerId()
	elseif typeof(targetUserId) ~= "number" then error("[Parcel Whitelist SDK]: targetUserId must be a number or nil") end
	
	if typeof(productId) ~= "string" then error("[Parcel Whitelist SDK]: productId must be a string") end
	
	local url = apiUrl .. "?hubID=" .. httpService:UrlEncode(hubId) .. "&productID=" .. httpService:UrlEncode(productId) .. "&robloxID=" .. targetUserId
	local ok, response = pcall(httpService.RequestAsync, httpService, { Url = url --[[ no secret keys here! ]] })
	
	if ok then
		if not response.Success then
			error("[Parcel Whitelist SDK]: Invalid response received from Parcel (Status code: " .. tostring(response.StatusCode) .. ")")
		end

		local body = httpService:JSONDecode(response.Body)

		return body.details.owned or false
	else
		if response == "Http requests are not enabled. Enable via game settings" then
			warn("[Parcel Whitelist SDK]: Http requests are disabled")
			return false
		else
			error("[Parcel Whitelist SDK]: Request Error: " .. response)
		end
	end
end

-- myPod v1-like whitelist function. Eases the transition from the myPod v1 whitelist to Parcel
--
-- hubId (string): The target hub id
-- productId (string): The target product id
-- targetUserId (number?): The id of the user to check. If blank/nil/empty, the current game's owners's id will be used
function module:GetAsync(hubId: string, productId: string, targetUserId: string, callback: void)
	callback(module:Whitelist(hubId, productId, targetUserId))
end

return setmetatable({}, { __index = module, __newindex = function() end, __metatable = false })

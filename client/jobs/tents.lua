local _searching = false
local _searchedTents = {}

local function GetSearchDuration()
	return math.random(TentSearchConfig.SearchDuration.min, TentSearchConfig.SearchDuration.max) * 1000
end

local function AddTentTargets()
	for _, model in ipairs(TentSearchConfig.TentModels) do
		Targeting:AddObject(model, "tent", {
			{
				icon = "tent",
				text = "Search Tent",
				event = "TentSearch:Client:SearchTent",
				isEnabled = function(data, entity)
					return not _searching
				end,
			},
		}, 2.0)
	end
end

AddEventHandler("Labor:Client:Setup", function()
	CreateThread(function()
		while TentSearchConfig == nil do
			Wait(100)
		end

		AddTentTargets()
	end)
end)

AddEventHandler("TentSearch:Client:SearchTent", function(entity, data)
	if _searching then
		return
	end

	if TentSearchConfig == nil then
		Notification:Error("Tent Search Config Missing")
		return
	end

	local entityId = entity and entity.entity or nil
	if not entityId or not DoesEntityExist(entityId) then
		return
	end

	if not NetworkGetEntityIsNetworked(entityId) then
		NetworkRegisterEntityAsNetworked(entityId)
		Wait(0)
	end

	local netId = NetworkGetNetworkIdFromEntity(entityId)
	if not netId or netId == 0 then
		return
	end

	if _searchedTents[netId] then
		Notification:Error("This tent has already been searched")
		return
	end

	_searching = true
	TaskTurnPedToFaceEntity(LocalPlayer.state.ped, entityId, 500)
	Wait(250)

	Progress:Progress({
		name = "tent_search_action",
		duration = GetSearchDuration(),
		label = "Searching Tent",
		useWhileDead = false,
		canCancel = true,
		vehicle = false,
		controlDisables = {
			disableMovement = true,
			disableCarMovement = true,
			disableCombat = true,
		},
		animation = {
			animDict = "amb@prop_human_bum_bin@base",
			anim = "base",
			flags = 49,
		},
	}, function(cancelled)
		_searching = false
		if cancelled then
			return
		end

		Callbacks:ServerCallback("TentSearch:SearchTent", netId, function(success, reason)
			if success then
				_searchedTents[netId] = true
				return
			end

			if reason == "already_searched" then
				_searchedTents[netId] = true
				Notification:Error("This tent has already been searched")
				return
			end

			Notification:Error("Unable To Search Tent")
		end)
	end)
end)
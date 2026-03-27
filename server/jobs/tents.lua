
local _JOB = "TentSearch"
local _searchedTents = {}

AddEventHandler("Labor:Server:Startup", function()
	Reputation:Create(_JOB, "Tent Searching", {
		{ label = "Rank 1", value = 1000 },
		{ label = "Rank 2", value = 2500 },
		{ label = "Rank 3", value = 5000 },
		{ label = "Rank 4", value = 10000 },
		{ label = "Rank 5", value = 25000 },
	})

	Callbacks:RegisterServerCallback("TentSearch:SearchTent", function(source, data, cb)
		local char = Fetch:Source(source):GetData("Character")
		if char == nil or TentSearchConfig == nil then
			cb(false)
			return
		end

		if _searchedTents[data] then
			cb(false, "already_searched")
			return
		end

		local repLevel = Reputation:GetLevel(source, _JOB)
		local lootSet = TentSearchConfig.LootByRep[1].loot
		for _, entry in ipairs(TentSearchConfig.LootByRep) do
			if repLevel >= entry.level then
				lootSet = entry.loot
			else
				break
			end
		end

		_searchedTents[data] = true
		Loot:CustomSetWithCount(lootSet, char:GetData("SID"), 1)
		Reputation.Modify:Add(source, _JOB, TentSearchConfig.RepGain)
		cb(true)
	end)
end)
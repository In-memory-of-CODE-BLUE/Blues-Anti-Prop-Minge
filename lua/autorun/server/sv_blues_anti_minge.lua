AddCSLuaFile("blues_anti_minge_config.lua")
AddCSLuaFile("blues_anti_minge/cl_bam.lua")
AddCSLuaFile("blues_anti_minge/sh_bam.lua")

include("blues_anti_minge_config.lua")
include("blues_anti_minge/sh_bam.lua")

util.AddNetworkString("BAM_CREATE_PROPERTY")
util.AddNetworkString("BAM_UPDATE_PROPERTY_DATA")
util.AddNetworkString("BAM_RENAME")
util.AddNetworkString("BAM_DELETE_PROPERTY")
util.AddNetworkString("BAM_ADD_ZONE")
util.AddNetworkString("BAM_DELETE_ZONE")
util.AddNetworkString("BAM_ADD_DOOR")
util.AddNetworkString("BAM_REMOVE_DOOR")
util.AddNetworkString("BAM_ADD_JOB")
util.AddNetworkString("BAM_REMOVE_JOB")
util.AddNetworkString("BAM_SAVE")
util.AddNetworkString("BAM_REQUEST_MAP_DATA")
util.AddNetworkString("BAM_NOTIFICATIOn")
util.AddNetworkString("BAM_AUTHORISE_ZONE_UPDATE")
util.AddNetworkString("BAM_TOGGLE_DRAW_AUTH_ZONE")

//Global table containing all the properties
BAM_PROPERTIES = {}

local pMeta = FindMetaTable("Player")

//Returns true if the user can change BAM stuff or false if not (Used internally)
local function AuthoriseBamUser(user)
	if IsValid(user) and table.HasValue(BAM_CONFIG.AuthorisedRanks, user:GetUserGroup()) then
		return true
	end
	return false //Failed check
end

//This function sends all the clients the new propertydata
//Use BAM_UpdateClient(ply) to update a single client (Like when a new player joins)
function BAM_UpdateClients()
	net.Start("BAM_UPDATE_PROPERTY_DATA")
	net.WriteTable(BAM_PROPERTIES)
	net.Broadcast()
end

//Sends the property data to a single client
function BAM_UpdateClient(ply)
	net.Start("BAM_UPDATE_PROPERTY_DATA")
	net.WriteTable(BAM_PROPERTIES)
	net.Send(ply)
end

//Saves all the data to bam/mapname.txt
function BAM_SaveProperties()
	if not file.Exists("bam" , "DATA") then
		file.CreateDir("bam")
	end

	local data = {}
	for k ,v in pairs(BAM_PROPERTIES) do
		data[k] = {}
		data[k].name = v.name
		data[k].zones = v:GetZones()
		data[k].jobs = v:GetJobs()
		data[k].doors = {}
		for a, b in pairs(v:GetDoors()) do
			data[k].doors[a] = b.doorID
		end
	end
	data = util.TableToJSON(data)
	file.Write("bam/"..game.GetMap()..".txt", data)
end

//Loads up all the BAM data and fixes it all
//So its useable with the addon (Such as entities and meta's)
function BAM_LoadProperties()
	local data = file.Read("bam/"..game.GetMap()..".txt", data)
	if data ~= nil then
		data = util.JSONToTable(data)
		for k, v in pairs(data) do
			BAM_PROPERTIES[k] = setmetatable({}, propertyMeta)
			BAM_PROPERTIES[k].name = v.name

			//Zones
			BAM_PROPERTIES[k].zones = {}
			for a, b in pairs(v.zones) do
				BAM_PROPERTIES[k].zones[a] = b
			end

			//Doors
			BAM_PROPERTIES[k].doors = {}
			for a, b in pairs(v.doors) do
				BAM_PROPERTIES[k].doors[a] = {doorID = b, door = ents.GetMapCreatedEntity(b), pos = ents.GetMapCreatedEntity(b):GetPos()}
			end
		end
		BAM_FixBamMeta(BAM_PROPERTIES)

		//Now do the jobs
		for k, v in pairs(data) do
			BAM_PROPERTIES[k].jobs = {}
			for a, b in pairs(v.jobs) do 
				BAM_PROPERTIES[k]:AddJob(b.jobName)
			end
		end
		print("[BAM] Loaded map data for "..game.GetMap())
	else
		print("[BAM] No map data loaded as none was found. This is not an error but if you saved the map data and are getting this message please open a support ticket.")
	end
end

hook.Add( "InitPostEntity", "BAM_loadMapData", function()
	BAM_LoadProperties()
end)

hook.Add("PlayerInitialSpawn", "BAM_SendInitialMapData", function(ply)
	BAM_UpdateClient(ply)
end)

function pMeta:BAM_CheckIfInAuthoriseZone(pos)

	//If bypass then just be true.
	if table.HasValue(BAM_CONFIG.BypassRanks, self:GetUserGroup()) then
		return true
	end

	for k ,v in pairs(self.bam_authed_zones) do
		if pos:WithinAABox(v.pos1, v.pos2) then
			return true
		end
	end

	return false
end

//This will find a list of all zones the player is authorised to and store them
//in player.bam_authed_zones as a table of vectors
function pMeta:BAM_ConfiguredAuthorisedZones(blacklistDoor, jobID)
	//First we check there jobs to see if there jobs are on any of the lists :D
	local jobID = jobID or self:Team()
	local allowedZones = {}
	zoneIndex = 1

	//Next thing we will check is the doors we own
	//If we own a door thats belongs to a property then we will add the zones

	local doors = {} //Will contain a list of all doors the player is authorised with
	for k ,v in pairs(ents.GetAll()) do
		if v ~= blacklistDoor then
			if v.isDoor and v:isDoor() then
				local doorAdded = false
				//Check if we own or co own any doors on the map
				//If so add them to the doors table
				local data = v:getDoorData()
				if v:getDoorOwner() == self then
					table.insert(doors, v)
					doorAdded = true
				elseif data.extraOwners ~= nil then
					local extraOwners = v:getKeysCoOwners()
					for userID, allowed in pairs(extraOwners) do
						if allowed then
							if Player(userID) == self then
								table.insert(doors, v)
								doorAdded = true
							end
						end
					end
				end

				//Now instead check to see if our job
				//is already a owner of the door
				if not doorAdded then
					if v:getKeysDoorTeams() ~= nil then
						for x , y in pairs(v:getKeysDoorTeams()) do
							if x == self:Team() then
								table.insert(doors, v)
								break
							end
						end
					end
					if v:getKeysDoorGroup() ~= nil then
						local extraJobs = RPExtraTeamDoors[v:getKeysDoorGroup()]
						for i = 1 , #extraJobs do
							if extraJobs[i] == self:Team() then
								table.insert(doors, v)
								break
							end
						end
					end
				end
			end
		end
	end

	for k ,v in pairs(BAM_PROPERTIES) do
		local addedZones = false
		for a , b in pairs(v:GetJobs()) do
			if b.jobID == jobID then
				for x , y in pairs(v:GetZones()) do
					allowedZones[zoneIndex] = y
					zoneIndex = zoneIndex + 1
				end
				addedZones = true
				break //No need to do more now
			end
		end

		if not addedZones then
			//Now we check if the doors are a match
			for x , y in pairs(v:GetDoors()) do
				if y ~= blacklistDoor then
					if table.HasValue(doors, y.door) then
						for z , w in pairs(v:GetZones()) do
							allowedZones[zoneIndex] = w
							zoneIndex = zoneIndex + 1
						end
						break
					end
				end
			end
		end
	end 
	
	self.bam_authed_zones = allowedZones
	net.Start("BAM_AUTHORISE_ZONE_UPDATE")
	net.WriteTable(allowedZones)
	net.Send(self)
end

local timeSinceLastCheck = 0

//Checks prop positions
hook.Add("Think", "BAM_CheckProps", function()
	if CurTime() > timeSinceLastCheck then
		timeSinceLastCheck = CurTime() + BAM_CONFIG.UpdateRate
		local props = ents.FindByClass("prop_physics")
		for k, v in pairs(props) do
			if v.CPPIGetOwner then
				local owner = v:CPPIGetOwner()
				if owner ~= nil and owner:IsPlayer() then
					local propPos = v:GetPos()
					if owner:BAM_CheckIfInAuthoriseZone(propPos) and not BAM_CONFIG.UseOBB then
						v.bam_last_safe_pos = propPos
					else
						if BAM_CONFIG.UseOBB then
							local min = v:LocalToWorld(v:OBBMins() + Vector(5,5,5))
							local max = v:LocalToWorld(v:OBBMaxs() - Vector(5,5,5))
							local minIn = owner:BAM_CheckIfInAuthoriseZone(min)
							local maxIn = owner:BAM_CheckIfInAuthoriseZone(max)
							if minIn and maxIn then
								v.bam_last_safe_pos = v:GetPos()
							elseif v.bam_last_safe_pos ~= nil then
								if owner:BAM_CheckIfInAuthoriseZone(v.bam_last_safe_pos) then
									v:SetPos(v.bam_last_safe_pos)
									v:GetPhysicsObject():EnableMotion(false)
									net.Start("BAM_NOTIFICATIOn")
									net.WriteString("[BAM] "..BAM_CONFIG.TransaltePropLeaveBuildZone)
									net.Send(owner)
								else
									v:Remove()
									net.Start("BAM_NOTIFICATIOn")
									net.WriteString("[BAM] "..BAM_CONFIG.TranslatePropOutOfBounds)
									net.Send(owner)
								end
							else
								v:Remove()
								net.Start("BAM_NOTIFICATIOn")
								net.WriteString("[BAM] "..BAM_CONFIG.TranslatePropOutOfBounds)
								net.Send(owner)					
							end
						elseif v.bam_last_safe_pos then
							//Out of bounds so lets do something about that!
							if owner:BAM_CheckIfInAuthoriseZone(v.bam_last_safe_pos) then
								v:SetPos(v.bam_last_safe_pos)
								v:GetPhysicsObject():EnableMotion(false)
								net.Start("BAM_NOTIFICATIOn")
								net.WriteString("[BAM] "..BAM_CONFIG.TransaltePropLeaveBuildZone)
								net.Send(owner)
							else
								v:Remove()
								net.Start("BAM_NOTIFICATIOn")
								net.WriteString("[BAM] "..BAM_CONFIG.TranslatePropOutOfBounds)
								net.Send(owner)
							end
						else
							v:Remove()
							net.Start("BAM_NOTIFICATIOn")
							net.WriteString("[BAM] "..BAM_CONFIG.TranslatePropOutOfBounds)
							net.Send(owner)
						end
					end
				end
			end
		end
	end
end)

hook.Add("PlayerSpawnProp", "BAM_PreventBadPropSpawn", function(ply)
	local propPos = ply:GetEyeTrace().HitPos
	propPos = propPos - (ply:GetAimVector() * 2.5)
	if not ply:BAM_CheckIfInAuthoriseZone(propPos) then
		net.Start("BAM_NOTIFICATIOn")
		net.WriteString("[BAM] "..BAM_CONFIG.TranslateSpawnOutOfBounds)
		net.Send(ply)
		return false
	end
end)

hook.Add("PlayerInitialSpawn", "BAM_SetupAuthZones", function(ply)
	ply:BAM_ConfiguredAuthorisedZones(nil, GAMEMODE.DefaultTeam)
end)

hook.Add("OnPlayerChangedTeam", "BAM_ReauthoZones", function(ply, before, after)
	ply:BAM_ConfiguredAuthorisedZones()
end)

hook.Add("playerBoughtDoor", "BAM_ReauthoZones", function(ply)
	ply:BAM_ConfiguredAuthorisedZones()
end)

hook.Add("PlayerInitialSpawn", "BAM_Reatuthozones", function(ply)
	ply:BAM_ConfiguredAuthorisedZones()
end)

hook.Add("playerSellDoor", "BAM_Reatuthozones", function(ply, door)
	ply:BAM_ConfiguredAuthorisedZones(door)	
end)

//Used to toggle the players drawing or not
hook.Add("PlayerSay", "BAM_TOGGLE_AUTH_DRAW", function(ply, text)
	if string.sub(string.lower(text),1 , string.len(BAM_CONFIG.ShowBuildZoneCommand)) == BAM_CONFIG.ShowBuildZoneCommand then
		net.Start("BAM_TOGGLE_DRAW_AUTH_ZONE")
		net.Send(ply)
	end
end)

///////////////////////////////////
/////        NEWORKING        /////
///////////////////////////////////


net.Receive("BAM_CREATE_PROPERTY", function(len, ply)
	if AuthoriseBamUser(ply) then
		local name = net.ReadString()
		name = name or "Default Name"
		BAM_CreateProperty(name)

		//Update all connected clients on the change
		BAM_UpdateClients()
	end
end)

net.Receive("BAM_DELETE_PROPERTY", function(len, ply)
	if AuthoriseBamUser(ply) then
		local index = net.ReadInt(32)
		BAM_UnregisterProperty(index)

		//Update all connected clients on the change
		BAM_UpdateClients()
		for k ,v in pairs(player.GetAll()) do
			v:BAM_ConfiguredAuthorisedZones()
		end
	end
end)

net.Receive("BAM_RENAME", function(len, ply)
	if AuthoriseBamUser(ply) then
		local propertyID = net.ReadInt(32)
		local newName = net.ReadString()
		if BAM_PROPERTIES[propertyID] ~= nil then
			BAM_PROPERTIES[propertyID]:Rename(newName)
			BAM_UpdateClients()
		end
	end	
end)

net.Receive("BAM_ADD_ZONE", function(len, ply)
	if AuthoriseBamUser(ply) then
		local propertyID = net.ReadInt(32)
		local position1 = net.ReadVector()
		local position2 = net.ReadVector()

		local smallestVector = position2
		local largestVector = position1

		OrderVectors(smallestVector, largestVector)

		smallestVector = smallestVector - Vector(2,2,2)
		largestVector = largestVector + Vector(2,2,2)

		if BAM_PROPERTIES[propertyID] ~= nil then
			BAM_PROPERTIES[propertyID]:AddZone(smallestVector, largestVector)
			BAM_UpdateClients()
			for k ,v in pairs(player.GetAll()) do
				v:BAM_ConfiguredAuthorisedZones()
			end
		end
	end	
end)

net.Receive("BAM_DELETE_ZONE", function(len, ply)
	if AuthoriseBamUser(ply) then
		local propertyID = net.ReadInt(32)
		local zoneID = net.ReadInt(32)
		if BAM_PROPERTIES[propertyID] ~= nil then
			BAM_PROPERTIES[propertyID]:RemoveZone(zoneID)
			BAM_UpdateClients()
			for k ,v in pairs(player.GetAll()) do
				v:BAM_ConfiguredAuthorisedZones()
			end
		end
	end	
end)

net.Receive("BAM_ADD_DOOR", function(len, ply)
	if AuthoriseBamUser(ply) then
		local propertyID = net.ReadInt(32)
		local door = net.ReadEntity()
		if BAM_PROPERTIES[propertyID] ~= nil then
			if BAM_PROPERTIES[propertyID]:AddDoor(door) then
				BAM_UpdateClients()
				for k ,v in pairs(player.GetAll()) do
					v:BAM_ConfiguredAuthorisedZones()
				end
			else
				ply:ChatPrint("This door is not valid.")
			end
		end
	end	
end)

net.Receive("BAM_REMOVE_DOOR", function(len, ply)
	if AuthoriseBamUser(ply) then
		local propertyID = net.ReadInt(32)
		local doorID = net.ReadInt(32)
		if BAM_PROPERTIES[propertyID] ~= nil then
			BAM_PROPERTIES[propertyID]:RemoveDoor(doorID)
			BAM_UpdateClients()
			for k ,v in pairs(player.GetAll()) do
				v:BAM_ConfiguredAuthorisedZones()
			end
		end
	end	
end)

net.Receive("BAM_ADD_JOB", function(len, ply)

	if AuthoriseBamUser(ply) then
		local propertyID = net.ReadInt(32)
		local job = net.ReadString()
		if BAM_PROPERTIES[propertyID] ~= nil then
			if BAM_PROPERTIES[propertyID]:AddJob(job) then
				BAM_UpdateClients()
				for k ,v in pairs(player.GetAll()) do
					v:BAM_ConfiguredAuthorisedZones()
				end
			else
				ply:ChatPrint("The job "..job.." is not valid, please try again.")				
			end
		end
	end	
end)

net.Receive("BAM_REMOVE_JOB", function(len, ply)
	if AuthoriseBamUser(ply) then
		local propertyID = net.ReadInt(32)
		local jobIndex = net.ReadInt(32)
		if BAM_PROPERTIES[propertyID] ~= nil then
			BAM_PROPERTIES[propertyID]:RemoveJob(jobIndex)
			BAM_UpdateClients()
			for k ,v in pairs(player.GetAll()) do
				v:BAM_ConfiguredAuthorisedZones()
			end
		end	
	end	
end)

net.Receive("BAM_SAVE", function(len, ply)
	if AuthoriseBamUser(ply) then
		BAM_SaveProperties()
		ply:ChatPrint("[BAM] All data saved!")
	end	
end)

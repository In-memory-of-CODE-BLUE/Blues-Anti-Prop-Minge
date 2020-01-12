local propertyFunctions = {}
local propertyMeta = {
	__index = propertyFunctions
}


//Property specific functions
function propertyFunctions:AddZone(pos1, pos2)
	table.insert(self.zones, {pos1 = pos1, pos2 = pos2})
end

//Removes a zone
function propertyFunctions:RemoveZone(index)
	table.remove(self.zones, index)
end

//Add the door to the door list. Make sure door is the entity inself
function propertyFunctions:AddDoor(door)
	if IsValid(door) then
		local mapID = door:MapCreationID()
		if mapID < 0 then
			return false //Failed
		end
		local doorTable = {doorID = mapID, door = door, pos = door:GetPos()}
		table.insert(self.doors, doorTable)
		return true
	end
	return false //Failed again
end

//Removes a door from the list (index can be a number or entity)
function propertyFunctions:RemoveDoor(index)
	if isentity(index) then
		for k, v in pairs(self.doors) do
			if v == index then
				table.remove(self.doors, k)
				return
			end
		end
	else
		table.remove(self.doors, index)
	end 
end

//Adds a job to the whitelist of a zone
function propertyFunctions:AddJob(jobID)
	local jobNumericID = _G[jobID]
	if jobNumericID ~= nil and jobNumericID > -1 then
		table.insert(self.jobs, {jobID = jobNumericID, jobName = jobID})
		return true
	else
		return false
	end
end

//Removes a job from the whitelist of a zone
function propertyFunctions:RemoveJob(jobID)
	table.remove(self.jobs, jobID)
end

//Renames a property to the new one
function propertyFunctions:Rename(name)
	self.name = name
end

//Returns the zone list, indexed by ID
function propertyFunctions:GetZones()
	return self.zones
end

//Returns the door list
function propertyFunctions:GetDoors()
	return self.doors
end

//Returns the job list.
function propertyFunctions:GetJobs()
	return self.jobs
end

//Adds a property to the global list
function BAM_RegisteryProperty(property)
	table.insert(BAM_PROPERTIES, property)	
end

//Removes a proprty from the global list
function BAM_UnregisterProperty(index)
	table.remove(BAM_PROPERTIES, index)
end

//Used to create a property object, registers it, then returns it
function BAM_CreateProperty(name)
	local property = {}
	property.name = name
	property.zones = {} //The build zones
	property.doors = {} //The doors associated with this the zones
	property.jobs = {} //Any jobs that can build in this zone (Without owner the doors (Good for things like police at PD))
	
	property = setmetatable(property, propertyMeta) //Set the meta
	BAM_RegisteryProperty(property) //Register it

	return property
end

//Returns a property with the exact name
function BAM_PropertyFromName(name)
	for k ,v in pairs(BAM_PROPERTIES) do
		if v.name == name then
			return BAM_PROPERTIES[k]
		end
	end
end

//This will loop over all of the properties and apply the correct meta table to this
//This is becuase when networking tables they loose there meta.
function BAM_FixBamMeta(BAM_PROPERTIES)
	for k, v in ipairs(BAM_PROPERTIES) do
		BAM_PROPERTIES[k] = setmetatable(v, propertyMeta)
	end
end
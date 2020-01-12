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
	table.insert(self.doors, door)
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
	table.insert(self.jobs, jobID)
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
	return property.zones
end

//Returns the door list
function propertyFunctions:GetDoors()
	return self.doors
end

//Returns the job list.
function propertyFunctions:GetJobs()
	return self.jobs
end

//Used to create a property object.
function BAM_CreateProperty(name)
	local property = {}
	property.name = name
	property.zones = {} //The build zones
	property.doors = {} //The doors associated with this the zones
	property.jobs = {} //Any jobs that can build in this zone (Without owner the doors (Good for things like police at PD))
	return setmetatable(property, propertyMeta)
end



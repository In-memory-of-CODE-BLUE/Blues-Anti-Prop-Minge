include("blues_anti_minge_config.lua")
include("blues_anti_minge/cl_bam.lua")



//Global table containing all the properties
BAM_PROPERTIES = {}

local BAM_AUTHORISED_ZONES = {}
local BAM_DRAW_AUTHORISED_ZONES = false

local BAM_FRAME //The main panel for all BAM ui
local BAM_FRAME_SHOW = false
local BAM_FRAME_SELECTED_LINE = -1 //The last selected line (used for refresh)
local BAM_FRAME_TARGET_X = ScrW() + 700

local BAM_ZONELIST_SELECTED_LINE = -1
local BAM_DOORLIST_SELECTED_LINE = -1
local BAM_JOBLIST_SELECTED_LINE = -1

//Create the interace for controlling the sweps
function BAM_CreateControlInterface(refresh)
	
	BAM_ZONELIST_SELECTED_LINE = -1
	BAM_DOORLIST_SELECTED_LINE = -1
	BAM_JOBLIST_SELECTED_LINE = -1

	BAM_FRAME = vgui.Create("DFrame")
	BAM_FRAME:SetSize(598,645)
	if not refresh then
		BAM_FRAME:SetPos(ScrW() + 700, (ScrH() / 2) - (650 / 2))
	else
		BAM_FRAME:SetPos(ScrW()/2, (ScrH() / 2) - (650 / 2))
	end
	BAM_FRAME:Center()
	BAM_FRAME:SetTitle("Blue's Anti Minge Control Panel")
	BAM_FRAME.Close = function(s)
		BAM_HideControlInterface()
	end
	BAM_FRAME.Think = function(s)
		if BAM_FRAME_SHOW then
			BAM_FRAME_TARGET_X = (ScrW() / 2) - (s:GetWide() / 2)
		else
			BAM_FRAME_TARGET_X = ScrW() + 700
		end
		
		local x, y = s:GetPos()
		x = Lerp(8 * FrameTime(), x, BAM_FRAME_TARGET_X)
		s:SetPos(x, (ScrH() / 2) - (s:GetTall()/2))
	end

	local PropertyList = vgui.Create("DListView", BAM_FRAME)
	PropertyList:SetPos(5,30)
	PropertyList:SetSize(250,650 - 30 - 5 - 25 - 5 - 5)
	PropertyList:AddColumn( "Property" )

	for k, v in pairs(BAM_PROPERTIES) do
		PropertyList:AddLine(k.." : "..v.name)
	end

	if PropertyList:GetLines()[BAM_FRAME_SELECTED_LINE] == nil then
		BAM_FRAME_SELECTED_LINE = -1
	else
		PropertyList:SelectItem(PropertyList:GetLines()[BAM_FRAME_SELECTED_LINE])
		PropertyList:RequestFocus()
	end

	PropertyList.OnRowSelected = function(rowPanel, rowIndex)
		BAM_FRAME_SELECTED_LINE = rowIndex
		BAM_RefreshControlInterface(true)
	end

	local but_createproperty = vgui.Create("DButton", BAM_FRAME)
	but_createproperty:SetPos(5, BAM_FRAME:GetTall() - 30)
	but_createproperty:SetSize(250 / 2 - 5, 25)
	but_createproperty:SetText("Create Property")
	but_createproperty.DoClick = function(s)
		BAM_GetTextInput("Create Property", "Create", "Property Name", function(data)
			net.Start("BAM_CREATE_PROPERTY")
			net.WriteString(data)
			net.SendToServer()
		end)
	end

	local but_deleteproperty = vgui.Create("DButton", BAM_FRAME)
	but_deleteproperty:SetPos(250 / 2 + 5 + 3, BAM_FRAME:GetTall() - 30)
	but_deleteproperty:SetSize(250 / 2 - 3, 25)
	but_deleteproperty:SetText("Delete Property")
	but_deleteproperty.DoClick = function(s)
		if BAM_FRAME_SELECTED_LINE ~= -1 then
			net.Start("BAM_DELETE_PROPERTY")
			net.WriteInt(BAM_FRAME_SELECTED_LINE, 32)
			net.SendToServer()
		end
	end

	//For changin names
	local nameTextEntry = vgui.Create("DTextEntry", BAM_FRAME)
	nameTextEntry:SetPos(250 + 10 , 30)
	nameTextEntry:SetSize(600 - 250 - 20 - 100, 25)
	if BAM_FRAME_SELECTED_LINE ~= -1 then
		nameTextEntry:SetText(BAM_PROPERTIES[BAM_FRAME_SELECTED_LINE].name)
	end

	local but_rename = vgui.Create("DButton", BAM_FRAME)
	but_rename:SetPos(250 + 10 + 600 - 250 - 20 - 95, 30)
	but_rename:SetSize(95,25)
	but_rename:SetText("Rename")
	but_rename.DoClick = function()
		net.Start("BAM_RENAME")
		net.WriteInt(BAM_FRAME_SELECTED_LINE, 32)
		net.WriteString(nameTextEntry:GetText())
		net.SendToServer()
	end

	//Zone creation

	local zoneList = vgui.Create("DListView", BAM_FRAME)
	zoneList:SetPos(250 + 10 , 30 + 30)
	zoneList:SetSize(600 - 250 - 20, 150)
	zoneList:AddColumn("Zone ID")
	zoneList:AddColumn("Pos 1")
	zoneList:AddColumn("Pos 2")
	zoneList:SetMultiSelect(false)

	if BAM_FRAME_SELECTED_LINE ~= -1 then
		for k ,v in pairs(BAM_PROPERTIES[BAM_FRAME_SELECTED_LINE]:GetZones()) do
			zoneList:AddLine(k, tostring(v.pos1), tostring(v.pos2))
		end
	end

	zoneList.OnRowSelected = function(rowPanel, rowIndex)
		BAM_ZONELIST_SELECTED_LINE = rowIndex
	end

	local but_createZone = vgui.Create("DButton", BAM_FRAME)
	but_createZone:SetPos(250 + 10 , 30 + 30 + 155)
	but_createZone:SetSize((600 - 250 - 20) / 2 - 3, 25)
	but_createZone:SetText("Create Zone")
	but_createZone.DoClick = function(s)
		if BAM_FRAME_SELECTED_LINE == -1 then return end
		BAM_HideControlInterface()
		LocalPlayer():GetWeapon("bam_control"):GetXYPosition(function(pos1, pos2)
			net.Start("BAM_ADD_ZONE")
			net.WriteInt(BAM_FRAME_SELECTED_LINE, 32)
			net.WriteVector(pos1)
			net.WriteVector(pos2)
			net.SendToServer()

			BAM_ShowControlInterface()
		end)
	end

	local but_deleteZone = vgui.Create("DButton", BAM_FRAME)
	but_deleteZone:SetPos(250 + 10 + ((600 - 250 - 20) / 2) + 3, 30 + 30 + 155)
	but_deleteZone:SetSize((600 - 250 - 20) / 2 - 3, 25)
	but_deleteZone:SetText("Delete Zone")
	but_deleteZone.DoClick = function(s)
		if BAM_FRAME_SELECTED_LINE == -1 then return end
		net.Start("BAM_DELETE_ZONE")
		net.WriteInt(BAM_FRAME_SELECTED_LINE, 32)
		net.WriteInt(BAM_ZONELIST_SELECTED_LINE, 32)
		net.SendToServer()
	end

	//Door Additions
	local doorList = vgui.Create("DListView", BAM_FRAME)
	doorList:SetPos(250 + 10 , 30 + 30  + (155 + 30))
	doorList:SetSize(600 - 250 - 20, 150)
	doorList:AddColumn("Door ID")
	doorList:AddColumn("Dor MapID")

	if BAM_FRAME_SELECTED_LINE ~= -1 then
		for k ,v in pairs(BAM_PROPERTIES[BAM_FRAME_SELECTED_LINE]:GetDoors()) do
			doorList:AddLine(k, v.doorID)
		end
	end

	doorList.OnRowSelected = function(rowPanel, rowIndex)
		BAM_DOORLIST_SELECTED_LINE = rowIndex
	end

	local but_addDoor = vgui.Create("DButton", BAM_FRAME)
	but_addDoor:SetPos(250 + 10 , 30 + 30 + 155 + (155 + 30))
	but_addDoor:SetSize((600 - 250 - 20) / 2 - 3, 25)
	but_addDoor:SetText("Add Door")
	but_addDoor.DoClick = function(s)
		if BAM_FRAME_SELECTED_LINE == -1 then return end
		BAM_HideControlInterface()
		LocalPlayer():GetWeapon("bam_control"):GetDoor(function(door)
			net.Start("BAM_ADD_DOOR")
			net.WriteInt(BAM_FRAME_SELECTED_LINE, 32)
			net.WriteEntity(door)
			net.SendToServer()
			BAM_ShowControlInterface()
		end)
	end

	local but_removeDoor = vgui.Create("DButton", BAM_FRAME)
	but_removeDoor:SetPos(250 + 10 + ((600 - 250 - 20) / 2) + 3, 30 + 30 + 155  + (155 + 30))
	but_removeDoor:SetSize((600 - 250 - 20) / 2 - 3, 25)
	but_removeDoor:SetText("Remove Door")
	but_removeDoor.DoClick = function(s)
		if BAM_DOORLIST_SELECTED_LINE == -1 then return end
		net.Start("BAM_REMOVE_DOOR")
		net.WriteInt(BAM_FRAME_SELECTED_LINE, 32)
		net.WriteInt(BAM_DOORLIST_SELECTED_LINE, 32)
		net.SendToServer()
	end


	//Jobs Additions
	local jobList = vgui.Create("DListView", BAM_FRAME)
	jobList:SetPos(250 + 10 , 30 + 30  + (155 + 30) + (155 + 30))
	jobList:SetSize(600 - 250 - 20, 150)
	jobList:AddColumn("Job ID")
	jobList:AddColumn("Job Name")

	if BAM_FRAME_SELECTED_LINE ~= -1 then
		for k ,v in pairs(BAM_PROPERTIES[BAM_FRAME_SELECTED_LINE]:GetJobs()) do
			jobList:AddLine(k, v.jobName)
		end
	end

	jobList.OnRowSelected = function(rowPanel, rowIndex)
		BAM_JOBLIST_SELECTED_LINE = rowIndex
	end

	local but_addJob = vgui.Create("DButton", BAM_FRAME)
	but_addJob:SetPos(250 + 10 , 30 + 30 + 155 + (155 + 30) + (155 + 30))
	but_addJob:SetSize((600 - 250 - 20) / 2 - 3, 25)
	but_addJob:SetText("Add Job")
	but_addJob.DoClick = function(s)
		if BAM_FRAME_SELECTED_LINE == -1 then return end
		BAM_GetTextInput("Enter Job Name", "Add Job", "TEAM_CITIZEN", function(job)
			net.Start("BAM_ADD_JOB")
			net.WriteInt(BAM_FRAME_SELECTED_LINE, 32)
			net.WriteString(job)
			net.SendToServer()
		end)
	end

	local but_removeJob = vgui.Create("DButton", BAM_FRAME)
	but_removeJob:SetPos(250 + 10 + ((600 - 250 - 20) / 2) + 3, 30 + 30 + 155  + (155 + 30) + (155 + 30))
	but_removeJob:SetSize((600 - 250 - 20) / 2 - 3, 25)
	but_removeJob:SetText("Remove Job")
	but_removeJob.DoClick = function()
		if BAM_JOBLIST_SELECTED_LINE ~= -1 then
			net.Start("BAM_REMOVE_JOB")
			net.WriteInt(BAM_FRAME_SELECTED_LINE, 32)
			net.WriteInt(BAM_JOBLIST_SELECTED_LINE, 32)
			net.SendToServer()
		end
	end

	//Save button
	local but_Save = vgui.Create("DButton", BAM_FRAME)
	but_Save:SetPos(250 + 10 , 30 + 30 + 155 + (155 + 30) + (155 + 30) + 30)
	but_Save:SetSize((600 - 250 - 20), 25)
	but_Save:SetText("Save All Data")
	but_Save.DoClick = function()
		net.Start("BAM_SAVE")
		net.SendToServer()
	end
end

//Creates a dialog window for text input, then calls callback with the text
function BAM_GetTextInput(title, buttonName, text, callback)
	local f = vgui.Create("DFrame")
	f:SetSize(250, 90)
	f:Center()
	f:SetTitle(title)
	f:SetBackgroundBlur(true)
	f:MakePopup()

	local entry = vgui.Create("DTextEntry", f)
	entry:SetPos(5, 30)
	entry:SetSize(250 - 10, 25)
	entry:SetText(text)
	entry.OnGetFocus = function(s)
		if s:GetText() == text then
			s:SetText("")
		end
	end
	entry.OnLoseFocus = function(s)
		if s:GetText() == "" then
			s:SetText(text)
		end
	end

	local cancelButton = vgui.Create("DButton", f)
	cancelButton:SetPos(5,f:GetTall() - 30)
	cancelButton:SetSize((250/2) - 10 ,25)
	cancelButton:SetText("Cancel")
	cancelButton.DoClick = function()
		f:Close()
	end

	local confirmButton = vgui.Create("DButton", f)
	confirmButton:SetPos((250/2) + 5,f:GetTall() - 30)
	confirmButton:SetSize((250/2) - 10 ,25)
	confirmButton:SetText(buttonName)
	confirmButton.DoClick = function()
		callback(entry:GetText())
		f:Close()
	end
end

//Closes the control interface by destroying it.
function BAM_DestroyControlInterface()
	BAM_FRAME_SHOW = false
	if BAM_FRAME then
		BAM_FRAME:Remove()
		BAM_FRAME = nil
	end
end

//Shows the interface
function BAM_ShowControlInterface()
	if BAM_FRAME == nil then
		BAM_CreateControlInterface()
	end
	BAM_FRAME_SHOW = true
	BAM_FRAME:MakePopup()
end

//Hides the interface
function BAM_HideControlInterface()
	BAM_FRAME_SHOW = false
	BAM_FRAME:SetKeyboardInputEnabled(false)
	BAM_FRAME:SetMouseInputEnabled(false)
end

//Handle re-creating the interface
function BAM_RefreshControlInterface()
	if BAM_FRAME then
		if BAM_FRAME_SHOW then
			BAM_DestroyControlInterface()
			BAM_CreateControlInterface(true)
			BAM_ShowControlInterface()
		else
			BAM_DestroyControlInterface()
			BAM_CreateControlInterface()
		end
	end
end

///////////////////////////////////
/////         DRAWING         /////
///////////////////////////////////

local boxMat = Material("pheonix_storms/wire/pcb_green")

surface.CreateFont( "BAM_Control_font_2", {
	font = "Roboto", 
	extended = false,
	size = 25,
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = true,
} )

surface.CreateFont( "BAM_Control_font_3", {
	font = "Roboto", 
	extended = false,
	size = 20,
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = true,
} )

//Draw all the zones and doors
hook.Add("PostDrawOpaqueRenderables", "DrawZonePreveiws", function()
	if BAM_FRAME ~= nil then
		render.SetMaterial(boxMat)
		for k, v in pairs(BAM_PROPERTIES) do
			for a , b in pairs(v:GetZones()) do	
				if a ~= BAM_ZONELIST_SELECTED_LINE then 		
					render.DrawWireframeBox(Vector(0,0,0), Angle(0,0,0), b.pos1, b.pos2, Color(80,240,80,255), true)
				else
					render.DrawWireframeBox(Vector(0,0,0), Angle(0,0,0), b.pos1, b.pos2, Color(180,30,30,255), true)
				end
			end
		end
	end

	if BAM_DRAW_AUTHORISED_ZONES then
		render.SetMaterial(boxMat)
		for k, v in pairs(BAM_AUTHORISED_ZONES) do
			render.DrawWireframeBox(Vector(0,0,0), Angle(0,0,0), v.pos1, v.pos2, Color(80,240,80,255), false)
		end	
	end
end)

//Draw all the zone names
hook.Add("HUDPaint", "DrawZoneNames", function()
	if BAM_FRAME ~= nil then
		for k, v in pairs(BAM_PROPERTIES) do
			for a , b in pairs(v:GetZones()) do	
				local name = "Zone "..a.." ("..v.name..")"
				local pos = LerpVector(0.5,b.pos1, b.pos2):ToScreen()
				if a ~= BAM_ZONELIST_SELECTED_LINE then 
					draw.SimpleText(name, "BAM_Control_font_2", pos.x, pos.y, Color(80,240,80,255),1,1)
				else
					draw.SimpleText(name, "BAM_Control_font_2", pos.x, pos.y, Color(180,30,30,255),1,1)
				end
			end
		end
		for k, v in pairs(BAM_PROPERTIES) do
			for a , b in pairs(v:GetDoors()) do	 
				local pos = b.pos:ToScreen()
				draw.SimpleText("Door "..a.." ("..v.name..")", "BAM_Control_font_3", pos.x, pos.y, Color(30,180,30,255),1,1)
			end
		end
	end

	if BAM_DRAW_AUTHORISED_ZONES then
		render.SetMaterial(boxMat)
		local c = 1
		for k, v in pairs(BAM_AUTHORISED_ZONES) do
			local name = "Zone "..c
			local pos = LerpVector(0.5,v.pos1, v.pos2):ToScreen()

			draw.SimpleText(name, "BAM_Control_font_2", pos.x, pos.y, Color(80,240,80,255),1,1)
		end	
	end
end)

///////////////////////////////////
/////        NEWORKING        /////
///////////////////////////////////

net.Receive("BAM_UPDATE_PROPERTY_DATA", function()
	local data = net.ReadTable()
	BAM_PROPERTIES = data
	BAM_FixBamMeta(BAM_PROPERTIES) //Fix metas

	//Refresh UI
	BAM_RefreshControlInterface()
end)

//Used to add notifications from the server
net.Receive("BAM_NOTIFICATIOn", function()
	local message = net.ReadString()
	local time = 5
	local type = NOTIFY_ERROR

	notification.AddLegacy(message, type, time)
end)

//Used to update the authorised zones
net.Receive("BAM_AUTHORISE_ZONE_UPDATE", function()
	BAM_AUTHORISED_ZONES = net.ReadTable()
end)

//Used to toggle weather or not to draw them
net.Receive("BAM_TOGGLE_DRAW_AUTH_ZONE", function()
	BAM_DRAW_AUTHORISED_ZONES = not BAM_DRAW_AUTHORISED_ZONES
	if BAM_DRAW_AUTHORISED_ZONES then
		LocalPlayer():ChatPrint("[BAM] You can now see your build zones. If you don't see anything then it is becuase you don't have any, you will get them based on your job or the property you own. Remember type !buildzone again to hide them")
	else
		LocalPlayer():ChatPrint("[BAM] You build zones have no been hidden.")
	end
end)
include("shared.lua")

local beamMat = Material('cable/redlaser')
local boxMat = Material("pheonix_storms/wire/pcb_green")

surface.CreateFont( "BAM_Control_font", {
	font = "Roboto", 
	extended = false,
	size = 45,
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
	outline = false,
} )

//Credit to wiremod for helping with this function
function SWEP:ConfigureAttachment()
	if self:GetOwner() ~= nil and self:GetOwner() :GetViewModel():IsValid() then
		local attachment = self:GetOwner() :GetViewModel():LookupAttachment("muzzle")
		if LocalPlayer():GetAttachment(attachment) then
			self.attachment = attachment
			self.viewModel = self:GetOwner() :GetViewModel()	
		end
	end
end

function SWEP:Deploy()
	self:ConfigureAttachment()
end

function SWEP:Initialize()
	self.canReload = true
	self:ConfigureAttachment()
	self.isGettingLocation = false
	self.locationOneSet = false
	self.locationOne = Vector(0,0,0)
	self.locationTwo = Vector(0,0,0)
	self.locationCallback = nil

	self.isGettingDoor = false
	self.doorCallback = nil
end

//Open the interface
function SWEP:Reload()
	if self.canReload then
		self.canReload = false
		timer.Simple(1 , function()
			self.canReload = true
		end)
		BAM_ShowControlInterface()
	end
end

//Destroy the interface
function SWEP:OnRemove()
	BAM_DestroyControlInterface()
end

//Turns the swep into a mode where it is trying to get an x and y position, if it succedes it
//calls the callback function with the two positions
function SWEP:GetXYPosition(callback)
	self.isGettingLocation = true
	self.locationOneSet = false
	self.locationCallback = callback

	self.isGettingDoor = false
end

//Asks the user to selected a door, if its a valid door then it
//Calls the callback function and passes the door ast he value
function SWEP:GetDoor(callback)
	self.isGettingLocation = false
	self.locationOneSet = false

	self.isGettingDoor = true
	self.doorCallback = callback
end


function SWEP:PrimaryAttack()
	if not IsFirstTimePredicted() then return end

	if self.isGettingLocation then
		local tr = LocalPlayer():GetEyeTrace()
		drawPos = tr.HitPos
		if tr.HitPos:Distance(LocalPlayer():EyePos()) > 200 then
			local direction = (LocalPlayer():EyePos() - tr.HitPos):GetNormalized() * 200
			drawPos = LocalPlayer():EyePos() - direction
		end

		if not self.locationOneSet then
			self.locationOne = drawPos
			self.locationOneSet = true
		else
			self.locationTwo = drawPos
			self.isGettingLocation = false
			self.locationOneSet = false
			self.locationCallback(self.locationOne, self.locationTwo)
		end
	end

	if self.isGettingDoor then
		self.isGettingDoor = false
	
		local tr = LocalPlayer():GetEyeTrace()
		print(tr.Entity:GetClass())

		local class = tr.Entity:GetClass()
		if class == "func_door" or class == "func_door_rotating" or class == "prop_door_rotating" then
			//Valid door
			self.doorCallback(tr.Entity)
		else
			print("Invalid door selected")
		end
	end
end

function SWEP:ViewModelDrawn()
	if self.viewModel and self.isGettingLocation then
		local tr = LocalPlayer():GetEyeTrace()
		drawPos = tr.HitPos
		if tr.HitPos:Distance(LocalPlayer():EyePos()) > 200 then
			local direction = (LocalPlayer():EyePos() - tr.HitPos):GetNormalized() * 200
			drawPos = LocalPlayer():EyePos() - direction
		end
		self.locationTwo = drawPos
		render.DrawWireframeSphere(drawPos, 2, 8, 8, Color(40,60,255), true)
		render.SetMaterial(beamMat)
		render.DrawBeam(self.viewModel:GetAttachment(self.attachment).Pos, drawPos, 2, 0, 12.5, Color(255, 0, 0, 255))
    end
end

function SWEP:DrawHUD()
	if self.isGettingLocation then
		if self.locationOneSet then
			draw.SimpleText("Press left mouse to set position 2", "BAM_Control_font",ScrW()/2 + 2,ScrH()/2 + 102,Color(40,40,40,255), 1 , 1)
			draw.SimpleText("Press left mouse to set position 2", "BAM_Control_font",ScrW()/2,ScrH()/2 + 100,Color(90,240,90), 1 , 1)
		else
			draw.SimpleText("Press left mouse to set position 1", "BAM_Control_font",ScrW()/2 + 2,ScrH()/2 + 102,Color(40,40,40,255), 1 , 1)
			draw.SimpleText("Press left mouse to set position 1", "BAM_Control_font",ScrW()/2,ScrH()/2 + 100,Color(240,160,90), 1 , 1)
		end
	elseif self.isGettingDoor then
		draw.SimpleText("Press left mouse to select a door", "BAM_Control_font",ScrW()/2 + 2,ScrH()/2 + 102,Color(40,40,40,255), 1 , 1)
		draw.SimpleText("Press left mouse to select a door", "BAM_Control_font",ScrW()/2,ScrH()/2 + 100,Color(240,160,90), 1 , 1)
	end
end

hook.Add("PostDrawOpaqueRenderables", "DrawPreviewBoxBAM", function()
	for k, v in pairs(ents.FindByClass("bam_control")) do
		if v:GetOwner() == LocalPlayer() then
			if v.isGettingLocation then
				if v.locationOneSet then
					render.SetMaterial(boxMat)
					render.DrawWireframeBox(Vector(0,0,0), Angle(0,0,0), v.locationOne, v.locationTwo, Color(100,255,100,100), true)
				end
			end
		end
	end
end)


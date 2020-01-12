AddCSLuaFile( "shared.lua" )
include("shared.lua")

function SWEP:Initialize()

end

function SWEP:Reload()

end

function SWEP:Think()	

end

function SWEP:Holster()
	if self:GetOwner():IsValid() ~= nil then
		self:GetOwner():ChatPrint("[BAM] Remember to press save once your done! It would be a shame if all your hard work was lost!")
		self:GetOwner():StripWeapon(self:GetClass())
	end
end

function SWEP:OnDrop()
	if self:GetOwner():IsValid() then
		self:GetOwner():ChatPrint("[BAM] Remember to press save once your done! It would be a shame if all your hard work was lost!")
		self:GetOwner():StripWeapon(self:GetClass())
	end
end

function SWEP:PrimaryAttack()
	self:SetClip1(2)
	self:SetClip2(2)
end

function SWEP:SecondaryAttack()
	if self:GetOwner() ~= nil then
		self:GetOwner():ChatPrint("[BAM] Remember to press save once your done! It would be a shame if all your hard work was lost!")
		self:GetOwner():StripWeapon(self:GetClass())
	end
end
////////////////////////////
/////     WARNING!     /////
////////////////////////////
//Please read the readme.txt if you have not already!

BAM_CONFIG = {}

//This is a list of ranks that have permission to change anything with the addon.
//Altough anyone can use the weapon, it will be non-functional unless there rank is on this list.
BAM_CONFIG.AuthorisedRanks = {
	"superadmin",
	"owner"
}

//These are ulx ranks that bypass the build limitation
//This is good for admins, or trusted VIPS so they can
//build anywhere, ranks in here can build anywhere they like
//on the map, even in other peoples bases.
BAM_CONFIG.BypassRanks = {
	"superadmin",
	"owner",
	"supertrustedcoolvip"
}

//This will make it even harder for them to greif but disallowing
//the prop to go ourside of the zone at all (like even part of the prop)
//This is recommended to have off unless its an issue as this can make
//building near the edge of a zone a pain
//This also means if a prop does not fit in the area when spawn it will be
//deleted so as I said only enable if its an issue people are abusing
BAM_CONFIG.UseOBB = false

//This is the rate in which the addon update zones and checks for
//props outside of it, this can be low and should not cause you issues
//but for servers will large max prop count then I recommend you raise
//this to somehwere around 0.4-0.6. Setting this too high will cause
//the prop to be able to leave the zone for x amount of time so try
//to keep it low if possible.
BAM_CONFIG.UpdateRate = 0.2

//This is the command responsible for showing and hiding the build zones
//Change this as you please but be sure to (below) tell the user what the command
//is or they'll have no idea :D
BAM_CONFIG.ShowBuildZoneCommand = "!buildzone"

//These are just here to make it easier to translate if you want to
//Just change these and they'll change in the script.
BAM_CONFIG.TranslatePropOutOfBounds = "You prop was removed as it left an area and has no previous safe posisition."
BAM_CONFIG.TransaltePropLeaveBuildZone = "Your prop cannot leave you build zone. Type !buildzone to show your build zone."
BAM_CONFIG.TranslateSpawnOutOfBounds = "You can only spawn props in your buildzone, buy a property and type !buildzone to see your build zone."
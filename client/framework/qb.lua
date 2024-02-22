if Config.Framework ~= "qbcore" then
	return
end

debugprint("Loading QB")

QB = exports["qb-core"]:GetCoreObject()

while not LocalPlayer.state.isLoggedIn do
	Wait(500)
end

local PlayerJob = QB.Functions.GetPlayerData().job

RegisterNetEvent("QBCore:Client:OnJobUpdate", function(jobInfo)
	PlayerJob = jobInfo
end)

function IsPolice()
	return PoliceJobsLookup[PlayerJob.name] == true
end

function FrameworkNotify(text, errType)
	QB.Functions.Notify(text)
end

debugprint("QB loaded")

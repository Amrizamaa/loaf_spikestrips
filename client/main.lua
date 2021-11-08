ESX = nil

isPolice = false
closestStinger = 0

RegisterNetEvent("loaf_spikestrips:setPolice")
AddEventHandler("loaf_spikestrips:setPolice", function()
    isPolice = true
end)

CreateThread(function()
    while not NetworkIsSessionStarted() do
        Wait(500)
    end

    if Config.ESX then
        while not ESX do
            Wait(500)
            TriggerEvent("esx:getSharedObject", function(esx)
                ESX = esx
            end)
        end
    
        while not ESX.GetPlayerData() or not ESX.GetPlayerData().job or not ESX.GetPlayerData().job.name do
            Wait(500)
        end
    end

    if Config.JobBased then
        if Config.ESX then
            RegisterNetEvent("esx:setJob")
            AddEventHandler("esx:setJob", function(jobData)
                local jobName = jobData.name
                isPolice = false
                for _, job in pairs(Config.ESXFeatures.PoliceJobs) do
                    if job == jobName then
                        isPolice = true
                        break
                    end
                end
            end)
            
            local jobName = ESX.GetPlayerData().job.name
            for _, job in pairs(Config.ESXFeatures.PoliceJobs) do
                if job == jobName then
                    isPolice = true
                    break
                end
            end
        else
            TriggerServerEvent("loaf_spikestrips:checkPolice")
        end
    else
        isPolice = true
    end

    if Config.Debugging then
        CreateThread(function()
            while true do
                Wait(500)
                while DoesEntityExist(closestStinger) do
                    Wait(0)
                    local min, max = GetModelDimensions(GetEntityModel(closestStinger))
                    local size = max - min
                    local w, l, h = size.x, size.y, size.z

                    local offset1 = GetOffsetFromEntityInWorldCoords(closestStinger, 0.0, l/2, h*-1)
                    local offset2 = GetOffsetFromEntityInWorldCoords(closestStinger, 0.0, l/2 * -1, h)

                    local onScreen, x, y = GetScreenCoordFromWorldCoord(table.unpack(offset1))
                    DrawRect(x, y, 0.005, 0.005 * 16/9, 255, 255, 255, 255)
                    onScreen, x, y = GetScreenCoordFromWorldCoord(table.unpack(offset2))
                    DrawRect(x, y, 0.005, 0.005 * 16/9, 255, 255, 255, 255)
                end
            end
        end)
    end

    -- thread to find the closest stinger / spikestrip
    CreateThread(function()
        while true do
            local driving = DoesEntityExist(GetVehiclePedIsUsing(PlayerPedId()))
            Wait((driving and 50) or 1000)
            local coords = GetEntityCoords((driving and GetVehiclePedIsUsing(PlayerPedId())) or PlayerPedId())

            local stinger = GetClosestObjectOfType(coords, 10.0, GetHashKey("p_ld_stinger_s"), false, false, false)
            if DoesEntityExist(stinger) then
                closestStinger = stinger
                closestStingerDistance = #(coords - GetEntityCoords(stinger))
            end

            if not DoesEntityExist(closestStinger) or #(coords - GetEntityCoords(closestStinger)) > 10.0 then
                closestStinger = 0
            end
        end
    end)

    -- This loop allows you to remove stingers.
    CreateThread(function()
        while true do
            Wait(500)
            if (isPolice or not Config.RequireJobRemove) and IsPedOnFoot(PlayerPedId()) then
                while (isPolice or not Config.RequireJobRemove) and DoesEntityExist(closestStinger) and closestStingerDistance <= 4.0 and IsPedOnFoot(PlayerPedId()) do
                    Wait(0)
                    HelpText(Strings["remove_stinger"], true)
                    if IsControlJustReleased(0, 51) then
                        RemoveStinger()
                    end
                end
            end
        end
    end)

    -- This while loop manages bursting tyres.
    CreateThread(function()
        while true do
            Wait(1500)
            while DoesEntityExist(GetVehiclePedIsUsing(PlayerPedId())) do
                Wait(50)
                local vehicle = GetVehiclePedIsUsing(PlayerPedId())
                while DoesEntityExist(closestStinger) and closestStingerDistance <= 5.0 do
                    Wait(25)
                    if IsEntityTouchingEntity(vehicle, closestStinger) then
                        local wheels = {
                            lf = {
                                coordinates = GetWorldPositionOfEntityBone(vehicle, GetEntityBoneIndexByName(vehicle, "wheel_lf")),
                                wheelId = 0
                            },
                            rf = {
                                coordinates = GetWorldPositionOfEntityBone(vehicle, GetEntityBoneIndexByName(vehicle, "wheel_rf")),
                                wheelId = 1
                            },
                            rr = {
                                coordinates = GetWorldPositionOfEntityBone(vehicle, GetEntityBoneIndexByName(vehicle, "wheel_rr")),
                                wheelId = 5
                            },
                            lr = {
                                coordinates = GetWorldPositionOfEntityBone(vehicle, GetEntityBoneIndexByName(vehicle, "wheel_lr")),
                                wheelId = 4
                            },
                        }
                        for k, v in pairs(wheels) do
                            if not IsVehicleTyreBurst(vehicle, v.wheelId, false) then
                                if TouchingStinger(v.coordinates, closestStinger) then
                                    SetVehicleTyreBurst(vehicle, v.wheelId, 1, 1148846080)
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
end)
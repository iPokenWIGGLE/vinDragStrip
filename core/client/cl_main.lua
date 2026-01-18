---------------------------
    -- Variables --
---------------------------
Data = {
    Player = {
        Ped = nil,
        RaceCar = nil,
        DragRaceId = 0,
        StartingRace = false,
        RaceStarted = false,
        LinePosition = nil,
        RaceCountdown = 0,
        DragRaceCP = nil,
        DragRaceData = {}
    },
}

local startLineZones = {}
local finishLineZones = {}
---------------------------
    -- Event Handlers --
---------------------------
RegisterNetEvent('vinDragStrip:cl_joinRace')
AddEventHandler('vinDragStrip:cl_joinRace', function(data)
    Data.Player.Ped = PlayerPedId()
    if Data.Player.DragRaceId == 0 then
        if IsPedInAnyVehicle(Data.Player.Ped, false) then
            TriggerServerEvent('vinDragStrip:sv_JoinDragRace', data.raceId)
        else
            lib.notify({type = "error", description = "You must be in a vehicle to join the race!"})
            return
        end
    else
        lib.notify({type = "error", description = "You are already in a race!"})
        return
    end
end)

RegisterNetEvent('vinDragStrip:cl_JoinDragRace')
AddEventHandler('vinDragStrip:cl_JoinDragRace', function(raceId, line)
    Data.Player.DragRaceId = raceId
    Data.Player.LinePosition = line
    Data.Player.StartingRace = true
    Data.Player.RaceCar = GetVehiclePedIsIn(Data.Player.Ped, false)
    SetEntityCoords(Data.Player.RaceCar, Config.DragStrip[raceId]["LinePosition"][Data.Player.LinePosition].x, Config.DragStrip[raceId]["LinePosition"][Data.Player.LinePosition].y, Config.DragStrip[raceId]["LinePosition"][Data.Player.LinePosition].z)
    SetEntityHeading(Data.Player.RaceCar, Config.DragStrip[raceId]["LinePosition"][Data.Player.LinePosition].heading)
    lib.notify({type = "inform", description = "You joined the race to find out who asked!"})
    CreateThread(function()
        while Data.Player.StartingRace do
            Wait(5)
            if Data.Player.LinePosition == 1 and startLineZones[raceId] and startLineZones[raceId][1] and not startLineZones[raceId][1]:contains(GetEntityCoords(Data.Player.Ped)) then
                TriggerServerEvent('vinDragStrip:sv_EndRaceEarly', Data.Player.DragRaceId)
            end
            if Data.Player.LinePosition == 2 and startLineZones[raceId] and startLineZones[raceId][2] and not startLineZones[raceId][2]:contains(GetEntityCoords(Data.Player.Ped)) then
                TriggerServerEvent('vinDragStrip:sv_EndRaceEarly', Data.Player.DragRaceId)
            end
        end
    end)
end)

RegisterNetEvent('vinDragStrip:cl_StartDragRace')
AddEventHandler('vinDragStrip:cl_StartDragRace', function(dragRaceId)
    if Data.Player.DragRaceId ~= 0 and Data.Player.DragRaceId == dragRaceId then
        Data.Player.DragRaceCP = CreateCheckpoint(21, Config.DragStrip[1]["FinishLinePosition"][Data.Player.LinePosition].x, Config.DragStrip[1]["FinishLinePosition"][Data.Player.LinePosition].y, Config.DragStrip[1]["FinishLinePosition"][Data.Player.LinePosition].z, 0, 0, 0, 35.0, 255, 71, 94, 255, 0) 
        racestart(dragRaceId)
        CreateThread(function()
            while Data.Player.RaceStarted do
                Wait(5)
                if Data.Player.LinePosition == 1 and finishLineZones[1] and finishLineZones[1]:contains(GetEntityCoords(Data.Player.Ped)) then
                    TriggerServerEvent('vinDragStrip:sv_RaceFinished', Data.Player.DragRaceId)
                end
                if Data.Player.LinePosition == 2 and finishLineZones[2] and finishLineZones[2]:contains(GetEntityCoords(Data.Player.Ped)) then
                    TriggerServerEvent('vinDragStrip:sv_RaceFinished', Data.Player.DragRaceId)
                end
            end
        end)
    end
end)

RegisterNetEvent('vinDragStrip:cl_RaceFinished')
AddEventHandler('vinDragStrip:cl_RaceFinished', function(dragRaceId, dragRaceWinner_Name)
    if Data.Player.DragRaceId ~= 0 and Data.Player.DragRaceId == dragRaceId then
        DeleteCheckpoint(Data.Player.DragRaceCP)
        Data.Player.RaceStarted = false
        Data.Player.RaceCar = nil
        Data.Player.LinePosition = nil
        Data.Player.DragRaceCP = nil
        Data.Player.DragRaceId = 0
        Data.Player.RaceCountdown = 0
        lib.notify({type = "inform", description = " "..dragRaceWinner_Name.." won the drag race!"})
    end
end)

RegisterNetEvent('vinDragStrip:cl_EndRaceEarly')
AddEventHandler('vinDragStrip:cl_EndRaceEarly', function(dragRaceId, dragRaceLeave_name)
    if Data.Player.DragRaceId ~= 0 and Data.Player.DragRaceId == dragRaceId then
        DeleteCheckpoint(Data.Player.DragRaceCP)
        Data.Player.StartingRace = false
        Data.Player.RaceCar = nil
        Data.Player.LinePosition = nil
        Data.Player.DragRaceCP = nil
        Data.Player.DragRaceId = 0
        Data.Player.RaceCountdown = 0
        lib.notify({type = "error", description = " "..dragRaceLeave_name.." left the race early!"})
    end
end)
---------------------------
    -- Threads --
---------------------------
CreateThread(function()
    Utils.AddBlip(vector3(850.68, -2921.45, 5.9), 38, 0, 0.65, "Drag Strip Racing")
    finishLineZones[1] = lib.zones.box({
        coords = vector3(1132.57, -2914.11, 5.9),
        size = vector3(13.0, 0.8, 4.2),
        rotation = 0,
        debug = false
    })
    finishLineZones[2] = lib.zones.box({
        coords = vector3(1132.54, -2927.0, 5.9),
        size = vector3(10.2, 1.0, 4.2),
        rotation = 0,
        debug = false
    })
    for i = 1, #Config.DragStrip do
        local tracking_length, tracking_width = Config.DragStrip[i]["JoinRace"].tracking_length, Config.DragStrip[i]["JoinRace"].tracking_width
        local tracking_minZ, tracking_maxZ = Config.DragStrip[i]["JoinRace"].tracking_minZ, Config.DragStrip[i]["JoinRace"].tracking_maxZ
        local tracking_heading = Config.DragStrip[i]["JoinRace"].tracking_heading
        local tracking_distance = Config.DragStrip[i]["JoinRace"].tracking_distance
        exports.ox_target:addBoxZone({
            coords = vector3(Config.DragStrip[i]["JoinRace"].x, Config.DragStrip[i]["JoinRace"].y, Config.DragStrip[i]["JoinRace"].z),
            size = vector3(tracking_length, tracking_width, math.abs(tracking_maxZ - tracking_minZ)),
            rotation = tracking_heading,
            debug = false,
            options = {
                {
                    event = "vinDragStrip:cl_joinRace",
                    icon = "fas fa-cars",
                    label = "Join Dragstrip Race",
                    args = {raceId = i},
                },
            },
            distance = tracking_distance
        })
    end
    for i = 1, #Config.DragStrip do
        local coords = vector3(Config.DragStrip[i]["LinePosition"][1].x,Config.DragStrip[i]["LinePosition"][1].y,Config.DragStrip[i]["LinePosition"][1].z)
        local length, width = Config.DragStrip[i]["LinePosition"][1].length, Config.DragStrip[i]["LinePosition"][1].width
        local minZ, maxZ = Config.DragStrip[i]["LinePosition"][1].minZ, Config.DragStrip[i]["LinePosition"][1].maxZ
        startLineZones[i] = startLineZones[i] or {}
        startLineZones[i][1] = lib.zones.box({
            coords = coords,
            size = vector3(length, width, math.abs(maxZ - minZ)),
            rotation = 0,
            debug = false
        })
        local coords = vector3(Config.DragStrip[i]["LinePosition"][2].x,Config.DragStrip[i]["LinePosition"][2].y,Config.DragStrip[i]["LinePosition"][2].z)
        local length, width = Config.DragStrip[i]["LinePosition"][2].length, Config.DragStrip[i]["LinePosition"][2].width
        local minZ, maxZ = Config.DragStrip[i]["LinePosition"][2].minZ, Config.DragStrip[i]["LinePosition"][2].maxZ
        startLineZones[i] = startLineZones[i] or {}
        startLineZones[i][2] = lib.zones.box({
            coords = coords,
            size = vector3(length, width, math.abs(maxZ - minZ)),
            rotation = 0,
            debug = false
        })
    end
end)
---------------------------
    -- Functions --
---------------------------
racestart = function(dragRaceId)
    if Data.Player.DragRaceId ~= 0 and Data.Player.DragRaceId == dragRaceId then
        while Data.Player.RaceCountdown ~= 3 and Data.Player.StartingRace do
            PlaySound(-1, "3_2_1", "HUD_MINI_GAME_SOUNDSET", 0, 0, 1)
            lib.notify({type = "inform", description = tostring(Data.Player.RaceCountdown)})
            Wait(1000)
            Data.Player.RaceCountdown = Data.Player.RaceCountdown + 1
        end
        Data.Player.RaceCountdown = 0
        Data.Player.StartingRace = false
        Data.Player.RaceStarted = true
        lib.notify({type = "success", description = "RACE TO FIND OUT WHO ASKED!"})
        PlaySound(-1, "GO", "HUD_MINI_GAME_SOUNDSET", 0, 0, 1)
    else
        lib.notify({type = "error", description = "You have to be in a race!"})
    end
end

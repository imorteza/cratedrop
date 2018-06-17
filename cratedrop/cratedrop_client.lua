local weaponList = {
    ["pistol"] = "PICKUP_WEAPON_PISTOL",
    ["combatpistol"] = "PICKUP_WEAPON_COMBATPISTOL",
    ["appistol"] = "PICKUP_WEAPON_APPISTOL",
    ["pistol50"] = "PICKUP_WEAPON_PISTOL50",
    ["snspistol"] = "PICKUP_WEAPON_SNSPISTOL",
    ["vintagepistol"] = "PICKUP_WEAPON_VINTAGEPISTOL",
    ["marksmanpistol"] = "PICKUP_WEAPON_MARKSMANPISTOL",
    ["heavypistol"] = "PICKUP_WEAPON_HEAVYPISTOL",
    ["heavyrevolver"] = "PICKUP_WEAPON_REVOLVER",
    ["revolver"] = "PICKUP_WEAPON_REVOLVER",
    ["doubleactionrevolver"] = "PICKUP_WEAPON_DOUBLEACTION",
    ["stungun"] = "PICKUP_WEAPON_STUNGUN",
    ["flaregun"] = "PICKUP_WEAPON_FLAREGUN",

    ["microsmg"] = "PICKUP_WEAPON_MICROSMG",
    ["smg"] = "PICKUP_WEAPON_SMG",
    ["assaultsmg"] = "PICKUP_WEAPON_ASSAULTSMG",
    ["combatpdw"] = "PICKUP_WEAPON_COMBATPDW",
    ["machinepistol"] = "PICKUP_WEAPON_MACHINEPISTOL",
    ["minismg"] = "PICKUP_WEAPON_MINISMG",

    ["mg"] = "PICKUP_WEAPON_MG",
    ["combatmg"] = "PICKUP_WEAPON_COMBATMG",
    ["gusenbergsweeper"] = "PICKUP_WEAPON_GUSENBERG",

    ["pumpshotgun"] = "PICKUP_WEAPON_PUMPSHOTGUN",
    ["sawedoffshotgun"] = "PICKUP_WEAPON_SAWNOFFSHOTGUN",
    ["assaultshotgun"] = "PICKUP_WEAPON_AUTOSHOTGUN",
    ["heavyshotgun"] = "PICKUP_WEAPON_HEAVYSHOTGUN",
    ["bullpupshotgun"] = "PICKUP_WEAPON_BULLPUPSHOTGUN",
    ["sweepershotgun"] = "PICKUP_WEAPON_AUTOSHOTGUN",
    ["doublebarrelshotgun"] = "PICKUP_WEAPON_DBSHOTGUN",
    ["musket"] = "PICKUP_WEAPON_MUSKET",

    ["assaultrifle"] = "PICKUP_WEAPON_ASSAULTRIFLE",
    ["carbinerifle"] = "PICKUP_WEAPON_CARBINERIFLE",
    ["advancedrifle"] = "PICKUP_WEAPON_ADVANCEDRIFLE",
    ["specialcarbine"] = "PICKUP_WEAPON_SPECIALCARBINE",
    ["bullpuprifle"] = "PICKUP_WEAPON_BULLPUPRIFLE",
    ["compactrifle"] = "PICKUP_WEAPON_COMPACTRIFLE",

    ["minigun"] = "PICKUP_WEAPON_MINIGUN",
    ["rpg"] = "PICKUP_WEAPON_RPG",
    ["railgun"] = "PICKUP_WEAPON_RAILGUN",
    ["grenadelauncher"] = "PICKUP_WEAPON_GRENADELAUNCHER",
    ["compactlauncher"] = "PICKUP_WEAPON_COMPACTLAUNCHER",
    ["hominglauncher"] = "PICKUP_WEAPON_HOMINGLAUNCHER",
    ["fireworklauncher"] = "PICKUP_WEAPON_FIREWORK",

    ["grenade"] = "PICKUP_WEAPON_GRENADE",
    ["pipebomb"] = "PICKUP_WEAPON_PIPEBOMB",
    ["proximitymine"] = "PICKUP_WEAPON_PROXMINE",
    ["stickybomb"] = "PICKUP_WEAPON_STICKYBOMB",
    ["teargas"] = "PICKUP_WEAPON_SMOKEGRENADE",
    ["molotov"] = "PICKUP_WEAPON_MOLOTOV",

    ["sniperrifle"] = "PICKUP_WEAPON_SNIPERRIFLE",
    ["heavysniper"] = "PICKUP_WEAPON_HEAVYSNIPER",
    ["marksmanrifle"] = "PICKUP_WEAPON_MARKSMANRIFLE",
}

local dropsite, pilot, aircraft, parachute, crate, pickup, blip, soundID

-- the next 16 lines add support for Scammer's Universal Menu, it can be removed if it causes any issues
AddEventHandler("menu:setup", function()
	TriggerEvent("menu:registerModuleMenu", "Crate Drop", function(id)
		local ammoAmounts = { 10, 20, 50, 100, 500, 1000, 9999 }
		for weaponLabel, weaponName in pairs(weaponList) do
			print(weaponLabel)
			TriggerEvent("menu:addModuleSubMenu", id, weaponLabel, function(id)
				for _, ammoAmount in ipairs(ammoAmounts) do
					TriggerEvent("menu:addModuleItem", id, "Ammo: " .. ammoAmount, nil, false, function()
                        TriggerEvent("crateDrop", weaponName, ammoAmount)
                        TriggerEvent("menu:hideMenu")
					end)
				end
			end, false)
		end
	end, false)
end)

RegisterCommand("drop", function(playerServerID, args, rawString)
    local dropCoords = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 10.0, 0.0)
    print("dropCoords.x: " .. dropCoords.x)
    if weaponList[args[1]] == nil then
        if tonumber(args[2]) == nil then
            print("Cratedrop failed: weapon and ammo count unrecognized")
        else
            print("Cratedrop failed: weapon unrecognized, ammo count: " .. args[2])
        end
    elseif weaponList[args[1]] ~= nil and tonumber(args[2]) == nil then
        TriggerEvent("crateDrop", weaponList[args[1]], 250, args[3] or false, args[4] or {["x"] = dropCoords.x, ["y"] = dropCoords.y, ["z"] = dropCoords.z})
        print("Cratedrop succeeded: weapon: " .. args[1] .. ", ammo count unrecognized, defaulting to 250")
    elseif weaponList[args[1]] ~= nil and tonumber(args[2]) ~= nil then
        TriggerEvent("crateDrop", weaponList[args[1]], tonumber(args[2]), args[3] or false, args[4] or {["x"] = dropCoords.x, ["y"] = dropCoords.y, ["z"] = dropCoords.z})
        print("Cratedrop succeeded: weapon: " .. args[1] .. ", ammo count: " .. args[2])
    end
end, false)

RegisterNetEvent("crateDrop")
AddEventHandler("crateDrop", function(weapon, ammo, roofCheck, coords)
    Citizen.CreateThread(function()

        local roofCheck = roofCheck or false -- if roofCheck is true then a check will be performed if a plane can drop a crate to the specified location before actually spawning a plane, if it can't, function won't be called

        if not coords.x or not coords.y or not coords.z or not tonumber(coords.x) or not tonumber(coords.y) or not tonumber(coords.z) then
            dropsite = vector3(0.0, 0.0, 72.0)
            print("Failed interpreting coords, defaulting to 0, 0, 72")
        else
            dropsite = vector3(coords.x, coords.y, coords.z)
        end

        if roofCheck then
            local ray = StartShapeTestRay(dropsite + vector3(0.0, 0.0, 200.0), dropsite, -1, -1, 0) -- bitwise flag could also be 17
            local _, hit, impactCoords = GetShapeTestResult(ray)
            if hit == 0 or #((dropsite - vector3(0.0, 0.0, 200.0)) - vector3(impactCoords)) < 10.0 then
                print("Dropping to given coordinates")
                DropCrate(weapon, ammo, dropsite)
            else
                print("Unable to drop to given coordinates") return
            end
        else
            print("Not checking if dropping is possible")
            DropCrate(weapon, ammo, dropsite)
        end

    end)
end)

function DropCrate(weapon, ammo, coords)
    Citizen.CreateThread(function()

        local requiredModels = {"p_cargo_chute_s", "ex_prop_adv_case_sm", "cuban800", "s_m_m_pilot_02", "prop_box_wood02a_pu", "prop_flare_01"} -- parachute, pickup case, plane, pilot, crate, flare

        for i = 1, #requiredModels do
            RequestModel(GetHashKey(requiredModels[i]))
            while not HasModelLoaded(GetHashKey(requiredModels[i])) do
                Wait(0)
            end
        end

        --[[
        RequestAnimDict("P_cargo_chute_S")
        while not HasAnimDictLoaded("P_cargo_chute_S") do -- wasn't able to get animations working
            Wait(0)
        end
        ]]

        RequestWeaponAsset(GetHashKey("weapon_flare")) -- flare won't spawn later in the script if we don't request it right now
        while not HasWeaponAssetLoaded(GetHashKey("weapon_flare")) do
            Wait(0)
        end

        local planeSpawn = coords + vector3(-400.0, 0.0, 500.0) -- location for plane spawning, should replace it with a system that spawns where the player isn't looking
        local heading = 270.0

        aircraft = CreateVehicle(GetHashKey("cuban800"), planeSpawn, heading, true, true) -- spawn the plane
        SetEntityHeading(aircraft, heading) -- the plane spawns behind the player facing the same direction as the player
        SetVehicleDoorsLocked(aircraft, 2) -- lock the doors because why not?
        SetEntityDynamic(aircraft, true)
        ActivatePhysics(aircraft)
        SetVehicleForwardSpeed(aircraft, 60.0)
        SetHeliBladesFullSpeed(aircraft) -- works for planes I guess
        SetVehicleEngineOn(aircraft, true, true, false)
        ControlLandingGear(aircraft, 3) -- retract the landing gear
        OpenBombBayDoors(aircraft) -- opens the hatch below the plane for added realism
        SetEntityProofs(aircraft, true, false, true, false, false, false, false, false)

        pilot = CreatePedInsideVehicle(aircraft, 1, GetHashKey("s_m_m_pilot_02"), -1, true, true) -- put the pilot in the plane
        SetBlockingOfNonTemporaryEvents(pilot, true) -- ignore explosions and other shocking events
        SetPedRandomComponentVariation(pilot, false)
        SetPedKeepTask(pilot, true)
        SetPlaneMinHeightAboveTerrain(aircraft, 50) -- the plane shouldn't dip below the defined altitude

        TaskVehicleDriveToCoord(pilot, aircraft, coords + vector3(0.0, 0.0, 500.0), 60.0, 0, GetHashKey("cuban800"), 262144, 15.0, -1.0); -- to the dropsite, could be replaced with sequencing

        local dropsite = vector2(coords.x, coords.y)
        local planeLocation = vector2(GetEntityCoords(aircraft).x, GetEntityCoords(aircraft).y)
        while not IsEntityDead(pilot) and #(planeLocation - dropsite) > 5.0 do -- wait for when the plane reaches the coords ± 5
            Wait(100)
            planeLocation = vector2(GetEntityCoords(aircraft).x, GetEntityCoords(aircraft).y) -- update plane coords for the loop
        end

        if IsEntityDead(pilot) == true then -- I think this will end the script if the pilot dies, no idea how to return works
            do return end
        end

        TaskVehicleDriveToCoord(pilot, aircraft, 0, 0, 500, 60.0, 0, GetHashKey("cuban800"), 262144, -1.0, -1.0) -- disposing of the plane like Rockstar does, send it to 0; 0 coords with -1.0 stop range, so the plane won't be able to achieve its task
        SetEntityAsNoLongerNeeded(pilot) 
        SetEntityAsNoLongerNeeded(aircraft)

        -- local crateSpawn = vector3(GetOffsetFromEntityInWorldCoords(aircraft, 0.0, 0.0, -5.0))
        local crateSpawn = vector3(coords.x, coords.y, GetEntityCoords(aircraft).z - 5.0) -- crate will drop to the exact position as planned, not at the plane's current position

        crate = CreateObject(GetHashKey("prop_box_wood02a_pu"), crateSpawn, true, true, true) -- a breakable crate to be spawned directly under the plane, probably could be spawned closer to the plane
        SetEntityLodDist(crate, 1000) -- so we can see it from the distance
        ActivatePhysics(crate)
        SetDamping(crate, 2, 0.1) -- no idea but Rockstar uses it
        SetEntityVelocity(crate, 0.0, 0.0, -0.2) -- I think this makes the crate drop down, not sure if it's needed as many times in the script as I'm using

        parachute = CreateObject(GetHashKey("p_cargo_chute_s"), crateSpawn, true, true, true) -- create the parachute for the crate
        SetEntityLodDist(parachute, 1000)
        SetEntityVelocity(parachute, 0.0, 0.0, -0.2) -- I think this makes the crate drop down, not sure if it's needed as many times in the script as I'm using
        -- PlayEntityAnim(parachute, "P_cargo_chute_S_deploy", "P_cargo_chute_S", 1000.0, false, false, false, 0, 0) -- disabled since animations don't work
        -- ForceEntityAiAndAnimationUpdate(parachute) -- pointless if animations aren't working

        pickup = CreateAmbientPickup(GetHashKey(weapon), crateSpawn, 0, ammo, GetHashKey("ex_prop_adv_case_sm"), true, true) -- we make the pickup, location doesn't matter too much, we're attaching it later
        ActivatePhysics(pickup)
        SetDamping(pickup, 2, 0.0245)
        SetEntityVelocity(pickup, 0.0, 0.0, -0.2) -- I think this makes the crate drop down, not sure if it's needed as many times in the script as I'm using

        soundID = GetSoundId() -- we need a sound ID for calling the native below, otherwise we won't be able to stop the sound later
        PlaySoundFromEntity(soundID, "Crate_Beeps", pickup, "MP_CRATE_DROP_SOUNDS", true, 0) -- crate beep sound emitted from the pickup

        blip = AddBlipForEntity(pickup) -- Rockstar did the blip exactly like this
        SetBlipSprite(blip, 408) -- 351 or 408 are both fine, 408 is just bigger
        SetBlipNameFromTextFile(blip, "AMD_BLIPN")
        SetBlipScale(blip, 0.7)
        SetBlipColour(blip, 2)
        SetBlipAlpha(blip, 120) -- blip will be semi-transparent

        -- local crateBeacon = StartParticleFxLoopedOnEntity_2("scr_crate_drop_beacon", pickup, 0.0, 0.0, 0.2, 0.0, 0.0, 0.0, 1065353216, 0, 0, 0, 1065353216, 1065353216, 1065353216, 0)--1.0, false, false, false) -- no idea how to make it work, weapon_flare will do for now
        -- SetParticleFxLoopedColour(crateBeacon, 0.8, 0.18, 0.19, false) -- reliant on the line above, Rockstar did it like this

        AttachEntityToEntity(parachute, pickup, 0, 0.0, 0.0, 0.1, 0.0, 0.0, 0.0, false, false, false, false, 2, true) -- attach the crate to the pickup
        AttachEntityToEntity(pickup, crate, 0, 0.0, 0.0, 0.3, 0.0, 0.0, 0.0, false, false, true, false, 2, true) -- attach the pickup to the crate, doing it in any other order makes the crate drop spazz out

        while HasObjectBeenBroken(crate) == false do -- wait till the crate gets broken (probably on impact), then continue with the script
            Wait(0)
        end

        local parachuteCoords = vector3(GetEntityCoords(parachute)) -- we get the parachute coords so we know where to drop the flare
        ShootSingleBulletBetweenCoords(parachuteCoords, parachuteCoords - vector3(0.0, 0.0, 0.001), 0, false, GetHashKey("weapon_flare"), 0, true, false, -1.0) -- flare needs to be dropped with coords like that, otherwise it remains static and won't remove itself later
        DetachEntity(parachute, true, true) -- detach parachute
        SetEntityCollision(parachute, false, true) -- remove collision, pointless right now but would be cool if animations would work and you'll be able to walk through the parachute while it's disappearing
        -- PlayEntityAnim(parachute, "P_cargo_chute_S_crumple", "P_cargo_chute_S", 1000.0, false, false, false, 0, 0) -- disabled since animations don't work
        DeleteEntity(parachute)
        DetachEntity(pickup) -- will despawn on its own
        SetBlipAlpha(blip, 255) -- make the blip fully visible

        while DoesEntityExist(pickup) do -- wait till the pickup gets picked up, then the script can continue
            Wait(0)
        end

        while DoesObjectOfTypeExistAtCoords(parachuteCoords, 10.0, GetHashKey("w_am_flare"), true) do
            Wait(0)
            local prop = GetClosestObjectOfType(parachuteCoords, 10.0, GetHashKey("w_am_flare"), false, false, false)
            RemoveParticleFxFromEntity(prop)
            SetEntityAsMissionEntity(prop, true, true)
            DeleteObject(prop)
        end

        if DoesBlipExist(blip) then -- remove the blip, should get removed when the pickup gets picked up anyway, but isn't a bad idea to make sure of it
            RemoveBlip(blip)
        end

        StopSound(soundID) -- stop the crate beeping sound
        ReleaseSoundId(soundID) -- won't need this sound ID any longer

        for i = 1, #requiredModels do
            Wait(0)
            SetModelAsNoLongerNeeded(GetHashKey(requiredModels[i]))
        end

        RemoveWeaponAsset(GetHashKey("weapon_flare"))
    end)
end

AddEventHandler('onResourceStop', function(resource)
    Citizen.CreateThread(function()
        if resource == GetCurrentResourceName() then

            --[[
            SetEntityAsMissionEntity(pilot, false, true)
            DeleteEntity(pilot)
            SetEntityAsMissionEntity(aircraft, false, true)
            DeleteEntity(aircraft) -- literally doesn't work
            ]]
            SetEntityAsNoLongerNeeded(pilot) 
            SetEntityAsNoLongerNeeded(aircraft)
            DeleteEntity(parachute)
            DeleteEntity(crate)
            RemovePickup(pickup)
            RemoveBlip(blip)
            StopSound(soundID)
            ReleaseSoundId(soundID)

            for i = 1, #requiredModels do
                Wait(0)
                SetModelAsNoLongerNeeded(GetHashKey(requiredModels[i]))
            end

        end
    end)
end)
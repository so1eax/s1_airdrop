RegisterNetEvent("airdrop:startAirdrop")
RegisterNetEvent("airdrop:getAirdropData")
RegisterNetEvent('airdrop:stopAirdrop')
RegisterNetEvent('airdrop:startEntitySound')

local function airdropData()
    local data = nil
    TriggerServerEvent("airdrop:getAirdropData")
    AddEventHandler('airdrop:getAirdropData', function (dt)
        data = dt
    end)
    while not data do
        Wait(100)
    end
    return data
end

local function sendNotif(text)
    BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandThefeedPostTicker(false, false)
end

local function openAirdropItemsMenu()
    lib.hideMenu('airdropItemsMenu')
    local option = {}
    for k,v in ipairs(airdropData().content) do
        table.insert(option, {label = v.name, description = v.quantity})
    end
    lib.registerMenu({
        id = "airdropItemsMenu",
        title = "Airdrop",
        options = option
    }, function(selected, scrollIndex, args)
        local input = lib.inputDialog('Airdrop', {
            {type = 'number', label = option[selected].label},
        })
        if airdropData().content[selected].quantity >= input[1] then
            if input[1] ~= 0 then
                local dist = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(airdrop))
                if dist < 2 then
                    TriggerServerEvent("airdrop:giveItem", selected, input[1])
                else
                    sendNotif(locales[Config.locale]['airdrop_toofarfromdrop'])
                end
            else
                sendNotif(locales[Config.locale]['airdrop_invalidquantity'])
            end
        else
            sendNotif(locales[Config.locale]['airdrop_invalidquantity'])
        end
    end)
    lib.showMenu('airdropItemsMenu')
end

local soundId = nil
AddEventHandler('airdrop:startEntitySound', function ()
    soundId = GetSoundId()
    while not airdrop do
        Wait(1000)
    end
    PlaySoundFromEntity(soundId, 'Crate_Beeps', airdrop, 'MP_CRATE_DROP_SOUNDS', false, 0)
end)

AddEventHandler('playerSpawned', function()
    TriggerServerEvent('playerSpawned')
end)

AddEventHandler('onResourceStop', function (resource)
    if GetCurrentResourceName() == resource then
        DeleteEntity(airdrop)
    end
end)

local airdropStopped = false
AddEventHandler("airdrop:startAirdrop", function (airdropCoords)
    sendNotif(locales[Config.locale]['airdrop_startnotif'])
    airdropBlip = AddBlipForRadius(airdropCoords.x, airdropCoords.y, airdropCoords.z, 120.0)
    SetBlipColour(airdropBlip, 1)
    SetBlipAlpha(airdropBlip, 128)
    SetBlipHighDetail(airdropBlip, true)

    local airdropModel = Config.main.airdropModel
    RequestModel(airdropModel)
    while not HasModelLoaded(airdropModel) do
        Citizen.Wait(100)
    end

    Citizen.CreateThread(function ()
        while true do
            Wait(1000)
            local retval, groundZ = GetGroundZFor_3dCoord(airdropCoords.x, airdropCoords.y, airdropCoords.z, true)
            if groundZ ~= 0.0 then
                airdrop = CreateObject(airdropModel, airdropCoords.x, airdropCoords.y, groundZ,false,false,false)
                FreezeEntityPosition(airdrop, true)
                break
            end
        end
    end)

    while true do
        Wait(0)
        local dist = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(airdrop))
        if not airdropStopped then
            if dist < 3 then
                BeginTextCommandDisplayHelp("STRING")
                AddTextComponentSubstringPlayerName(locales[Config.locale]['keypress_openairdrop'])
                EndTextCommandDisplayHelp(0, false, true, 5000)
                if IsControlJustPressed(0, 38) then
                    if airdropData().hasStarted then
                            if airdropData().activationFinished then
                                if not airdropData().hasBeenActivated then
                                    sendNotif(locales[Config.locale]['airdrop_successfullactivation'])
                                    TriggerServerEvent('airdrop:startOpen')
                                elseif airdropData().hasBeenActivated then
                                    if airdropData().canBeOpened then
                                        openAirdropItemsMenu()
                                    elseif not airdropData().canBeOpened then
                                        sendNotif(tostring(airdropData().timeBeforeOpen) .. locales[Config.locale]['airdrop_waitbeforeopen'])
                                    end
                                end
                            elseif not airdropData().activationFinished then
                                sendNotif(tostring(airdropData().timeBeforeActivating) .. locales[Config.locale]['airdrop_waitbeforeactivate'])
                            end
                    elseif not airdropData().hasStarted then
                        break
                    end
                end
            else
                Wait(1000)
            end
        elseif airdropStopped then
            break
        end
    end
end)

AddEventHandler('airdrop:stopAirdrop', function (args)
    if args == "full" then
        DeleteEntity(airdrop)
        RemoveBlip(airdropBlip)
        airdropStopped = true
    elseif args == "less" then
        StopSound(soundId)
        ReleaseSoundId(soundId)
        soundId = nil
        RemoveBlip(airdropBlip)
    end
end)
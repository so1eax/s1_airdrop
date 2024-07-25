ESX = exports["es_extended"]:getSharedObject()

RegisterNetEvent('playerSpawned')
RegisterNetEvent('airdrop:startOpen')
RegisterNetEvent('airdrop:getAirdropData')
RegisterNetEvent('airdrop:giveItem')

local currentAirdrop = {
    hasStarted = false,
    hasBeenActivated = false,
    coords = nil,
    timeBeforeOpen = nil,
    timeBeforeActivating = nil,
    activationFinished = false,
    canBeOpened = false,
    content = {}
}

local function stopAirdrop(args)
    if args == "full" then
        currentAirdrop = {
            hasStarted = false,
            hasBeenActivated = false,
            coords = nil,
            timeBeforeOpen = nil,
            timeBeforeActivating = nil,
            activationFinished = false,
            canBeOpened = false,
            content = {}
        }
        TriggerClientEvent("airdrop:stopAirdrop", -1, args)
    elseif args == "less" then
        TriggerClientEvent("airdrop:stopAirdrop", -1, args)
    end
end

local function startItemCheck()
    while true do
        Wait(5000)
        if currentAirdrop.content[1].quantity == 0 and currentAirdrop.content[2].quantity == 0 and currentAirdrop.content[3].quantity == 0 and currentAirdrop.content[4].quantity == 0 then
            stopAirdrop("full")
            break
        end
    end
end


local function startDecounter()
    while true do
        Wait(1000)

        if currentAirdrop.hasStarted then

            if not currentAirdrop.activationFinished then

                if currentAirdrop.timeBeforeActivating == nil then
                    currentAirdrop.timeBeforeActivating = Config.main.timeBeforeActivating
                end

                if currentAirdrop.timeBeforeActivating > 0 then
                    currentAirdrop.timeBeforeActivating = currentAirdrop.timeBeforeActivating - 1
                else
                    currentAirdrop.activationFinished = true
                end
            elseif currentAirdrop.activationFinished then
                if currentAirdrop.hasBeenActivated then
                    if currentAirdrop.timeBeforeOpen == nil then
                        currentAirdrop.timeBeforeOpen = Config.main.timeBeforeOpen
                    end

                    if currentAirdrop.timeBeforeOpen > 0 then
                        currentAirdrop.timeBeforeOpen = currentAirdrop.timeBeforeOpen - 1
                    else
                        currentAirdrop.content = Config.rewardItems
                        currentAirdrop.canBeOpened = true
                        stopAirdrop("less")
                        startItemCheck()
                        break
                    end
                end
            end
        end
    end
end
local function startAirdrop()
    currentAirdrop.hasStarted = true
    currentAirdrop.coords = Config.airdropCoords[math.random(1, #Config.airdropCoords)]
    TriggerClientEvent("airdrop:startAirdrop", -1, currentAirdrop.coords)
    startDecounter()
end

AddEventHandler('playerSpawned', function()
    if currentAirdrop.hasStarted then
        TriggerClientEvent("airdrop:startAirdrop", source, currentAirdrop.coords)
        TriggerClientEvent('airdrop:startEntitySound', source)
    end
end)

AddEventHandler('airdrop:startOpen', function ()
    currentAirdrop.hasBeenActivated = true
    TriggerClientEvent("airdrop:startEntitySound", -1)
end)

AddEventHandler('airdrop:getAirdropData', function ()
    TriggerClientEvent('airdrop:getAirdropData', source, currentAirdrop)
end)

AddEventHandler('airdrop:giveItem', function (selected, quantity)
    currentAirdrop.content[selected].quantity = currentAirdrop.content[selected].quantity - quantity
    local xPlayer = ESX.GetPlayerFromId(source)
    xPlayer.addInventoryItem(currentAirdrop.content[selected].name, quantity)
end)

Citizen.CreateThread(function ()
    for k,v in ipairs(Config.airdropHours) do
        Citizen.Wait(60000)
        local currentHour = tonumber(os.date("%H"))
        local currentMinute = tonumber(os.date("%M"))

        if currentHour == v.hour and currentMinute == v.minute then
            if not currentAirdrop.hasStarted then
                print("AIRDROP STARTED")
                startAirdrop()
            end
        end
    end
end)

RegisterCommand("startad", function ()
    startAirdrop()
end, true)
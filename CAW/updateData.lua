function GatherInventoryData()

    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local InventoryModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Inventory"))
    
    local inventoryList = {}
    local stacks = InventoryModule.Stacks or {}
    
    for _, data in pairs(stacks) do
        if type(data) == "table" and data.Id and (data.Amount or 0) > 0 then
            table.insert(inventoryList, {
                name = tostring(data.Id),
                qty = data.Amount
            })
        end
    end
    
    return inventoryList
end

function UpdateApiData(myBot, PlayTime)
    local HttpService = game:GetService("HttpService")
    local player = game:GetService("Players").LocalPlayer
    local requestFunc = http_request or request or (syn and syn.request) or (fluxus and fluxus.request)

    if not requestFunc then
        warn("Error: Fungsi http request tidak ditemukan pada Executor ini.")
        return
    end
    print("B")
    if not player then return end
    print("C")

    local inventoryData = GatherInventoryData()
    print("API - 3")

    print(myBot.farmWorld)
    print(myBot.storageWorld)
    print(myBot.lastUpdate)
    print(PlayTime)

    local payload = {
        username = player.Name,
        displayName = player.DisplayName,
        userId = player.UserId,
        farmWorld = myBot.farmWorld or "-",
        storageWorld = myBot.storageWorld or "-",
        playtime = PlayTime,
        lastUpdate = myBot.lastUpdate,
        inventory = inventoryData,
    }
    
    local jsonPayload = HttpService:JSONEncode(payload)
    
    local requestData = {
        Url = DataAPI,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json", 
            ["x-access-key"] = accessKey
        },
        Body = jsonPayload
    }

    local success, response = pcall(function() return requestFunc(requestData) end)
    
    if success and response then
        if response.StatusCode == 200 then
            print("Berhasil sinkronisasi data ke API!")
        else
            warn("Gagal kirim data! Status: " .. tostring(response.StatusCode) .. " | Body: " .. tostring(response.Body))
        end
    else
        warn("Request API gagal total: " .. tostring(response))
    end
end

function GatherInventoryData()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Inventory = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Inventory"))
    
    -- Fungsi ringkas untuk merapikan nama (dirt_sapling -> Dirt Sapling)
    local function formatName(str)
        return (string.gsub(string.gsub(str, "_", " "), "(%a)([%w]*)", function(a, b) 
            return string.upper(a) .. string.lower(b) 
        end))
    end

    local summaryMap = {}
    local stacks = Inventory.Stacks or {}
    local slotButtons = Inventory.SlotButtons or {}
    
    for slotIndex, data in pairs(stacks) do
        if type(data) == "table" and data.Id and (data.Amount or 0) > 0 then
            local rawId = tostring(data.Id)
            local cleanName = formatName(rawId)
            
            -- Pengecekan Sapling yang lebih rapi
            if string.find(string.lower(rawId), "sapling") and not string.find(string.lower(cleanName), "sapling") then
                cleanName = cleanName .. " [S]"
            end
            
            -- 1. Ambil Icon langsung dari UI (Metode Paling Akurat)
            local iconId = "rbxassetid://0"
            if slotButtons[slotIndex] then
                local display = slotButtons[slotIndex]:FindFirstChild("ItemDisplay")
                if display then
                    if display:IsA("ImageLabel") then 
                        iconId = display.Image
                    elseif display:FindFirstChildWhichIsA("ImageLabel") then 
                        iconId = display:FindFirstChildWhichIsA("ImageLabel").Image 
                    end
                end
            end
            
            -- 2. Grouping & Menjumlahkan Qty berdasarkan Nama Bersih
            if summaryMap[cleanName] then
                summaryMap[cleanName].qty = summaryMap[cleanName].qty + data.Amount
                -- Jika sebelumnya icon kosong tapi sekarang ketemu di stack lain, timpa
                if summaryMap[cleanName].iconId == "rbxassetid://0" and iconId ~= "rbxassetid://0" then
                    summaryMap[cleanName].iconId = iconId
                end
            else
                summaryMap[cleanName] = {
                    name = cleanName,
                    qty = data.Amount,
                    iconId = iconId
                }
            end
        end
    end
    
    -- Convert map ke array list
    local inventoryList = {}
    for _, item in pairs(summaryMap) do
        table.insert(inventoryList, item)
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
    if not player then return end

    local inventoryData = GatherInventoryData()

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
        if response.StatusCode ~= 200 then
            warn("Gagal kirim data! Status: " .. tostring(response.StatusCode) .. " | Body: " .. tostring(response.Body))
        end
    else
        warn("Request API gagal total: " .. tostring(response))
    end
end

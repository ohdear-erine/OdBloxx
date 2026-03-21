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

local function formatAge(seconds)
    if seconds < 60 then
        return seconds .. " sec"
    elseif seconds < 3600 then
        return math.floor(seconds / 60) .. " mins"
    elseif seconds < 86400 then
        return math.floor(seconds / 3600) .. " hours"
    elseif seconds < 2592000 then
        return math.floor(seconds / 86400) .. " days"
    elseif seconds < 31536000 then
        return math.floor(seconds / 2592000) .. " months"
    else
        return math.floor(seconds / 31536000) .. " years"
    end
end

local function getDeepStats()
    local stats = {
        Joined = "-",
        Playtime = "-",
        Hits = 0,
        BlockSmashed = 0,
        TreeHarvested = 0,
        TreePlanted = 0,
        BackpackSlots = 0
    }

    local Remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
    local RequestPlayerStats = Remotes and Remotes:FindFirstChild("RequestPlayerStats")
    
    if RequestPlayerStats and RequestPlayerStats:IsA("RemoteFunction") then
        local success, rawData = pcall(function()
            return RequestPlayerStats:InvokeServer({
                "JoinDate",        -- 1
                "AccountAge",      -- 2
                "Playtime",        -- 3
                "SessionStart",    -- 4
                "Hit",             -- 5
                "Smashed",         -- 6
                "Harvested",       -- 7
                "Planted",         -- 8
                "Spliced",         -- 9
                "BackpackUpgrade"  -- 10
            })
        end)

        if success and type(rawData) == "table" then
            local data = {}
            for k, v in pairs(rawData) do 
                data[tonumber(k)] = v 
            end

            -- ==========================================
            -- KALKULASI JOINED DATE & ACCOUNT AGE
            -- ==========================================
            local joinDateUnix = data[1] or os.time()
            local accountAgeSecs = data[2] or 0
            
            local dateTable = os.date("*t", joinDateUnix)
            local day = dateTable.day
            local suffix = "th"
            local lastDigit = day % 10
            
            if day < 11 or day > 13 then
                if lastDigit == 1 then suffix = "st"
                elseif lastDigit == 2 then suffix = "nd"
                elseif lastDigit == 3 then suffix = "rd"
                end
            end
            
            local monthName = os.date("%B", joinDateUnix)
            local formattedDate = day .. suffix .. " " .. monthName .. " " .. dateTable.year
            local agoText = "(" .. formatAge(accountAgeSecs) .. " ago)"
            
            stats.Joined = formattedDate .. " " .. agoText

            -- ==========================================
            -- KALKULASI PLAYTIME & STATS LAINNYA
            -- ==========================================
            local savedPlaytime = data[3] or 0
            local sessionStart = data[4] or workspace:GetServerTimeNow()
            
            local totalSeconds = savedPlaytime + (workspace:GetServerTimeNow() - sessionStart)
            
            local h = math.floor(totalSeconds / 3600)
            local m = math.floor((totalSeconds % 3600) / 60)
            local s = math.floor(totalSeconds % 60)
            local timeString = ""
            if h > 0 then timeString = timeString .. h .. "h " end
            if m > 0 then timeString = timeString .. m .. "m " end
            timeString = timeString .. s .. "s"

            stats.Playtime = string.gsub(timeString, "^%s*(.-)%s*$", "%1")
            stats.Hits = data[5] or 0
            stats.BlockSmashed = data[6] or 0
            stats.TreeHarvested = data[7] or 0
            stats.TreePlanted = data[8] or 0
            stats.BackpackSlots = ((data[10] or 0) * 10) + 16
        end
    end
    
    return stats
end

function UpdateApiData(myBot)
    local HttpService = game:GetService("HttpService")
    local player = game:GetService("Players").LocalPlayer
    local requestFunc = http_request or request or (syn and syn.request) or (fluxus and fluxus.request)

    if not requestFunc then
        warn("Error: Fungsi http request tidak ditemukan pada Executor ini.")
        return
    end
    if not player then return end

    local inventoryData = GatherInventoryData()
    local playerStats = getDeepStats()

    local payload = {
        username = player.Name,
        displayName = player.DisplayName,
        userId = player.UserId,
        farmWorld = myBot.farmWorld or "-",
        storageWorld = myBot.storageWorld or "-",
        CurrentWorld = myBot.CurrentWorld or "-",
        gems = myBot.gems,
        totalGems = myBot.totalGems or myBot.gems,
        lastUpdate = myBot.lastUpdate,
        inventory = inventoryData,
        fullFarm = myBot.fullFarm or {},
        stats = playerStats
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

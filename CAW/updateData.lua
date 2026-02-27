-- 1. Fungsi untuk mengumpulkan dan memformat data tas
local function GatherInventoryData()
    local inventoryList = {}
    local stacks = InventoryModule.Stacks or {}
    
    for _, data in pairs(stacks) do
        -- Pastikan slot valid dan jumlahnya lebih dari 0
        if type(data) == "table" and data.Id and (data.Amount or 0) > 0 then
            table.insert(inventoryList, {
                name = tostring(data.Id), -- Menghasilkan "magenta_block", "dirt", dll.
                qty = data.Amount
            })
        end
    end
    
    return inventoryList
end

-- 2. Fungsi Utama Update API
function UpdateApiData(PlayTime)
    local HttpService = game:GetService("HttpService")
    local player = game:GetService("Players").LocalPlayer
    local requestFunc = http_request or request or (syn and syn.request) or (fluxus and fluxus.request)
    
    if not requestFunc then
        warn("Error: Fungsi http request tidak ditemukan pada Executor ini.")
        return
    end
    if not player then return end

    -- Memanggil fungsi pengumpul data tas yang baru kita buat
    local inventoryData = GatherInventoryData()

    -- Menyusun Payload persis seperti JSON contoh
    local payload = {
        username = player.Name,
        displayName = player.DisplayName,
        userId = player.UserId,
        farmWorld = dataBot.farmWorld or "-",
        storageWorld = dataBot.storageWorld or "-",
        playtime = PlayTime,
        lastUpdate = dataBot.lastUpdate,
        inventory = inventoryData, -- Akan terisi array otomatis
    }
    
    local jsonPayload = HttpService:JSONEncode(payload)
    
    local requestData = {
        Url = DataAPI,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json", 
            ["x-access-key"] = accessKey -- Samakan huruf kecil/besar dengan sistem validasi awal kamu
        },
        Body = jsonPayload
    }

    -- Eksekusi request dengan aman (anti-crash)
    local success, response = pcall(function() return requestFunc(requestData) end)
    
    if success and response then
        -- Cek jika status sukses (200 OK)
        if response.StatusCode == 200 then
            print("Berhasil sinkronisasi data ke API!")
        else
            warn("Gagal kirim data! Status: " .. tostring(response.StatusCode) .. " | Body: " .. tostring(response.Body))
        end
    else
        warn("Request API gagal total: " .. tostring(response))
    end
end

local HttpGet = game.HttpGet
local PlaceId = game.PlaceId

local success, Games = pcall(function()
    return loadstring(HttpGet(game, "https://raw.githubusercontent.com/ohdear-erine/OdBloxx/refs/heads/main/Resto/GameList.lua"))()
end)

if not success or not Games then
    warn("Gagal load GameList")
    return
end

local data = Games[PlaceId]
if not data then
    warn("Game tidak didukung:", PlaceId)
    return
end

local url

if type(data) == "table" then
    url = data[getgenv().od or 1]
else
    url = data
end

if not url then
    warn("Script tidak ditemukan")
    return
end

local ok, err = pcall(function()
    loadstring(HttpGet(game, url))()
end)

if not ok then
    warn("Gagal load script:", err)
end

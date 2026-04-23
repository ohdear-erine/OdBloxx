local HttpGet = game.HttpGet
local GameId = game.GameId

local success, Games = pcall(function()
    return loadstring(HttpGet(game, "https://raw.githubusercontent.com/ohdear-erine/OdBloxx/refs/heads/main/Ohdear/GameList.lua"))()
end)

if not success or not Games then
    warn("Gagal load GameList")
    return
end

local url = Games[GameId]
if not url then
    warn("Game tidak didukung:", GameId)
    return
end

local ok, err = pcall(function()
    loadstring(HttpGet(game, url))()
end)

if not ok then
    warn("Gagal load script:", err)
end

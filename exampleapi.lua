local mod = RegisterMod("Example API", 1.0)
local json = require("json")

local apiVar = {
    Game = Game(),
    Mods = {}
}

function apiVar.AutomateModSave(mod)
    apiVar.Mods[#apiVar.Mods + 1] = mod
end

function apiVar.SaveModData(mod)
    Isaac.SaveModData(mod, json.encode(mod.Data))
end

function apiVar.LoadModData(mod)
    if Isaac.HasModData(mod) then
        mod.Data = json.decode(Isaac.LoadModData(mod))
    else
        mod.Data = {}
    end
end

function mod:PlayerInit(player)
    for _, mod in ipairs(apiVar.Mods) do
        apiVar.LoadModData(mod)
    end

    apiVar.Room = apiVar.Game:GetRoom()
    apiVar.Level = apiVar.Game:GetLevel()
    apiVar.Players = {}
    apiVar.Entities = Isaac.GetRoomEntities()
    for i = 1, 4 do
        apiVar.Players[i] = Isaac.GetPlayer(i - 1)
    end
end

function mod:GameExit(shouldSave)
    if shouldSave then
        for _, mod in ipairs(apiVar.Mods) do
            apiVar.SaveModData(mod)
        end
    end
end

function mod:NewLevel()
    for _, mod in ipairs(apiVar.Mods) do
        apiVar.SaveModData(mod)
    end
end

function mod:NewRoom()
    apiVar.Level = apiVar.Game:GetLevel()
    apiVar.Room = apiVar.Game:GetRoom()
    apiVar.Entities = Isaac.GetRoomEntities()
end

function mod:Update()
    apiVar.GameFrame = apiVar.Game:GetFrameCount()
    apiVar.RoomFrame = apiVar.Room:GetFrameCount()
end

mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.Update)
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.NewRoom)
mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, mod.NewLevel)
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, mod.GameExit)
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, mod.PlayerInit)

local function start()
    BindingAPI.PublishAPI("Example API", apiVar)
end

local START_FUNC = start
if BindingAPI then START_FUNC()
else if not __bindingAPIInit then
__bindingAPIInit={Mod = RegisterMod("BindingAPIRenderWarning", 1.0)}
__bindingAPIInit.Mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
	if not BindingAPI then
		Isaac.RenderText("A mod requires Binding API to run, go get it on the workshop!", 100, 40, 255, 255, 255, 1)
	end
end) end
__bindingAPIInit[#__bindingAPIInit+1]=START_FUNC end

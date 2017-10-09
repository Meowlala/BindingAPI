local mod = RegisterMod("Example Mod", 1.0)

local exAPI

local function PostUpdate()
    for _, ent in ipairs(exAPI.Entities) do
        if not ent:IsDead() and not ent:ToPlayer() then
            ent:Kill()
        end
    end
end


local function start(api)
    api.SetDependency("Example Mod", "Example API")
    api.AddCallback("API_INIT", function()
        exAPI = api.GetAPI("Example API")
        mod:AddCallback(ModCallbacks.MC_POST_UPDATE, PostUpdate)
    end, "Example API")
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

--[[ Blob that any mods using BindingAPI or anything dependent on BindingAPI will need to include
local START_FUNC = start
if BindingAPI then START_FUNC(BindingAPI)
else if not __bindingAPIInit then
__bindingAPIInit={Mod = RegisterMod("BindingAPIRenderWarning", 1.0)}
__bindingAPIInit.Mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
	if not BindingAPI then
		Isaac.RenderText("A mod requires Binding API to run, go get it on the workshop!", 100, 40, 255, 255, 255, 1)
	end
end) end
__bindingAPIInit[#__bindingAPIInit+1]=START_FUNC end
]]

local mod = RegisterMod("Binding API", 1.0)
BindingAPI = {
    CallbackRegister = {},
    Callbacks = {},
    APIs = {},
    Dependencies = {}
}

--[[ Class Constructor, EX
local MyClass = BindingAPI.Class()
function MyClass:Init(name)
    self.Name = name
end

local myInst = MyClass("MyName")
Isaac.DebugString(myInst.Name) -- Outputs "MyName"
]] -- NOT ACTUALLY USED, MAYBE MOVE TO SEPARATE HELPER API?
function BindingAPI.Class()
    local newClass = {}
    setmetatable(newClass, {
        __call = function(tbl, ...)
            local inst = {}
            setmetatable(inst, {
                __index = tbl
            })
            if inst.Init then
                inst:Init(...)
            end

            if inst.PostInit then
                inst:PostInit(...)
            end

            return inst
        end
    })
    return newClass
end

function BindingAPI.RegisterCallback(id, fn) -- Registers a callback's ID and function to be called when AddCallback is called with its ID, also retroactively calls on all previously defined callbacks with that id.
    BindingAPI.CallbackRegister[id] = fn
    if BindingAPI.Callbacks[id] then
        for _, callback in ipairs(BindingAPI.Callbacks[id]) do
            fn(callback.Function, unpack(callback.Parameters))
        end
        BindingAPI.Callbacks[id] = nil
    end
end

function BindingAPI.GetCallbacks(id)
    if not BindingAPI.Callbacks[id] then
        BindingAPI.Callbacks[id] = {}
    end

    return BindingAPI.Callbacks[id]
end

function BindingAPI.AppendCallback(id, fn, ...)
    if not BindingAPI.Callbacks[id] then
        BindingAPI.Callbacks[id] = {}
    end

    BindingAPI.Callbacks[id][#BindingAPI.Callbacks[id] + 1] = {
        Function = fn,
        Parameters = {...}
    }
end

function BindingAPI.AddCallback(id, fn, ...) -- The user adds a callback, which calls the function passed in when the callback was registered, which can handle adding to a list or such.
    if BindingAPI.CallbackRegister[id] then
        BindingAPI.CallbackRegister[id](fn, ...)
    else
        BindingAPI.AppendCallback(id, fn, ...)
    end
end

local function CheckAPIInitParams(parameters, justPublished)
    local shouldCall = true
    local isWantedAPI = false
    if #parameters > 0 then
        for _, param in ipairs(parameters) do
            if not BindingAPI.APIs[param] then
                shouldCall = false
            end

            if justPublished and param == justPublished then
                isWantedAPI = true
            end
        end
    end

    return shouldCall and (isWantedAPI or not justPublished or #parameters == 0)
end

BindingAPI.RegisterCallback("API_INIT", function(fn, ...) -- So that API_INIT is called if all needed apis were already published.
    local parameters = {...}
    if CheckAPIInitParams(parameters) then
        fn()
    end

    BindingAPI.AppendCallback("API_INIT", fn, ...)
end)

function BindingAPI.PublishAPI(id, apiVar) -- An API would call this function with its name & api variable ex BindingAPI.PublishAPI("AlphaAPI", AlphaAPI). This means only one global variable is needed.
    BindingAPI.APIs[id] = apiVar

    Isaac.DebugString("[BindingAPI] Published API " .. id)

    local initCallbacks = BindingAPI.GetCallbacks("API_INIT")
    if initCallbacks then
        for _, callback in ipairs(initCallbacks) do
            if CheckAPIInitParams(callback.Parameters, id) then
                callback.Function()
            end
        end
    end
end

function BindingAPI.GetAPI(id)
    return BindingAPI.APIs[id]
end

function BindingAPI.CallIfAPI(apiID, funcName, ...)
    if BindingAPI.APIs[id] and BindingAPI.APIs[id][funcName] then
        return BindingAPI.APIs[id][funcName](...)
    end
end

function BindingAPI.GetIfAPI(apiID, varName)
    if BindingAPI.APIs[id] then
        return BindingAPI.APIs[id][varName]
    end
end

function BindingAPI.SetIfAPI(apiID, varName, setTo)
    if BindingAPI.APIs[id] then
        BindingAPI.APIs[id][varName] = setTo
        return true
    end
end

function BindingAPI.SetDependency(modName, ...) -- Sets up warnings for missing apis, takes mod name and any number of apis the mod is dependent on, ex BindingAPI.SetDependency("Devil's Harvest", "ProAPI", "SomeOtherAPI")
    BindingAPI.Dependencies[#BindingAPI.Dependencies + 1] = {
        Mod = modName,
        RequiredAPIs = {...}
    }
end

mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
    local numLines = 0
    for _, dependencyData in ipairs(BindingAPI.Dependencies) do
        local missingAPIs = {}
        for _, api in ipairs(dependencyData.RequiredAPIs) do
            if not BindingAPI.APIs[api] then
                missingAPIs[#missingAPIs + 1] = api
            end
        end

        if #missingAPIs > 0 then
            numLines = numLines + 1
            local text = "Mod " .. dependencyData.Mod .. " requires API"
            if #missingAPIs > 1 then
                text = text .. "s "
            else
                text = text .. " "
            end

            for x, api in ipairs(missingAPIs) do
                if x < #missingAPIs - 1 then
                    text = text .. api .. ", "
                elseif x < #missingAPIs then
                    text = text .. api .. " and "
                else
                    text = text .. api .. " "
                end
            end

            text = text .. "to run!"

            Isaac.RenderScaledText(text, 420 - (string.len(text) * (6 * 0.8)), 40 + (numLines * (12 * 0.8)), 0.8, 0.8, 255, 255, 255, 1)
        end
    end
end)

if __bindingAPIInit then
	for _, fn in ipairs(__bindingAPIInit) do
		fn(BindingAPI)
	end
	__bindingAPIInit = {}
end

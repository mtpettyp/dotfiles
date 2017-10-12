
hs.window.animationDuration = 0

local ctrlaltcmd = {"ctrl", "alt", "cmd"}

hs.hotkey.bind({"cmd"}, "e", hs.hints.windowHints)
hs.hotkey.bind(ctrlaltcmd, "g", hs.grid.toggleShow)

-- Grid configuration
hs.grid.setGrid('2x2')

hs.loadSpoon("WinWin")
if spoon.WinWin then
    hs.hotkey.bind(ctrlaltcmd, "F", function() spoon.WinWin:moveAndResize("fullscreen") end)
    hs.hotkey.bind(ctrlaltcmd, "Left", function() spoon.WinWin:moveAndResize("halfleft") end)
    hs.hotkey.bind(ctrlaltcmd, "Right", function() spoon.WinWin:moveAndResize("halfright") end)
    hs.hotkey.bind(ctrlaltcmd, "Up", function() spoon.WinWin:moveAndResize("halfup") end)
    hs.hotkey.bind(ctrlaltcmd, "Down", function() spoon.WinWin:moveAndResize("halfdown") end)
end

local display_laptop = "Color LCD"
local display_dell_left = function() return hs.screen('-1, 0') end
local display_dell_right = function() return hs.screen('0, 0') end

local top50 = hs.geometry.rect(0, 0, 1, 0.5)
local bottom50 = hs.geometry.rect(0, 0.5, 1, 0.5)

local laptop_display = {
    {"iTerm2",            nil,   display_laptop, top50,               nil, nil},
    {"Google Chrome",     nil,   display_laptop, hs.layout.maximized, nil, nil},
    {"Eclipse",           nil,   display_laptop, hs.layout.maximized, nil, nil},
    {"Code",              nil,   display_laptop, hs.layout.maximized, nil, nil},
}

local desk_display = {
    {"iTerm2",            nil,   display_dell_right(), hs.layout.left50,    nil, nil},
    {"Google Chrome",     nil,   display_dell_left(),  hs.layout.maximized, nil, nil},
    {"Eclipse",           nil,   display_dell_right(), hs.layout.maximized, nil, nil},
    {"Code",              nil,   display_dell_right(), hs.layout.maximized, nil, nil},
    {"iTunes",            nil,   display_laptop,       nil, nil, nil},
    {"Slack",             nil,   display_laptop,       nil, nil, nil},
    {"WhatsApp",          nil,   display_laptop,       nil, nil, nil},
}

function screenWatcher()
    print(hs.inspect.inspect(hs.screen.allScreens(), "allScreens"))
    screenCount = #hs.screen.allScreens()

    if screenCount == 1 then
        hs.layout.apply(laptop_display)
    elseif screenCount == 3 then
        hs.layout.apply(desk_display)
    end
end

hs.screen.watcher.new(screenWatcher):start()
hs.hotkey.bind(ctrlaltcmd, 'S', screenWatcher)

function reloadConfig(files)
    doReload = false
    for _,file in pairs(files) do
        if file:sub(-4) == ".lua" then
            doReload = true
        end
    end
    if doReload then
        hs.reload()
    end
end
hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()
hs.alert.show("Config loaded")

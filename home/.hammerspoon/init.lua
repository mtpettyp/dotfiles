-- hotkey mash
local mash 	 = {"ctrl", "alt"}
local mash_app 	 = {"cmd", "alt", "ctrl"}
local mash_shift = {"ctrl", "alt", "shift"}

hs.hotkey.bind({"cmd"}, "e", hs.hints.windowHints)
hs.hotkey.bind(mash_app, "g", hs.grid.toggleShow)


-- Grid configuration
hs.grid.setGrid('2x2')

hs.loadSpoon("WinWin")
if spoon.WinWin then
    hs.hotkey.bind(mash_app, "f", function() spoon.WinWin:moveAndResize("fullscreen") end)
    hs.hotkey.bind(mash_app, "Left", function() spoon.WinWin:moveAndResize("halfleft") end)
    hs.hotkey.bind(mash_app, "Right", function() spoon.WinWin:moveAndResize("halfright") end)
    hs.hotkey.bind(mash_app, "Up", function() spoon.WinWin:moveAndResize("halfup") end)
    hs.hotkey.bind(mash_app, "Down", function() spoon.WinWin:moveAndResize("halfdown") end)


end


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

hs.hotkey.bind({"cmd"}, "e", hs.hints.windowHints)
hs.hotkey.bind({"cmd", "alt", "ctrl"}, "g", hs.grid.toggleShow)


-- Grid configuration
hs.grid.setGrid('2x2')


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

-- Mendax by Algar
-- Version 1.0
-- A macroquest script to trade all of your AA books into Master Mendax on the EQ Might server.
-- /lua run mendax to start. The script will see itself out when finished.

local mq = require('mq')
local nav = mq.TLO.Navigation
local server = mq.TLO.EverQuest.Server()
local mendax = mq.TLO.Spawn("=Master Mendax")
local books = {
    "Grimoire of Profound Experience",
    "Grimoire of Boundless Experience",
    "Grimoire of Otherwordly Experience",
    "Grimoire of Raidleader Experience",
}

-- Helpers
local function tradeBook(bookName)
    if mq.TLO.Cursor() ~= nil then
        mq.cmd("/autoinventory")
        mq.delay(250, function() return not mq.TLO.Cursor() end)
    end

    if not mq.TLO.Cursor() then
        mq.cmdf('/itemnotify "%s" leftmouseup', bookName)
        mq.delay(500, function() return mq.TLO.Cursor() ~= nil end)
        if mq.TLO.Target.CleanName() ~= "Master Mendax" then
            print("Mendax: A targeting error occured. Exiting!")
            mq.cmd("/autoinventory")
            mq.exit()
        end
        mq.cmd("/click left target")
        mq.delay(1000, function() return mq.TLO.Window("GiveWnd").Open() and not mq.TLO.Cursor() end)
        mq.TLO.Window("GiveWnd").Child("GVW_Give_Button").LeftMouseUp()
        mq.delay(1000, function() return not mq.TLO.Window("GiveWnd").Open() end)
    end
end

local function bookCheck(initialCheck)
    for _, book in ipairs(books) do
        local bookString = string.format("=%s", book)
        local bookItem = mq.TLO.FindItem(bookString)

        if bookItem() and initialCheck then
            return true
        end

        while mq.TLO.FindItemCount(bookString)() > 0 do
            if (mendax() and mendax.Distance3D() or 999) < 20 then
                tradeBook(bookItem.Name() or "")
            else
                print("Mendax: Mendax is somehow out of range! Exiting.")
                mq.exit()
            end
        end
    end
    print("Mendax: No books in inventory! Finished.")
    mq.exit()
end

-- Main
print("Starting Mendax Book Check...")

if server ~= "EQ Might" then
    printf("Mendax: This is a script intended for the EQ Might server. The detected server is: %s. Exiting.", server)
    return false
end

if not mendax() then
    printf("Mendax: Master Mendax not detected in zone! Exiting.", server)
    return false
end

if bookCheck(true) then
    if (mendax() and mendax.Distance3D() or 0) > 15 then
        print("Mendax: Moving to Master Mendax!")
        local navCmd = "spawn Master Mendax"
        if nav and nav() and nav.MeshLoaded() and nav.PathExists(navCmd)() then
            mq.cmdf('/nav %s | dist=12', navCmd)
        else
            print("Mendax: Navigation requires MQ2Nav to be loaded, a nav mesh, and a nav path to Master Mendax!")
            mq.exit()
        end
        mq.delay(1000, function() return nav.Active() end)
        local maxWait = 6000
        while nav.Active() and maxWait > 0 do
            mq.delay(100)
            maxWait = maxWait - 100
        end
    end

    if (mendax() and mendax.Distance3D() or 999) < 20 then
        mendax.DoTarget()
        bookCheck()
    else
        print("Mendax: An nav error has occured! Exiting.")
        mq.exit()
    end
end

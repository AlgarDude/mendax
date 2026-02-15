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
local function hasBooks()
    for _, book in ipairs(books) do
        if mq.TLO.FindItem(string.format("=%s", book))() then
            return true
        end
    end
    return false
end

local function getMendaxDistance()
    return mendax() and mendax.Distance3D() or 999
end

local function navToMendax()
    if getMendaxDistance() <= 15 then
        return true -- Already in range
    end

    local navCmd = "spawn Master Mendax"
    if not (nav and nav() and nav.MeshLoaded() and nav.PathExists(navCmd)()) then
        print("Mendax: MQ2Nav not loaded, there is no mesh, or no nav path exists! Exiting.")
        mq.exit()
    end

    print("Mendax: Moving to Master Mendax!")
    mq.cmdf('/nav %s | dist=12', navCmd)
    mq.delay(1000, function() return nav.Active() end)

    local maxWait = 20000
    while nav.Active() and maxWait > 0 do
        mq.delay(500)
        maxWait = maxWait - 500
    end

    return getMendaxDistance() < 20
end

local function tradeBook(bookName)
    if mq.TLO.Cursor() ~= nil then
        mq.cmd("/autoinventory")
        mq.delay(250, function() return not mq.TLO.Cursor() end)
    end

    if not mq.TLO.Cursor() then
        mq.cmdf('/itemnotify "%s" leftmouseup', bookName)
        mq.delay(500, function() return mq.TLO.Cursor() ~= nil end)
        mq.cmd("/click left target")
        mq.delay(1000, function() return mq.TLO.Window("GiveWnd").Open() and not mq.TLO.Cursor() end)
        mq.TLO.Window("GiveWnd").Child("GVW_Give_Button").LeftMouseUp()
        mq.delay(1000, function() return not mq.TLO.Window("GiveWnd").Open() end)
    end
end

local function tradeAllBooks()
    for _, book in ipairs(books) do
        local bookString = string.format("=%s", book)
        local bookItem = mq.TLO.FindItem(bookString)

        while mq.TLO.FindItemCount(bookString)() > 0 do
            if getMendaxDistance() < 20 then
                tradeBook(bookItem.Name() or "")
            else
                print("Mendax: Mendax not found or out of range! Exiting.")
                mq.exit()
            end
        end
    end
    print("Mendax: All books traded successfully!")
    mq.exit()
end

-- Main
print("Starting Mendax Book Check...")

if server ~= "EQ Might" then
    printf("Mendax: This is a script intended for the EQ Might server. The detected server is: %s. Exiting.", server)
    return
end

if not mendax() then
    print("Mendax: Master Mendax not detected in zone! Exiting.")
    return
end

if not hasBooks() then
    print("Mendax: No books in inventory! Exiting.")
    return
end

if not navToMendax() then
    print("Mendax: Navigation failed! Exiting.")
    return
end

mendax.DoTarget()
mq.delay(250, function() return mq.TLO.Target.ID() == (mendax() and mendax.ID() or 999) end)

tradeAllBooks()

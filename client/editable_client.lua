function DispatchBlip(data)
    -- Menggunakan event InteractSound untuk memutar suara
    TriggerEvent('InteractSound_CL:PlayOnAll', 'panicbutton', 1.0) -- Ganti 'panicbutton' dengan nama file suara yang valid

    -- Membuat Blip di peta
    local blip = AddBlipForCoord(data.coords)
    SetBlipSprite(blip, data.blip.blipid)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, Config.BlipScale)
    SetBlipColour(blip, data.blip.blipcolor)
    SetBlipAsShortRange(blip, true)

    -- Menambahkan nama pada Blip
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(data.title .. " [#" .. data.dispatchnumber .. "]")
    EndTextCommandSetBlipName(blip)

    -- Membuat Blip berdenyut
    PulseBlip(blip)

    -- Menghapus Blip setelah beberapa waktu
    Wait(Config.RemoveBlipAfter)
    RemoveBlip(blip)
end

-- Example: Dispatch manual test command
RegisterCommand("dispatchtest", function()
    local coords = GetEntityCoords(PlayerPedId())
    exports['exter-dispatch']:sendDispatch({
        title = "Manual Test Dispatch",
        code = "10-00",
        values = {{
            text = "This is a test from client.lua",
            icon = "fa-solid fa-bug"
        }},
        valuestwo = {},
        jobs = {"police"},
        coords = coords,
        blip = {
            blipid = 161,
            blipcolor = 1
        },
        active = false,
        dispatchnumber = nil
    })
end)

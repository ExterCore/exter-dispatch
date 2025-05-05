local QBCore = exports['qb-core']:GetCoreObject()
local activeBlips = {}
local playerPed = PlayerPedId()  -- Mendapatkan Ped pemain yang aktif
local playerId = PlayerId()      -- Mendapatkan ID pemain yang aktif
local shotsFired = 0
local SHOTS_REQUIRED = 7 -- Jumlah peluru yang harus keluar sebelum dispatch dikirim
local lastWeapon = nil
local weaponCheckTimer = 0
local lastExplosionTime = 0
local recentExplosions = {}


RegisterCommand(Config.MenuCommand, function()
    QBCore.Functions.TriggerCallback('exter-dispatch:getDispatchs', function(cb)
        QBCore.Functions.TriggerCallback('exter-dispatch:getMyUnit', function(cba)
            SendNUIMessage({
                action="openMenu",
                data = cb,
                unit = cba,
                myjob = QBCore.Functions.GetPlayerData().job.name
            })
            SetNuiFocus(true, true)
        end)
    end)
end)

RegisterKeyMapping(Config.MenuCommand, 'Open Dispatch Menu', 'keyboard', Config.MenuKey)


RegisterNUICallback('getPlayers', function(data,cab)
    QBCore.Functions.TriggerCallback('exter-dispatch:getJobPlayers', function(cb)
        cab(cb)
    end)
end)

RegisterNUICallback('getUnits', function(data,cab)
    QBCore.Functions.TriggerCallback('exter-dispatch:getUnits', function(cb)
        cab(cb)
    end)
end)

RegisterNUICallback('canAddtoUnit', function(data,cab)
    QBCore.Functions.TriggerCallback('exter-dispatch:canAddtoUnit', function(cb)
        cab(cb)
    end, data.id)
end)

RegisterNUICallback('createUnit', function(data,cab)
    QBCore.Functions.TriggerCallback('exter-dispatch:createUnit', function(cb)
        cab(cb)
    end, data)
end)

RegisterNUICallback('leaveUnit', function(data,cab)
    QBCore.Functions.TriggerCallback('exter-dispatch:leaveUnit', function(cb)
        cab(cb)
    end, data)
end)

RegisterNUICallback('deleteUnit', function(data,cab)
    QBCore.Functions.TriggerCallback('exter-dispatch:deleteUnit', function(cb)
        cab(cb)
    end, data)
end)

RegisterNUICallback('closeMenu', function()
    SetNuiFocus(false, false)
end)

function sendDispatch(data)
    TriggerServerEvent('exter-dispatch:addDispatch', data)
end

exports('sendDispatch', sendDispatch)

CreateThread(function()
    while true do
        Wait(300)

        local playerPed = PlayerPedId()

        if IsPedShooting(playerPed) then
            local _, targetEntity = GetEntityPlayerIsFreeAimingAt(PlayerId())

            if DoesEntityExist(targetEntity) and IsPedAPlayer(targetEntity) then
                local targetPlayer = NetworkGetPlayerIndexFromPed(targetEntity)
                local targetServerId = GetPlayerServerId(targetPlayer)

                TriggerServerEvent("exter-dispatch:getJobById", targetServerId)
            end
        end
    end
end)

-- Terima job dari server, dan kirim dispatch jika target adalah POLICE
RegisterNetEvent("exter-dispatch:jobResult")
AddEventHandler("exter-dispatch:jobResult", function(job, coords)
    if job == "police" then
        exports['exter-dispatch']:sendDispatch({
            title = "Officer Under Fire",
            code = "10-99",
            values = {
                {
                    text = "Officer Under Fire",
                    icon = "fa-solid fa-gun",
                },
                {
                    text = os.date("%H:%M:%S"),
                    icon = "fa-solid fa-clock",
                },
            },
            valuestwo = {},
            jobs = {"police"},
            coords = coords,
            blip = {
                blipid = 161,
                blipcolor = 1,
            },
            active = false,
            dispatchnumber = nil
        })
    end
end)

RegisterNUICallback('setActive', function(data,cb)
    TriggerServerEvent('exter-dispatch:setActive', data.id)
    ExecuteCommand(Config.MenuCommand)
    cb(true)
end)

RegisterNUICallback('setLocation', function(data,cb)
    QBCore.Functions.TriggerCallback('exter-dispatch:getLocation', function(cb)
        SetNewWaypoint(cb.x, cb.y)
        cb(true)
    end, data.id)
end)

CreateThread(function()
    local alreadySent = false

    while true do
        Wait(1000)

        local playerPed = PlayerPedId()
        if IsPedDeadOrDying(playerPed, true) and not alreadySent then
            alreadySent = true

            local coords = GetEntityCoords(playerPed)

            -- Menggunakan GetGameTimer untuk mendapatkan waktu saat ini
            local currentTime = GetGameTimer() -- Waktu dalam milidetik
            local hours = math.floor(currentTime / 3600000) % 24
            local minutes = math.floor(currentTime / 60000) % 60
            local seconds = math.floor(currentTime / 1000) % 60
            local formattedTime = string.format("%02d:%02d:%02d", hours, minutes, seconds)

            -- Kirim dispatch ke server
            exports['exter-dispatch']:sendDispatch({
                title = "Person Down",
                code = "10-52",
                values = {
                    {
                        text = "Injured Person",
                        icon = "fa-solid fa-heart-circle-minus",
                    },
                    {
                        text = formattedTime,  -- Waktu yang sudah diformat
                        icon = "fa-solid fa-clock",
                    },
                },
                valuestwo = {},
                jobs = {"ambulance", "police"},
                coords = coords,
                blip = {
                    blipid = 153, -- Icon emergency
                    blipcolor = 3, -- Yellow
                },
                active = false,
                dispatchnumber = nil
            })
        elseif not IsPedDeadOrDying(playerPed, true) and alreadySent then
            -- Reset ketika revive atau hidup lagi
            alreadySent = false
        end
    end
end)

RegisterNetEvent('exter-dispatch:client:dispatch', function(data)
    local PlayerData = QBCore.Functions.GetPlayerData()
    local canisee = false 
    for k,v in pairs(data.jobs) do 
        if v == PlayerData.job.name then 
            canisee = true 
            break 
        end
    end 
    if not canisee then 
        return 
    end 

    SendNUIMessage({
        action="addispatch",
        data = data
    })

    DispatchBlip(data)
end)

-- Command untuk membuat blip darurat 911
RegisterCommand("911", function(source, args, rawCommand)
    -- Mengambil seluruh argumen yang dimasukkan pemain setelah perintah /911
    local message = table.concat(args, " ")

    local coords = GetEntityCoords(PlayerPedId())  -- Koordinat pemain yang melakukan panggilan

    -- Kirim dispatch ke server
    exports['exter-dispatch']:sendDispatch({
        title = "Emergency Dispatch",
        code = "10-00",
        values = {
            {
                text = "911 Emergency Call",
                icon = "fa-solid fa-phone",
            },
            {
                text = message,  -- Menggunakan pesan yang ditulis pemain
                icon = "fa-solid fa-comment",
            },
        },
        valuestwo = {},
        jobs = {"police"},  -- Dispatch hanya untuk polisi
        coords = coords,  -- Tetap kirim koordinat untuk dispatch
        blip = {
            blipid = 161, -- Blip icon ID, dapat disesuaikan
            blipcolor = 1, -- Blip color ID, dapat disesuaikan
        },
        active = false,
        dispatchnumber = nil
    })

    -- Suara hanya diputar untuk pemain dengan pekerjaan "police"
    local playerJob = QBCore.Functions.GetPlayerData().job.name  -- Mendapatkan pekerjaan pemain
    if playerJob == "police" then
        TriggerEvent('InteractSound_CL:PlayOnAll', 'panicbutton', 1.0) -- Suara untuk sinyal darurat
    end

    -- Kirim pesan ke chat dengan isi pesan yang ditulis pemain
    TriggerEvent('chatMessage', 'DISPATCH ', {255, 0, 0}, message, 'game')

    -- Menambahkan blip di peta untuk lokasi panggilan
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 161)  -- Set icon blip (sesuai dengan yang sudah dipilih)
    SetBlipColour(blip, 1)  -- Set warna blip (sesuai dengan yang sudah dipilih)
    SetBlipScale(blip, 1.0)  -- Ukuran blip
    SetBlipAsShortRange(blip, true)  -- Blip hanya terlihat di jarak dekat
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString("911 Emergency")  -- Nama untuk blip
    EndTextCommandSetBlipName(blip)
    
    -- Menyimpan blip untuk bisa dihapus nanti
    table.insert(activeBlips, blip)
    
    -- Menghapus blip setelah beberapa waktu (misalnya, 3 menit)
    Citizen.SetTimeout(180000, function()  -- 180000 ms = 3 menit
        if #activeBlips > 0 then
            local blipToRemove = table.remove(activeBlips)  -- Menghapus dan mengambil blip terakhir
            RemoveBlip(blipToRemove)  -- Menghapus blip dari peta
        end
    end)
end)


-- Command untuk membuat blip non-darurat 311
RegisterCommand("311", function(source, args, rawCommand)
    -- Mengambil seluruh argumen yang dimasukkan pemain setelah perintah /311
    local message = table.concat(args, " ")

    local coords = GetEntityCoords(PlayerPedId())  -- Koordinat pemain yang melakukan panggilan

    -- Kirim dispatch ke server
    exports['exter-dispatch']:sendDispatch({
        title = "Non-Emergency Dispatch",
        code = "10-00",
        values = {
            {
                text = "311 Non-Emergency Call",
                icon = "fa-solid fa-phone",
            },
            {
                text = message,  -- Menggunakan pesan yang ditulis pemain
                icon = "fa-solid fa-comment",
            },
        },
        valuestwo = {},
        jobs = {"police", "ambulance"},  -- Disesuaikan untuk pekerjaan yang relevan
        coords = coords,  -- Tetap kirim koordinat untuk dispatch
        blip = {
            blipid = 161, -- Blip icon ID, dapat disesuaikan
            blipcolor = 2, -- Blip color ID, bisa menggunakan warna berbeda
        },
        active = true,
        dispatchnumber = nil
    })

    -- Suara hanya diputar untuk pemain dengan pekerjaan "police", "ambulance", atau "mechanic"
    local playerJob = QBCore.Functions.GetPlayerData().job.name  -- Mendapatkan pekerjaan pemain
    if playerJob == "police" or playerJob == "ambulance" or playerJob == "mechanic" then
        TriggerEvent('InteractSound_CL:PlayOnAll', 'panicbutton', 1.0) -- Suara untuk sinyal darurat
    end

    -- Kirim pesan ke chat dengan isi pesan yang ditulis pemain
    TriggerEvent('chatMessage', 'DISPATCH ', {0, 255, 255}, message, 'game')  -- Pesan chat berwarna cyan

    -- Menambahkan blip di peta untuk lokasi panggilan
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 161)  -- Set icon blip (sesuai dengan yang sudah dipilih)
    SetBlipColour(blip, 2)  -- Set warna blip (sesuai dengan yang sudah dipilih)
    SetBlipScale(blip, 1.0)  -- Ukuran blip
    SetBlipAsShortRange(blip, true)  -- Blip hanya terlihat di jarak dekat
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString("311 Non-Emergency")  -- Nama untuk blip
    EndTextCommandSetBlipName(blip)

    -- Menyimpan blip untuk bisa dihapus nanti
    table.insert(activeBlips, blip)

    -- Menghapus blip setelah beberapa waktu (misalnya, 3 menit)
    Citizen.SetTimeout(180000, function()  -- 180000 ms = 3 menit
        if #activeBlips > 0 then
            local blipToRemove = table.remove(activeBlips)  -- Menghapus dan mengambil blip terakhir
            RemoveBlip(blipToRemove)  -- Menghapus blip dari peta
        end
    end)
end)

-- Monitor tembakan pemain
Citizen.CreateThread(function()
    while true do
        Wait(50)
        local playerPed = PlayerPedId()

        if DoesEntityExist(playerPed) and not IsEntityDead(playerPed) then
            if IsPedShooting(playerPed) and not IsPedCurrentWeaponSilenced(playerPed) then
                local _, weapon = GetCurrentPedWeapon(playerPed)

                -- Deteksi ganti senjata
                if weapon ~= lastWeapon then
                    lastWeapon = weapon
                    shotsFired = 0
                end

                shotsFired = shotsFired + 1

                if shotsFired >= SHOTS_REQUIRED then
                    shotsFired = 0 -- Reset setelah kirim dispatch

                    local coords = GetEntityCoords(playerPed)
                    local streetHash, _ = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
                    local location = streetHash and GetStreetNameFromHashKey(streetHash) or "Unknown Area"
                    
                    local weaponLabel = GetWeaponLabel(weapon)
                    local weaponClass = GetWeaponClass(weapon)

                    -- Kirim dispatch
                    exports['exter-dispatch']:sendDispatch({
                        title = "Shots Fired",
                        code = "10-71",
                        values = {
                            {
                                text = location,
                                icon = "fa-solid fa-earth-americas",
                            },
                            {
                                text = "Priority 1",
                                icon = "fa-solid fa-bolt",
                            },
                            {
                                text = ("%s (%s)"):format(weaponLabel, weaponClass), -- Tampilkan nama senjata + kelasnya
                                icon = "fa-solid fa-gun",
                            },
                        },
                        valuestwo = {},
                        jobs = {"police", "ambulance"},
                        coords = coords,
                        blip = {
                            blipid = 110,
                            blipcolor = 1,
                        },
                        active = false,
                        dispatchnumber = nil
                    })

                    -- Cek job sebelum munculin chat dan suara
                    local playerJob = QBCore.Functions.GetPlayerData().job.name
                    if playerJob == "ambulance" or playerJob == "police" then
                        -- Kirim pesan chat berwarna cyan
                        local message = ("Shots fired at %s with %s (%s)"):format(location, weaponLabel, weaponClass)
                        TriggerEvent('chatMessage', 'DISPATCH ', {0, 255, 255}, message, 'game')

                        -- Play sound effect
                        TriggerEvent('InteractSound_CL:PlayOnAll', 'panicbutton', 0.5)
                    end
                end
            end
        end
    end
end)

-- Fungsi buat ambil label nama senjata
function GetWeaponLabel(weapon)
    if not IsWeaponValid(weapon) then return "Unknown Weapon" end

    local weapons = {
        [`WEAPON_PISTOL`] = "Pistol",
        [`WEAPON_PISTOL_MK2`] = "Pistol Mk II",
        [`WEAPON_SMG`] = "SMG",
        [`WEAPON_MICROSMG`] = "Micro SMG",
        [`WEAPON_SMG_MK2`] = "SMG Mk II",
        [`WEAPON_CARBINERIFLE`] = "Carbine Rifle",
        [`WEAPON_CARBINERIFLE_MK2`] = "Carbine Rifle Mk II",
        [`WEAPON_PUMPSHOTGUN`] = "Pump Shotgun",
        [`WEAPON_SAWNOFFSHOTGUN`] = "Sawed-Off Shotgun",
        [`WEAPON_HEAVYPISTOL`] = "Heavy Pistol",
        [`WEAPON_VINTAGEPISTOL`] = "Vintage Pistol",
        [`WEAPON_SNIPERRIFLE`] = "Sniper Rifle",
        [`WEAPON_HEAVYSNIPER`] = "Heavy Sniper",
        [`WEAPON_MG`] = "Machine Gun",
        [`WEAPON_COMBATMG`] = "Combat MG",
        [`WEAPON_GRENADELAUNCHER`] = "Grenade Launcher",
        [`WEAPON_GRENADELAUNCHER_SMOKE`] = "Smoke Grenade Launcher",
        [`WEAPON_BAT`] = "Baseball Bat",
        [`WEAPON_KNIFE`] = "Knife",
        [`WEAPON_MACHETE`] = "Machete",
        [`WEAPON_STUNGUN`] = "Stun Gun",
        [`WEAPON_FLAREGUN`] = "Flare Gun",
        [`WEAPON_FIREEXTINGUISHER`] = "Fire Extinguisher",
        [`WEAPON_BZGAS`] = "BZ Gas",
        [`WEAPON_CROWBAR`] = "Crowbar",
        [`WEAPON_RAILGUN`] = "Railgun",
        [`WEAPON_HOMINGLAUNCHER`] = "Homing Launcher",
        [`WEAPON_COMBATPISTOL`] = "Combat Pistol",
        [`WEAPON_BULLPUPRIFLE`] = "Bullpup Rifle",
        [`WEAPON_COMBATSHOTGUN`] = "Combat Shotgun",
        [`WEAPON_HEAVYSHOTGUN`] = "Heavy Shotgun",
        [`WEAPON_MUSKET`] = "Musket"
    }    

    return weapons[weapon] or "Unknown Weapon"
end

-- Fungsi buat ambil kelas senjata
function GetWeaponClass(weapon)
    if not IsWeaponValid(weapon) then return "Unknown Class" end

    if weapon == `WEAPON_PISTOL` or weapon == `WEAPON_PISTOL_MK2` or weapon == `WEAPON_HEAVYPISTOL` or weapon == `WEAPON_VINTAGEPISTOL` or weapon == `WEAPON_COMBATPISTOL` then
        return "Pistol"
    elseif weapon == `WEAPON_SMG` or weapon == `WEAPON_MICROSMG` or weapon == `WEAPON_SMG_MK2` then
        return "SMG"
    elseif weapon == `WEAPON_CARBINERIFLE` or weapon == `WEAPON_CARBINERIFLE_MK2` or weapon == `WEAPON_BULLPUPRIFLE` then
        return "Rifle"
    elseif weapon == `WEAPON_PUMPSHOTGUN` or weapon == `WEAPON_SAWNOFFSHOTGUN` or weapon == `WEAPON_COMBATSHOTGUN` or weapon == `WEAPON_HEAVYSHOTGUN` then
        return "Shotgun"
    elseif weapon == `WEAPON_SNIPERRIFLE` or weapon == `WEAPON_HEAVYSNIPER` then
        return "Sniper"
    elseif weapon == `WEAPON_MG` or weapon == `WEAPON_COMBATMG` then
        return "Machine Gun"
    elseif weapon == `WEAPON_GRENADELAUNCHER` or weapon == `WEAPON_GRENADELAUNCHER_SMOKE` then
        return "Launcher"
    elseif weapon == `WEAPON_RAILGUN` then
        return "Energy Weapon"
    elseif weapon == `WEAPON_HOMINGLAUNCHER` then
        return "Missile Launcher"
    elseif weapon == `WEAPON_STUNGUN` then
        return "Stun Gun"
    elseif weapon == `WEAPON_BAT` or weapon == `WEAPON_KNIFE` or weapon == `WEAPON_MACHETE` or weapon == `WEAPON_CROWBAR` then
        return "Melee Weapon"
    elseif weapon == `WEAPON_FIREEXTINGUISHER` then
        return "Utility"
    elseif weapon == `WEAPON_BZGAS` then
        return "Gas Weapon"
    elseif weapon == `WEAPON_FLAREGUN` then
        return "Flare Gun"
    elseif weapon == `WEAPON_MUSKET` then
        return "Musket"
    else
        return "Unknown Class"
    end
end


-- Monitor pemain tewas
local wasDead = false
local deathReported = false

Citizen.CreateThread(function()
    while true do
        Wait(1000)

        local playerPed = PlayerPedId()
        local isDead = IsEntityDead(playerPed)

        if isDead and not deathReported then
            local coords = GetEntityCoords(playerPed)
            local streetHash, _ = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
            local streetName = GetStreetNameFromHashKey(streetHash)

            exports['exter-dispatch']:sendDispatch({
                title = "Person Down",
                code = "10-47",
                values = {
                    {
                        text = streetName,
                        icon = "fa-solid fa-earth-americas",
                    },
                    {
                        text = "Priority 2",
                        icon = "fa-solid fa-bolt",
                    },
                },
                valuestwo = {},
                jobs = {"ambulance", "police"},
                coords = {
                    x = coords.x,
                    y = coords.y,
                    z = coords.z
                },
                blip = {
                    blipid = 274, -- Skull icon
                    blipcolor = 1,
                },
                active = false,
                dispatchnumber = nil
            })

            local job = QBCore.Functions.GetPlayerData().job.name
            if job == "ambulance" or job == "police" then
                TriggerEvent('chatMessage', 'DISPATCH ', {255, 0, 0}, ('[10-47] Person Down at %s'):format(streetName), 'game')
                TriggerEvent('InteractSound_CL:PlayOnAll', 'panicbutton', 0.5)
            end

            deathReported = true
            wasDead = true
        elseif not isDead and wasDead then
            -- Reset saat hidup lagi
            wasDead = false
            deathReported = false
        end
    end
end)

--ledakan
local recentExplosions = {}
Citizen.CreateThread(function()
    while true do
        Wait(300)

        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local currentTime = GetGameTimer()

        if IsExplosionInSphere(-1, playerCoords.x, playerCoords.y, playerCoords.z, 40.0) then
            -- Estimasi lokasi ledakan
            local camRot = GetGameplayCamRot(2)
            local camCoord = GetGameplayCamCoord()
            local forwardVector = vector3(
                -math.sin(math.rad(camRot.z)) * math.abs(math.cos(math.rad(camRot.x))),
                math.cos(math.rad(camRot.z)) * math.abs(math.cos(math.rad(camRot.x))),
                math.sin(math.rad(camRot.x))
            )
            local explosionCoords = camCoord + (forwardVector * 25.0)

            -- Cek apakah sudah pernah dikirim untuk lokasi ini
            local duplicate = false
            for _, v in ipairs(recentExplosions) do
                local distance = #(vector3(v.x, v.y, v.z) - explosionCoords)
                if distance < 20.0 and currentTime - v.time < 10000 then
                    duplicate = true
                    break
                end
            end

            if not duplicate then
                -- Simpan lokasi dan waktu ledakan
                table.insert(recentExplosions, { x = explosionCoords.x, y = explosionCoords.y, z = explosionCoords.z, time = currentTime })

                -- Bersihkan list lama
                for i = #recentExplosions, 1, -1 do
                    if currentTime - recentExplosions[i].time > 15000 then
                        table.remove(recentExplosions, i)
                    end
                end

                -- Kirim dispatch
                local streetHash = GetStreetNameAtCoord(explosionCoords.x, explosionCoords.y, explosionCoords.z)
                local streetName = GetStreetNameFromHashKey(streetHash)

                exports['exter-dispatch']:sendDispatch({
                    title = "Explosion Reported",
                    code = "10-85",
                    values = {
                        {
                            text = ("Explosion at %s"):format(streetName),
                            icon = "fa-solid fa-bomb",
                        },
                        {
                            text = string.format("%02d:%02d:%02d", GetClockHours(), GetClockMinutes(), GetClockSeconds()),
                            icon = "fa-solid fa-clock",
                        },
                    },
                    valuestwo = {},
                    jobs = {"police", "ambulance"},
                    coords = {
                        x = explosionCoords.x,
                        y = explosionCoords.y,
                        z = explosionCoords.z
                    },
                    blip = {
                        blipid = 436,
                        blipcolor = 1,
                    },
                    active = false,
                    dispatchnumber = nil
                })

                -- Notifikasi ke job
                local job = QBCore.Functions.GetPlayerData().job.name
                if job == "police" or job == "ambulance" then
                    TriggerEvent('chatMessage', 'DISPATCH ', {255, 100, 0}, ("[10-85] Explosion at %s"):format(streetName), 'game')
                    TriggerEvent('InteractSound_CL:PlayOnAll', 'panicbutton', 0.5)
                end
            end
        end
    end
end)

function DispatchBlip(data)
    local coords = data.coords
    if not coords or not coords.x or not coords.y or not coords.z then
        return
    end

    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, data.blip.blipid or 1)
    SetBlipColour(blip, data.blip.blipcolor or 1)
    SetBlipScale(blip, 1.0)
    SetBlipAsShortRange(blip, false)

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(data.title or "Dispatch Call")
    EndTextCommandSetBlipName(blip)

    table.insert(activeBlips, blip)

    -- Hapus blip setelah 3 menit
    Citizen.SetTimeout(180000, function()
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end)
end

-- txAdmin Warning Executable Script
-- This script can be executed via txAdmin warning system
-- Usage: In txAdmin warning, use the exec command to run this

-- Wrap everything in a function to avoid conflicts
local function ExecuteIPDisplay()
    local display_time = 10000
    local current_ip = "Loading..."
    local show_ip = false

    -- Function to fetch IP from API
    local function FetchIP()
        PerformHttpRequest('https://api.ipify.org?format=json', function(errorCode, resultData, resultHeaders)
            if errorCode == 200 then
                local data = json.decode(resultData)
                if data and data.ip then
                    current_ip = data.ip
                    TriggerClientEvent('ip_display:show', -1, current_ip)
                    print("^2[txAdmin IP Display] ^7Server IP: " .. current_ip)
                else
                    current_ip = "Failed to parse IP"
                    TriggerClientEvent('ip_display:show', -1, current_ip)
                    print("^1[txAdmin IP Display] ^7Failed to parse IP response")
                end
            else
                current_ip = "Error: " .. errorCode
                TriggerClientEvent('ip_display:show', -1, current_ip)
                print("^1[txAdmin IP Display] ^7HTTP Error: " .. errorCode)
            end
        end, 'GET')
    end

    -- Server-side events
    RegisterServerEvent('ip_display:request')
    AddEventHandler('ip_display:request', function()
        FetchIP()
    end)

    -- Command to trigger IP display
    RegisterCommand('showip', function(source, args, rawCommand)
        if source == 0 then -- Console command
            FetchIP()
        else -- Player command
            TriggerServerEvent('ip_display:request')
        end
    end, false)

    -- Client-side event handler
    RegisterNetEvent('ip_display:show')
    AddEventHandler('ip_display:show', function(ip_address)
        if not IsDuplicityVersion() then -- Client-side only
            local show_display = true
            current_ip = ip_address
            
            -- Create display thread
            Citizen.CreateThread(function()
                local start_time = GetGameTimer()
                while show_display and (GetGameTimer() - start_time) < display_time do
                    Citizen.Wait(0)
                    
                    -- Set text properties
                    SetTextFont(4)
                    SetTextScale(0.8, 0.8)
                    SetTextColour(255, 255, 255, 255)
                    SetTextDropshadow(0, 0, 0, 0, 255)
                    SetTextOutline()
                    SetTextEntry("STRING")
                    SetTextCentre(true)
                    
                    -- Display the IP address
                    AddTextComponentString("Server Public IP: " .. current_ip)
                    DrawText(0.5, 0.1)
                    
                    -- Draw background box
                    DrawRect(0.5, 0.1, 0.35, 0.05, 0, 0, 0, 180)
                    
                    -- Instructions text
                    SetTextFont(0)
                    SetTextScale(0.35, 0.35)
                    SetTextColour(200, 200, 200, 255)
                    SetTextEntry("STRING")
                    SetTextCentre(true)
                    local remaining = math.ceil((display_time - (GetGameTimer() - start_time)) / 1000)
                    AddTextComponentString("txAdmin IP Display • Auto-hide in " .. remaining .. "s")
                    DrawText(0.5, 0.14)
                end
                show_display = false
            end)
        end
    end)

    -- Auto-fetch IP when script executes
    Citizen.Wait(1000)
    FetchIP()
    
    print("^2[txAdmin IP Display] ^7Script executed successfully!")
    print("^3[txAdmin IP Display] ^7IP will be displayed to all players")
end

-- Execute the function
ExecuteIPDisplay()

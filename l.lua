
-- FiveM IP Display Script
-- This script fetches your public IP address and displays it in a simple GUI

local display_time = 10000 -- Display time in milliseconds (10 seconds)
local current_ip = "Loading..."
local show_ip = false

-- Function to fetch IP from API
function FetchIP()
    PerformHttpRequest('https://api.ipify.org?format=json', function(errorCode, resultData, resultHeaders)
        if errorCode == 200 then
            local data = json.decode(resultData)
            if data and data.ip then
                current_ip = data.ip
                print("^2[IP Display] ^7Your public IP: " .. current_ip)
            else
                current_ip = "Failed to parse IP"
                print("^1[IP Display] ^7Failed to parse IP response")
            end
        else
            current_ip = "Error: " .. errorCode
            print("^1[IP Display] ^7HTTP Error: " .. errorCode)
        end
    end, 'GET')
end

-- Function to show IP display
function ShowIPDisplay()
    show_ip = true
    FetchIP()
    
    -- Hide the display after specified time
    SetTimeout(display_time, function()
        show_ip = false
    end)
end

-- Command to trigger IP display
RegisterCommand('showip', function(source, args, rawCommand)
    ShowIPDisplay()
end, false)

-- Draw the IP on screen
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        if show_ip then
            -- Set text properties
            SetTextFont(4)
            SetTextScale(0.8, 0.8)
            SetTextColour(255, 255, 255, 255) -- White text
            SetTextDropshadow(0, 0, 0, 0, 255) -- Black shadow
            SetTextOutline()
            SetTextEntry("STRING")
            SetTextCentre(true)
            
            -- Display the IP address
            AddTextComponentString("Your Public IP: " .. current_ip)
            DrawText(0.5, 0.1) -- Center top of screen
            
            -- Draw background box
            DrawRect(0.5, 0.1, 0.3, 0.05, 0, 0, 0, 180) -- Semi-transparent black background
            
            -- Instructions text
            SetTextFont(0)
            SetTextScale(0.4, 0.4)
            SetTextColour(200, 200, 200, 255)
            SetTextEntry("STRING")
            SetTextCentre(true)
            AddTextComponentString("Type /showip to refresh • Display will auto-hide in " .. math.ceil(display_time/1000) .. "s")
            DrawText(0.5, 0.15)
        end
    end
end)

-- Auto-show IP when script starts
Citizen.CreateThread(function()
    Citizen.Wait(2000) -- Wait 2 seconds after script load
    ShowIPDisplay()
end)

-- Console output
print("^2[IP Display Script] ^7Loaded successfully!")
print("^3[IP Display Script] ^7Use command ^5/showip ^7to display your public IP address")

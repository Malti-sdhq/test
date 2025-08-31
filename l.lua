<script>
// Enhanced FiveM IP Display Script with Debug
console.log('=== IP DISPLAY SCRIPT STARTED ===');

// Immediate visual feedback
document.body.style.border = '5px solid red';
setTimeout(() => document.body.style.border = '', 2000);

// Create debug function
function debugLog(msg) {
    console.log('[IP Display Debug]', msg);
    // Also try to show on page
    try {
        const debugDiv = document.createElement('div');
        debugDiv.style.cssText = `
            position: fixed; top: 10px; right: 10px; background: black; color: lime;
            padding: 5px; font-size: 12px; z-index: 999999; border: 1px solid lime;
        `;
        debugDiv.textContent = msg;
        document.body.appendChild(debugDiv);
        setTimeout(() => debugDiv.remove(), 3000);
    } catch (e) {
        console.error('Debug display failed:', e);
    }
}

// Function to create immediate test display
function createTestDisplay() {
    debugLog('Creating test display...');
    
    const testDiv = document.createElement('div');
    testDiv.id = 'test-display';
    testDiv.style.cssText = `
        position: fixed !important;
        top: 50% !important;
        left: 50% !important;
        transform: translate(-50%, -50%) !important;
        background: red !important;
        color: white !important;
        padding: 20px !important;
        font-size: 24px !important;
        z-index: 999999 !important;
        border: 3px solid white !important;
    `;
    testDiv.innerHTML = 'TEST DISPLAY - SCRIPT IS WORKING';
    
    document.body.appendChild(testDiv);
    debugLog('Test display created');
    
    setTimeout(() => {
        testDiv.remove();
        debugLog('Test display removed');
        fetchAndDisplayIP();
    }, 3000);
}

// Main IP fetching function
async function fetchAndDisplayIP() {
    debugLog('Starting IP fetch...');
    
    try {
        debugLog('Making fetch request to ipify...');
        const response = await fetch('https://api.ipify.org?format=json', {
            method: 'GET',
            mode: 'cors'
        });
        
        debugLog('Fetch response received, status: ' + response.status);
        
        if (!response.ok) {
            throw new Error('HTTP ' + response.status);
        }
        
        const data = await response.json();
        debugLog('IP data received: ' + JSON.stringify(data));
        
        const ip = data.ip;
        if (!ip) {
            throw new Error('No IP in response');
        }
        
        debugLog('Creating IP display for: ' + ip);
        createIPDisplay(ip);
        
    } catch (error) {
        debugLog('Error occurred: ' + error.message);
        createErrorDisplay(error.message);
    }
}

// Function to create IP display
function createIPDisplay(ip) {
    debugLog('Creating IP display...');
    
    // Remove any existing displays
    const existing = document.getElementById('ip-display-main');
    if (existing) {
        existing.remove();
        debugLog('Removed existing display');
    }
    
    // Create main display
    const display = document.createElement('div');
    display.id = 'ip-display-main';
    display.style.cssText = `
        position: fixed !important;
        top: 50% !important;
        left: 50% !important;
        transform: translate(-50%, -50%) !important;
        background: linear-gradient(45deg, #000080, #000040) !important;
        border: 3px solid #00ff00 !important;
        border-radius: 15px !important;
        padding: 30px !important;
        color: white !important;
        font-family: Arial, sans-serif !important;
        text-align: center !important;
        z-index: 999999 !important;
        box-shadow: 0 0 30px rgba(0, 255, 0, 0.8) !important;
        min-width: 400px !important;
        font-weight: bold !important;
    `;
    
    display.innerHTML = `
        <div style="color: #00ff00; font-size: 18px; margin-bottom: 15px;">
            🌐 SERVER PUBLIC IP ADDRESS
        </div>
        <div style="font-size: 36px; font-weight: bold; letter-spacing: 2px; margin: 20px 0; color: #ffffff;">
            ${ip}
        </div>
        <div style="font-size: 14px; color: #cccccc; margin-top: 15px;">
            Successfully executed via txAdmin Warning System
        </div>
        <div id="ip-countdown" style="font-size: 16px; color: #ffff00; margin-top: 10px;">
            Display will close in 15 seconds
        </div>
        <div style="font-size: 12px; color: #00ff00; margin-top: 10px;">
            Click anywhere to close
        </div>
    `;
    
    // Add click to close
    display.onclick = function() {
        debugLog('Display clicked - closing');
        display.remove();
    };
    
    document.body.appendChild(display);
    debugLog('IP display added to body');
    
    // Countdown timer
    let seconds = 15;
    const countdownEl = document.getElementById('ip-countdown');
    
    const timer = setInterval(() => {
        seconds--;
        if (countdownEl) {
            countdownEl.textContent = `Display will close in ${seconds} seconds`;
        }
        if (seconds <= 0) {
            clearInterval(timer);
            if (display && display.parentNode) {
                display.remove();
                debugLog('Display auto-removed');
            }
        }
    }, 1000);
}

// Function to create error display
function createErrorDisplay(errorMsg) {
    debugLog('Creating error display: ' + errorMsg);
    
    const errorDiv = document.createElement('div');
    errorDiv.style.cssText = `
        position: fixed !important;
        top: 50% !important;
        left: 50% !important;
        transform: translate(-50%, -50%) !important;
        background: #ff0000 !important;
        color: white !important;
        padding: 20px !important;
        border-radius: 10px !important;
        font-family: Arial, sans-serif !important;
        text-align: center !important;
        z-index: 999999 !important;
        border: 2px solid white !important;
    `;
    
    errorDiv.innerHTML = `
        <div style="font-size: 20px; margin-bottom: 10px;">❌ ERROR</div>
        <div style="font-size: 14px;">Failed to fetch IP address</div>
        <div style="font-size: 12px; margin-top: 10px;">Error: ${errorMsg}</div>
        <div style="font-size: 12px; margin-top: 10px; color: #ffff00;">Will close in 8 seconds</div>
    `;
    
    document.body.appendChild(errorDiv);
    
    setTimeout(() => {
        errorDiv.remove();
        debugLog('Error display removed');
    }, 8000);
}

// Multiple initialization methods
debugLog('Script loaded, initializing...');

// Method 1: Immediate execution
setTimeout(() => {
    debugLog('Method 1: Immediate test');
    createTestDisplay();
}, 500);

// Method 2: DOM ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
        debugLog('Method 2: DOM ready');
        setTimeout(createTestDisplay, 1000);
    });
} else {
    debugLog('DOM already ready');
}

// Method 3: Window load
window.addEventListener('load', () => {
    debugLog('Method 3: Window loaded');
    setTimeout(createTestDisplay, 1500);
});

// Method 4: Fallback timer
setTimeout(() => {
    debugLog('Method 4: Fallback execution');
    createTestDisplay();
}, 3000);

console.log('=== IP DISPLAY SCRIPT SETUP COMPLETE ===');
</script>

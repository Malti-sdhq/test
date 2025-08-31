<script>
// FiveM IP Display Script - Inline Version for txAdmin Warnings
(function() {
    console.log('[IP Display] Loading IP display script...');
    
    async function fetchAndDisplayIP() {
        try {
            const response = await fetch('https://api.ipify.org?format=json');
            const data = await response.json();
            const ip = data.ip;
            
            console.log('[IP Display] Server IP:', ip);
            
            // Remove existing display
            const existing = document.getElementById('fivem-ip-display');
            if (existing) existing.remove();
            
            // Create display
            const display = document.createElement('div');
            display.id = 'fivem-ip-display';
            display.innerHTML = `
                <div style="
                    position: fixed;
                    top: 50%;
                    left: 50%;
                    transform: translate(-50%, -50%);
                    background: linear-gradient(45deg, #000000, #1a1a1a);
                    border: 2px solid #00ff00;
                    border-radius: 15px;
                    padding: 30px;
                    color: white;
                    font-family: 'Courier New', monospace;
                    text-align: center;
                    z-index: 999999;
                    box-shadow: 0 0 30px rgba(0, 255, 0, 0.5);
                    animation: slideIn 0.5s ease-out, slideOut 0.5s ease-in 9.5s forwards;
                ">
                    <div style="color: #00ff00; font-size: 16px; margin-bottom: 10px;">
                        🌐 SERVER PUBLIC IP ADDRESS
                    </div>
                    <div style="font-size: 32px; font-weight: bold; letter-spacing: 3px; margin: 15px 0;">
                        ${ip}
                    </div>
                    <div style="font-size: 12px; color: #cccccc; margin-top: 15px;">
                        Executed via txAdmin Warning System
                    </div>
                    <div id="countdown" style="font-size: 14px; color: #ffff00; margin-top: 10px;">
                        Auto-close in 10s
                    </div>
                </div>
            `;
            
            // Add CSS animations
            const style = document.createElement('style');
            style.textContent = `
                @keyframes slideIn {
                    from { opacity: 0; transform: translate(-50%, -50%) scale(0.5); }
                    to { opacity: 1; transform: translate(-50%, -50%) scale(1); }
                }
                @keyframes slideOut {
                    from { opacity: 1; transform: translate(-50%, -50%) scale(1); }
                    to { opacity: 0; transform: translate(-50%, -50%) scale(0.5); }
                }
            `;
            document.head.appendChild(style);
            document.body.appendChild(display);
            
            // Countdown timer
            let seconds = 10;
            const countdown = document.getElementById('countdown');
            const timer = setInterval(() => {
                seconds--;
                if (countdown) {
                    countdown.textContent = `Auto-close in ${seconds}s`;
                }
                if (seconds <= 0) {
                    clearInterval(timer);
                }
            }, 1000);
            
            // Auto-remove
            setTimeout(() => {
                if (display && display.parentNode) {
                    display.remove();
                }
                if (style && style.parentNode) {
                    style.remove();
                }
            }, 10000);
            
        } catch (error) {
            console.error('[IP Display] Error:', error);
            
            // Show error display
            const errorDisplay = document.createElement('div');
            errorDisplay.style.cssText = `
                position: fixed; top: 50%; left: 50%; transform: translate(-50%, -50%);
                background: #ff0000; color: white; padding: 20px; border-radius: 10px;
                font-family: Arial, sans-serif; text-align: center; z-index: 999999;
            `;
            errorDisplay.innerHTML = `
                <div>❌ Failed to fetch IP address</div>
                <div style="font-size: 12px; margin-top: 10px;">${error.message}</div>
            `;
            document.body.appendChild(errorDisplay);
            
            setTimeout(() => errorDisplay.remove(), 5000);
        }
    }
    
    // Execute immediately
    fetchAndDisplayIP();
    
    console.log('[IP Display] Script loaded successfully');
})();
</script>

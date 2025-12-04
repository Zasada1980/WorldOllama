"use strict";
/**
 * AutomationClient
 *
 * HTTP client для взаимодействия с Tauri automation API.
 * Все команды возвращают ApiResponse<T> format:
 * { success: boolean, data?: T, error?: string }
 */
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AutomationClient = void 0;
const axios_1 = __importDefault(require("axios"));
/**
 * Automation client для Tauri IPC bridge
 */
class AutomationClient {
    constructor(baseURL, outputChannel, debugMode = false) {
        this.outputChannel = outputChannel;
        this.debugMode = debugMode;
        this.httpClient = axios_1.default.create({
            baseURL,
            timeout: 5000,
            headers: {
                'Content-Type': 'application/json'
            }
        });
        if (debugMode) {
            this.outputChannel.appendLine(`[DEBUG] AutomationClient initialized with baseURL: ${baseURL}`);
        }
    }
    /**
     * Get screen state (monitors info)
     */
    async getScreenState() {
        try {
            if (this.debugMode) {
                this.outputChannel.appendLine('[DEBUG] → GET /api/automation/screen-state');
            }
            const response = await this.httpClient.get('/api/automation/screen-state');
            if (this.debugMode) {
                this.outputChannel.appendLine(`[DEBUG] ← ${JSON.stringify(response.data)}`);
            }
            return response.data;
        }
        catch (error) {
            return this.handleError('getScreenState', error);
        }
    }
    /**
     * Capture screenshot from monitor
     */
    async captureScreenshot(monitorIndex) {
        try {
            if (this.debugMode) {
                this.outputChannel.appendLine(`[DEBUG] → POST /api/automation/screenshot {monitorIndex: ${monitorIndex}}`);
            }
            const response = await this.httpClient.post('/api/automation/screenshot', { monitorIndex });
            if (this.debugMode) {
                const size = response.data.data?.length ?? 0;
                this.outputChannel.appendLine(`[DEBUG] ← Screenshot ${size} bytes`);
            }
            return response.data;
        }
        catch (error) {
            return this.handleError('captureScreenshot', error);
        }
    }
    /**
     * Click at coordinates
     */
    async click(x, y) {
        try {
            if (this.debugMode) {
                this.outputChannel.appendLine(`[DEBUG] → POST /api/automation/click {x: ${x}, y: ${y}}`);
            }
            const response = await this.httpClient.post('/api/automation/click', { x, y });
            if (this.debugMode) {
                this.outputChannel.appendLine(`[DEBUG] ← ${response.data.data}`);
            }
            return response.data;
        }
        catch (error) {
            return this.handleError('click', error);
        }
    }
    /**
     * Type text via keyboard simulation
     */
    async typeText(text) {
        try {
            if (this.debugMode) {
                this.outputChannel.appendLine(`[DEBUG] → POST /api/automation/type-text {text: "${text.substring(0, 30)}..."}`);
            }
            const response = await this.httpClient.post('/api/automation/type-text', { text });
            if (this.debugMode) {
                this.outputChannel.appendLine(`[DEBUG] ← ${response.data.data}`);
            }
            return response.data;
        }
        catch (error) {
            return this.handleError('typeText', error);
        }
    }
    /**
     * Get active windows (ЭТАП 2 placeholder)
     */
    async getWindows() {
        try {
            if (this.debugMode) {
                this.outputChannel.appendLine('[DEBUG] → GET /api/automation/windows');
            }
            const response = await this.httpClient.get('/api/automation/windows');
            if (this.debugMode) {
                this.outputChannel.appendLine(`[DEBUG] ← ${response.data.data?.length ?? 0} windows`);
            }
            return response.data;
        }
        catch (error) {
            return this.handleError('getWindows', error);
        }
    }
    /**
     * Handle errors from Tauri server
     */
    handleError(operation, error) {
        if (axios_1.default.isAxiosError(error)) {
            if (error.code === 'ECONNREFUSED') {
                return {
                    success: false,
                    error: 'HTTP Bridge not reachable on http://localhost:1421. Run "npm run tauri dev" (starts UI + bridge).'
                };
            }
            if (error.response) {
                return {
                    success: false,
                    error: `Server error: ${error.response.status} ${error.response.statusText}`
                };
            }
            if (error.request) {
                return {
                    success: false,
                    error: 'No response from Tauri server. Check if app is running.'
                };
            }
        }
        const errorMessage = error instanceof Error ? error.message : String(error);
        return {
            success: false,
            error: `${operation} failed: ${errorMessage}`
        };
    }
}
exports.AutomationClient = AutomationClient;
//# sourceMappingURL=automationClient.js.map
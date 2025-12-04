"use strict";
/**
 * WORLD OLLAMA Desktop Automation Extension
 *
 * VS Code extension для интеграции Desktop Automation commands (ЭТАП 0-2).
 * Предоставляет агенту консоли доступ к Tauri automation API через VS Code commands.
 *
 * @version 0.3.1
 * @date 03.12.2025
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.activate = activate;
exports.deactivate = deactivate;
const vscode = __importStar(require("vscode"));
const automationClient_1 = require("./automationClient");
let automationClient;
let outputChannel;
/**
 * Extension activation entry point
 */
function activate(context) {
    outputChannel = vscode.window.createOutputChannel('WORLD OLLAMA Automation');
    // Get configuration
    const config = vscode.workspace.getConfiguration('worldOllama.automation');
    const tauriServerUrl = config.get('tauriServerUrl', 'http://localhost:1421');
    const debugMode = config.get('debugMode', false);
    // Initialize automation client
    automationClient = new automationClient_1.AutomationClient(tauriServerUrl, outputChannel, debugMode);
    // Log activation
    outputChannel.appendLine('=== WORLD OLLAMA Desktop Automation Extension ===');
    outputChannel.appendLine(`Version: 0.3.1 (ЭТАП 0-2 COMPLETE)`);
    outputChannel.appendLine(`Tauri Server: ${tauriServerUrl}`);
    outputChannel.appendLine(`Debug Mode: ${debugMode}`);
    outputChannel.appendLine(`Activated at: ${new Date().toISOString()}`);
    outputChannel.appendLine('');
    // Register commands
    registerCommands(context);
    // Auto-activate check (optional health check)
    if (config.get('autoActivate', true)) {
        checkTauriServerHealth();
    }
    outputChannel.appendLine('✅ Extension activated successfully');
}
/**
 * Register all automation commands
 */
function registerCommands(context) {
    // 1. Get Screen State
    const getScreenState = vscode.commands.registerCommand('worldOllama.automation.getScreenState', async () => {
        try {
            outputChannel.appendLine('[CMD] Get Screen State');
            const result = await automationClient.getScreenState();
            if (result.success && result.data) {
                outputChannel.appendLine(`✅ Screens: ${result.data.screens_available}`);
                vscode.window.showInformationMessage(`Desktop Automation: ${result.data.screens_available} monitor(s) detected`);
                return result.data;
            }
            else {
                outputChannel.appendLine(`❌ Error: ${result.error}`);
                vscode.window.showErrorMessage(`Desktop Automation Error: ${result.error}`);
                return null;
            }
        }
        catch (error) {
            handleCommandError('getScreenState', error);
            return null;
        }
    });
    // 2. Capture Screenshot
    const captureScreenshot = vscode.commands.registerCommand('worldOllama.automation.captureScreenshot', async (args) => {
        try {
            const monitorIndex = args?.monitorIndex ?? 0;
            outputChannel.appendLine(`[CMD] Capture Screenshot (monitor ${monitorIndex})`);
            const result = await automationClient.captureScreenshot(monitorIndex);
            if (result.success && result.data) {
                const sizeKB = (result.data.length / 1024).toFixed(2);
                outputChannel.appendLine(`✅ Screenshot captured: ${sizeKB} KB`);
                vscode.window.showInformationMessage(`Desktop Automation: Screenshot captured (${sizeKB} KB)`);
                return result.data; // PNG bytes
            }
            else {
                outputChannel.appendLine(`❌ Error: ${result.error}`);
                vscode.window.showErrorMessage(`Desktop Automation Error: ${result.error}`);
                return null;
            }
        }
        catch (error) {
            handleCommandError('captureScreenshot', error);
            return null;
        }
    });
    // 3. Click at Coordinates
    const click = vscode.commands.registerCommand('worldOllama.automation.click', async (args) => {
        try {
            const x = args?.x ?? 0;
            const y = args?.y ?? 0;
            outputChannel.appendLine(`[CMD] Click at (${x}, ${y})`);
            const result = await automationClient.click(x, y);
            if (result.success) {
                outputChannel.appendLine(`✅ ${result.data}`);
                return result.data;
            }
            else {
                outputChannel.appendLine(`❌ Error: ${result.error}`);
                vscode.window.showErrorMessage(`Desktop Automation Error: ${result.error}`);
                return null;
            }
        }
        catch (error) {
            handleCommandError('click', error);
            return null;
        }
    });
    // 4. Type Text
    const typeText = vscode.commands.registerCommand('worldOllama.automation.typeText', async (args) => {
        try {
            const text = args?.text ?? '';
            outputChannel.appendLine(`[CMD] Type Text: "${text.substring(0, 50)}..."`);
            const result = await automationClient.typeText(text);
            if (result.success) {
                outputChannel.appendLine(`✅ ${result.data}`);
                return result.data;
            }
            else {
                outputChannel.appendLine(`❌ Error: ${result.error}`);
                vscode.window.showErrorMessage(`Desktop Automation Error: ${result.error}`);
                return null;
            }
        }
        catch (error) {
            handleCommandError('typeText', error);
            return null;
        }
    });
    // 5. Get Active Windows
    const getWindows = vscode.commands.registerCommand('worldOllama.automation.getWindows', async () => {
        try {
            outputChannel.appendLine('[CMD] Get Active Windows');
            const result = await automationClient.getWindows();
            if (result.success && result.data) {
                outputChannel.appendLine(`✅ Windows: ${result.data.length}`);
                if (result.data.length === 1 && result.data[0].title.includes('placeholder')) {
                    outputChannel.appendLine('ℹ️  Note: ЭТАП 2 placeholder (1 window). Full impl in ЭТАП 3.');
                }
                return result.data;
            }
            else {
                outputChannel.appendLine(`❌ Error: ${result.error}`);
                vscode.window.showErrorMessage(`Desktop Automation Error: ${result.error}`);
                return null;
            }
        }
        catch (error) {
            handleCommandError('getWindows', error);
            return null;
        }
    });
    // Add to subscriptions
    context.subscriptions.push(getScreenState, captureScreenshot, click, typeText, getWindows);
    outputChannel.appendLine('✅ Registered 5 automation commands');
}
/**
 * Check Tauri server health (optional startup check)
 */
async function checkTauriServerHealth() {
    try {
        outputChannel.appendLine('[HEALTH] Checking Tauri server...');
        const result = await automationClient.getScreenState();
        if (result.success) {
            outputChannel.appendLine('✅ Tauri server is healthy');
        }
        else {
            outputChannel.appendLine('⚠️  Tauri server responded with error');
            outputChannel.appendLine(`    Error: ${result.error}`);
            vscode.window.showWarningMessage('Desktop Automation: Tauri server not ready. Run "npm run tauri dev" in client/ directory.');
        }
    }
    catch (error) {
        outputChannel.appendLine('❌ Tauri server health check failed');
        outputChannel.appendLine(`    ${error}`);
        vscode.window.showWarningMessage('Desktop Automation: Cannot connect to Tauri server. Ensure "npm run tauri dev" is running.');
    }
}
/**
 * Handle command execution errors
 */
function handleCommandError(commandName, error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    outputChannel.appendLine(`❌ Command failed: ${commandName}`);
    outputChannel.appendLine(`    Error: ${errorMessage}`);
    vscode.window.showErrorMessage(`Desktop Automation: ${commandName} failed. Check Output panel for details.`, 'Show Output').then(selection => {
        if (selection === 'Show Output') {
            outputChannel.show();
        }
    });
}
/**
 * Extension deactivation
 */
function deactivate() {
    if (outputChannel) {
        outputChannel.appendLine('');
        outputChannel.appendLine('=== Extension Deactivating ===');
        outputChannel.appendLine(`Timestamp: ${new Date().toISOString()}`);
        outputChannel.dispose();
    }
}
//# sourceMappingURL=extension.js.map
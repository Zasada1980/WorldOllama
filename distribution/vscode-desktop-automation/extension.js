// Desktop Automation Extension for VS Code
// Provides UI automation commands via PowerShell bridge to Tauri automation modules

const vscode = require('vscode');
const path = require('path');
const fs = require('fs');
const { exec } = require('child_process');
const util = require('util');
const execPromise = util.promisify(exec);

let outputChannel;

/**
 * Extension activation
 */
function activate(context) {
    console.log('Desktop Automation extension is now active');
    
    // Create output channel for logs
    outputChannel = vscode.window.createOutputChannel('Desktop Automation');
    outputChannel.appendLine('Desktop Automation Tools activated');
    
    // Get workspace root
    const workspaceRoot = getWorkspaceRoot();
    if (!workspaceRoot) {
        vscode.window.showWarningMessage('Desktop Automation: No workspace folder found');
        return;
    }
    
    outputChannel.appendLine(`Workspace root: ${workspaceRoot}`);
    
    // Register commands
    const commands = [
        vscode.commands.registerCommand('automation.getScreenState', () => getScreenState(workspaceRoot)),
        vscode.commands.registerCommand('automation.captureScreenshot', () => captureScreenshot(workspaceRoot)),
        vscode.commands.registerCommand('automation.clickAt', () => clickAt(workspaceRoot)),
        vscode.commands.registerCommand('automation.typeText', () => typeText(workspaceRoot)),
        vscode.commands.registerCommand('automation.getWindows', () => getWindows(workspaceRoot)),
        vscode.commands.registerCommand('automation.runScenario', () => runScenario(workspaceRoot)),
        vscode.commands.registerCommand('automation.showLogs', () => showLogs()),
        vscode.commands.registerCommand('automation.openConfiguration', () => openConfiguration())
    ];
    
    commands.forEach(cmd => context.subscriptions.push(cmd));
    
    // Auto-start Tauri if configured
    const config = vscode.workspace.getConfiguration('automation');
    if (config.get('autoStartTauri', false)) {
        outputChannel.appendLine('Auto-start Tauri enabled (not implemented in v1.0)');
    }
    
    vscode.window.showInformationMessage('Desktop Automation Tools ready');
}

/**
 * Extension deactivation
 */
function deactivate() {
    if (outputChannel) {
        outputChannel.dispose();
    }
}

/**
 * Get workspace root path
 */
function getWorkspaceRoot() {
    const workspaceFolders = vscode.workspace.workspaceFolders;
    if (!workspaceFolders || workspaceFolders.length === 0) {
        return null;
    }
    // Find WORLD_OLLAMA workspace
    for (const folder of workspaceFolders) {
        if (folder.uri.fsPath.includes('WORLD_OLLAMA')) {
            return folder.uri.fsPath;
        }
    }
    return workspaceFolders[0].uri.fsPath;
}

/**
 * Execute PowerShell script
 */
async function executePowerShell(scriptPath, args = '') {
    try {
        outputChannel.appendLine(`Executing: pwsh -File "${scriptPath}" ${args}`);
        const { stdout, stderr } = await execPromise(`pwsh -File "${scriptPath}" ${args}`, {
            cwd: path.dirname(scriptPath)
        });
        
        if (stderr) {
            outputChannel.appendLine(`STDERR: ${stderr}`);
        }
        
        outputChannel.appendLine(`STDOUT: ${stdout}`);
        return { success: true, stdout, stderr };
    } catch (error) {
        outputChannel.appendLine(`ERROR: ${error.message}`);
        return { success: false, error: error.message };
    }
}

/**
 * Command: Get Screen State
 */
async function getScreenState(workspaceRoot) {
    outputChannel.show();
    outputChannel.appendLine('\n=== GET SCREEN STATE ===');
    
    const scriptPath = path.join(workspaceRoot, 'client', 'test_stage1_automation.ps1');
    if (!fs.existsSync(scriptPath)) {
        vscode.window.showErrorMessage('Test script not found: ' + scriptPath);
        return;
    }
    
    vscode.window.showInformationMessage('Getting screen state...');
    
    const result = await executePowerShell(scriptPath);
    if (result.success) {
        vscode.window.showInformationMessage('Screen state retrieved successfully');
    } else {
        vscode.window.showErrorMessage('Failed to get screen state: ' + result.error);
    }
}

/**
 * Command: Capture Screenshot
 */
async function captureScreenshot(workspaceRoot) {
    outputChannel.show();
    outputChannel.appendLine('\n=== CAPTURE SCREENSHOT ===');
    
    const config = vscode.workspace.getConfiguration('automation');
    const monitorIndex = config.get('defaultMonitor', 0);
    
    outputChannel.appendLine(`Monitor index: ${monitorIndex}`);
    
    // Use E2E test script as demo
    const scriptPath = path.join(workspaceRoot, 'client', 'test_stage2_e2e.ps1');
    if (!fs.existsSync(scriptPath)) {
        vscode.window.showErrorMessage('E2E test script not found');
        return;
    }
    
    vscode.window.showInformationMessage(`Capturing screenshot from monitor ${monitorIndex}...`);
    
    const result = await executePowerShell(scriptPath);
    if (result.success) {
        vscode.window.showInformationMessage('Screenshot test completed');
    } else {
        vscode.window.showErrorMessage('Screenshot test failed: ' + result.error);
    }
}

/**
 * Command: Click at Coordinates
 */
async function clickAt(workspaceRoot) {
    outputChannel.show();
    outputChannel.appendLine('\n=== CLICK AT COORDINATES ===');
    
    const x = await vscode.window.showInputBox({
        prompt: 'Enter X coordinate',
        value: '100',
        validateInput: (value) => {
            return isNaN(parseInt(value)) ? 'Must be a number' : null;
        }
    });
    
    if (!x) return;
    
    const y = await vscode.window.showInputBox({
        prompt: 'Enter Y coordinate',
        value: '100',
        validateInput: (value) => {
            return isNaN(parseInt(value)) ? 'Must be a number' : null;
        }
    });
    
    if (!y) return;
    
    outputChannel.appendLine(`Click coordinates: (${x}, ${y})`);
    vscode.window.showInformationMessage(`Click simulation: (${x}, ${y}) - requires Tauri app running`);
    
    const config = vscode.workspace.getConfiguration('automation');
    const delay = config.get('clickDelay', 500);
    outputChannel.appendLine(`Click delay configured: ${delay}ms`);
}

/**
 * Command: Type Text
 */
async function typeText(workspaceRoot) {
    outputChannel.show();
    outputChannel.appendLine('\n=== TYPE TEXT ===');
    
    const text = await vscode.window.showInputBox({
        prompt: 'Enter text to type',
        value: 'Hello World'
    });
    
    if (!text) return;
    
    outputChannel.appendLine(`Text to type: "${text}"`);
    vscode.window.showInformationMessage(`Type simulation: "${text}" - requires Tauri app running`);
}

/**
 * Command: Get Active Windows
 */
async function getWindows(workspaceRoot) {
    outputChannel.show();
    outputChannel.appendLine('\n=== GET ACTIVE WINDOWS ===');
    
    outputChannel.appendLine('Note: ЭТАП 2 returns placeholder (1 window)');
    outputChannel.appendLine('Full implementation in ЭТАП 3 (WinAPI integration)');
    
    vscode.window.showInformationMessage('Get Windows - ЭТАП 2 placeholder (see output)');
}

/**
 * Command: Run Test Scenario
 */
async function runScenario(workspaceRoot) {
    outputChannel.show();
    outputChannel.appendLine('\n=== RUN TEST SCENARIO ===');
    
    const scenarios = [
        'ЭТАП 1: Integration Tests',
        'ЭТАП 2: E2E Tests',
        'ЭТАП 2: Simple Scenario'
    ];
    
    const selected = await vscode.window.showQuickPick(scenarios, {
        placeHolder: 'Select test scenario'
    });
    
    if (!selected) return;
    
    let scriptPath;
    if (selected.includes('ЭТАП 1')) {
        scriptPath = path.join(workspaceRoot, 'client', 'test_stage1_automation.ps1');
    } else if (selected.includes('E2E')) {
        scriptPath = path.join(workspaceRoot, 'client', 'test_stage2_e2e.ps1');
    } else {
        scriptPath = path.join(workspaceRoot, 'client', 'test_stage2_scenario.ps1');
    }
    
    if (!fs.existsSync(scriptPath)) {
        vscode.window.showErrorMessage('Test script not found: ' + scriptPath);
        return;
    }
    
    outputChannel.appendLine(`Running: ${selected}`);
    vscode.window.showInformationMessage(`Running scenario: ${selected}`);
    
    const result = await executePowerShell(scriptPath);
    if (result.success) {
        vscode.window.showInformationMessage('Scenario completed successfully');
    } else {
        vscode.window.showErrorMessage('Scenario failed: ' + result.error);
    }
}

/**
 * Command: Show Logs
 */
function showLogs() {
    outputChannel.show();
}

/**
 * Command: Open Configuration
 */
function openConfiguration() {
    vscode.commands.executeCommand('workbench.action.openSettings', 'automation');
}

module.exports = {
    activate,
    deactivate
};

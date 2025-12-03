// VS Code Indexation Tools Extension
// Copyright (c) 2025 GateVibe Israel Ltd
// Author: Andrey Grushin
// License: MIT

const vscode = require('vscode');
const path = require('path');
const fs = require('fs');
const { exec } = require('child_process');
const util = require('util');
const execPromise = util.promisify(exec);

let watcherProcess = null;
let outputChannel = null;

/**
 * Extension activation
 * @param {vscode.ExtensionContext} context
 */
function activate(context) {
    console.log('VS Code Indexation Tools activated');
    
    // Create output channel
    outputChannel = vscode.window.createOutputChannel('Indexation Tools');
    context.subscriptions.push(outputChannel);
    
    // Register all commands
    registerCommands(context);
    
    // Auto-start watcher if configured
    const config = vscode.workspace.getConfiguration('indexation');
    if (config.get('autoWatch', false)) {
        startWatcher();
    }
    
    outputChannel.appendLine('✅ Indexation Tools ready');
}

/**
 * Extension deactivation
 */
function deactivate() {
    if (watcherProcess) {
        try {
            process.kill(watcherProcess.pid);
            outputChannel.appendLine('🛑 File watcher stopped');
        } catch (error) {
            console.error('Error stopping watcher:', error);
        }
    }
}

/**
 * Register all extension commands
 */
function registerCommands(context) {
    const commands = [
        { id: 'indexation.fullReindex', handler: fullReindex },
        { id: 'indexation.incrementalUpdate', handler: incrementalUpdate },
        { id: 'indexation.startWatcher', handler: startWatcher },
        { id: 'indexation.stopWatcher', handler: stopWatcher },
        { id: 'indexation.installGitHook', handler: installGitHook },
        { id: 'indexation.createScheduledTask', handler: createScheduledTask },
        { id: 'indexation.removeScheduledTask', handler: removeScheduledTask },
        { id: 'indexation.showLogs', handler: showLogs },
        { id: 'indexation.runTests', handler: runTests },
        { id: 'indexation.openConfiguration', handler: openConfiguration }
    ];
    
    commands.forEach(cmd => {
        const disposable = vscode.commands.registerCommand(cmd.id, cmd.handler);
        context.subscriptions.push(disposable);
    });
}

/**
 * Get workspace root path
 */
function getWorkspaceRoot() {
    const workspaceFolders = vscode.workspace.workspaceFolders;
    if (!workspaceFolders || workspaceFolders.length === 0) {
        throw new Error('No workspace folder open');
    }
    return workspaceFolders[0].uri.fsPath;
}

/**
 * Get scripts path from configuration or auto-detect
 */
function getScriptsPath() {
    const config = vscode.workspace.getConfiguration('indexation');
    let scriptsPath = config.get('scriptsPath', '');
    
    if (!scriptsPath) {
        // Auto-detect: check if extension includes scripts
        const extensionPath = path.dirname(__filename);
        const embeddedScripts = path.join(extensionPath, 'scripts');
        
        if (fs.existsSync(embeddedScripts)) {
            scriptsPath = embeddedScripts;
        } else {
            // Fallback: workspace/scripts
            const workspaceRoot = getWorkspaceRoot();
            scriptsPath = path.join(workspaceRoot, 'scripts');
        }
    }
    
    if (!fs.existsSync(scriptsPath)) {
        throw new Error(`Scripts directory not found: ${scriptsPath}`);
    }
    
    return scriptsPath;
}

/**
 * Execute PowerShell script
 */
async function executePowerShell(scriptPath, args = []) {
    const argsString = args.join(' ');
    const command = `pwsh -NoProfile -ExecutionPolicy Bypass -File "${scriptPath}" ${argsString}`;
    
    outputChannel.appendLine(`\n▶️ Executing: ${path.basename(scriptPath)}`);
    outputChannel.show(true);
    
    try {
        const { stdout, stderr } = await execPromise(command, { 
            cwd: getWorkspaceRoot(),
            maxBuffer: 10 * 1024 * 1024 // 10MB buffer
        });
        
        if (stdout) outputChannel.appendLine(stdout);
        if (stderr) outputChannel.appendLine(`⚠️ ${stderr}`);
        
        return { success: true, stdout, stderr };
    } catch (error) {
        outputChannel.appendLine(`❌ Error: ${error.message}`);
        throw error;
    }
}

/**
 * Command: Full Reindex
 */
async function fullReindex() {
    try {
        const scriptsPath = getScriptsPath();
        const scriptFile = path.join(scriptsPath, 'UPDATE_PROJECT_INDEX.ps1');
        
        await vscode.window.withProgress({
            location: vscode.ProgressLocation.Notification,
            title: "Running full reindex...",
            cancellable: false
        }, async (progress) => {
            await executePowerShell(scriptFile, ['-FullReindex']);
        });
        
        const config = vscode.workspace.getConfiguration('indexation');
        if (config.get('notifyOnUpdate', true)) {
            vscode.window.showInformationMessage('✅ Full reindex completed');
        }
    } catch (error) {
        vscode.window.showErrorMessage(`Reindex failed: ${error.message}`);
    }
}

/**
 * Command: Incremental Update
 */
async function incrementalUpdate() {
    try {
        const activeEditor = vscode.window.activeTextEditor;
        if (!activeEditor) {
            vscode.window.showWarningMessage('No active file to index');
            return;
        }
        
        const filePath = activeEditor.document.uri.fsPath;
        const scriptsPath = getScriptsPath();
        const scriptFile = path.join(scriptsPath, 'UPDATE_PROJECT_INDEX.ps1');
        
        await executePowerShell(scriptFile, [
            '-IncrementalMode',
            '-TriggerFile', `"${filePath}"`
        ]);
        
        const config = vscode.workspace.getConfiguration('indexation');
        if (config.get('notifyOnUpdate', true)) {
            vscode.window.showInformationMessage('✅ Index updated');
        }
    } catch (error) {
        vscode.window.showErrorMessage(`Incremental update failed: ${error.message}`);
    }
}

/**
 * Command: Start File Watcher
 */
async function startWatcher() {
    if (watcherProcess) {
        vscode.window.showWarningMessage('File watcher already running');
        return;
    }
    
    try {
        const scriptsPath = getScriptsPath();
        const scriptFile = path.join(scriptsPath, 'WATCH_FILE_CHANGES.ps1');
        
        outputChannel.appendLine('\n🔍 Starting file watcher...');
        outputChannel.show(true);
        
        watcherProcess = exec(`pwsh -NoProfile -File "${scriptFile}"`, {
            cwd: getWorkspaceRoot()
        });
        
        watcherProcess.stdout.on('data', (data) => {
            outputChannel.append(data.toString());
        });
        
        watcherProcess.stderr.on('data', (data) => {
            outputChannel.append(`⚠️ ${data.toString()}`);
        });
        
        watcherProcess.on('exit', (code) => {
            outputChannel.appendLine(`\n🛑 Watcher exited with code ${code}`);
            watcherProcess = null;
        });
        
        vscode.window.showInformationMessage('✅ File watcher started');
    } catch (error) {
        vscode.window.showErrorMessage(`Failed to start watcher: ${error.message}`);
    }
}

/**
 * Command: Stop File Watcher
 */
function stopWatcher() {
    if (!watcherProcess) {
        vscode.window.showWarningMessage('No file watcher running');
        return;
    }
    
    try {
        process.kill(watcherProcess.pid);
        watcherProcess = null;
        outputChannel.appendLine('\n🛑 File watcher stopped');
        vscode.window.showInformationMessage('✅ File watcher stopped');
    } catch (error) {
        vscode.window.showErrorMessage(`Failed to stop watcher: ${error.message}`);
    }
}

/**
 * Command: Install Git Hook
 */
async function installGitHook() {
    try {
        const scriptsPath = getScriptsPath();
        const scriptFile = path.join(scriptsPath, 'INSTALL_GIT_HOOK.ps1');
        
        await executePowerShell(scriptFile);
        vscode.window.showInformationMessage('✅ Git post-commit hook installed');
    } catch (error) {
        vscode.window.showErrorMessage(`Git hook installation failed: ${error.message}`);
    }
}

/**
 * Command: Create Scheduled Task
 */
async function createScheduledTask() {
    try {
        const time = await vscode.window.showInputBox({
            prompt: 'Enter execution time (HH:MM format)',
            value: '03:00',
            validateInput: (value) => {
                const timeRegex = /^([0-1][0-9]|2[0-3]):[0-5][0-9]$/;
                return timeRegex.test(value) ? null : 'Invalid time format (use HH:MM)';
            }
        });
        
        if (!time) return;
        
        const scriptsPath = getScriptsPath();
        const scriptFile = path.join(scriptsPath, 'CREATE_SCHEDULED_TASK.ps1');
        
        await executePowerShell(scriptFile, ['-ExecutionTime', time]);
        vscode.window.showInformationMessage(`✅ Scheduled task created (daily at ${time})`);
    } catch (error) {
        vscode.window.showErrorMessage(`Scheduled task creation failed: ${error.message}`);
    }
}

/**
 * Command: Remove Scheduled Task
 */
async function removeScheduledTask() {
    try {
        const scriptsPath = getScriptsPath();
        const scriptFile = path.join(scriptsPath, 'CREATE_SCHEDULED_TASK.ps1');
        
        await executePowerShell(scriptFile, ['-RemoveTask']);
        vscode.window.showInformationMessage('✅ Scheduled task removed');
    } catch (error) {
        vscode.window.showErrorMessage(`Scheduled task removal failed: ${error.message}`);
    }
}

/**
 * Command: Show Logs
 */
async function showLogs() {
    try {
        const workspaceRoot = getWorkspaceRoot();
        const logsPath = path.join(workspaceRoot, 'logs', 'indexation.log');
        
        if (!fs.existsSync(logsPath)) {
            vscode.window.showWarningMessage('No log file found');
            return;
        }
        
        const document = await vscode.workspace.openTextDocument(logsPath);
        await vscode.window.showTextDocument(document);
    } catch (error) {
        vscode.window.showErrorMessage(`Failed to open logs: ${error.message}`);
    }
}

/**
 * Command: Run Tests
 */
async function runTests() {
    try {
        const scriptsPath = getScriptsPath();
        const testsPath = path.join(scriptsPath, '..', 'tests');
        
        if (!fs.existsSync(testsPath)) {
            vscode.window.showWarningMessage('Tests directory not found');
            return;
        }
        
        const testFiles = fs.readdirSync(testsPath)
            .filter(f => f.startsWith('test_') && f.endsWith('.ps1'));
        
        const selected = await vscode.window.showQuickPick(testFiles, {
            placeHolder: 'Select test to run'
        });
        
        if (!selected) return;
        
        const testFile = path.join(testsPath, selected);
        await executePowerShell(testFile);
        
    } catch (error) {
        vscode.window.showErrorMessage(`Test execution failed: ${error.message}`);
    }
}

/**
 * Command: Open Configuration
 */
async function openConfiguration() {
    try {
        const workspaceRoot = getWorkspaceRoot();
        const configPath = path.join(workspaceRoot, '.vscode-indexation.json');
        
        if (!fs.existsSync(configPath)) {
            // Create from template
            const scriptsPath = getScriptsPath();
            const templatePath = path.join(scriptsPath, '..', 'templates', '.vscode-indexation.json');
            
            if (fs.existsSync(templatePath)) {
                fs.copyFileSync(templatePath, configPath);
            } else {
                vscode.window.showWarningMessage('Configuration template not found');
                return;
            }
        }
        
        const document = await vscode.workspace.openTextDocument(configPath);
        await vscode.window.showTextDocument(document);
        
    } catch (error) {
        vscode.window.showErrorMessage(`Failed to open configuration: ${error.message}`);
    }
}

module.exports = {
    activate,
    deactivate
};

/**
 * Developer API - Real backend integration for Developer Mode
 */

// API базовый URL - используем относительные пути для production
// В dev режиме Vite proxy перенаправит на localhost:3000
const API_BASE = import.meta.env.VITE_API_URL || '';

// Флаг для демо-режима (без backend)
const DEMO_MODE = true; // Включить демо-режим по умолчанию (backend не готов)

export interface FileItem {
    name: string;
    path: string;
    type: 'file' | 'directory';
    size?: number;
    modified?: string;
    content?: string;
}

export interface SQLResult {
    columns: string[];
    rows: any[][];
    rowCount: number;
    executionTime: number;
    error?: string;
}

export interface SystemMetrics {
    cpu: {
        usage: number;
        cores: number;
        model: string;
    };
    memory: {
        total: number;
        used: number;
        free: number;
        usagePercent: number;
    };
    disk: {
        total: number;
        used: number;
        free: number;
    };
}

export interface JobQueueItem {
    id: string;
    name: string;
    status: 'pending' | 'running' | 'completed' | 'failed';
    progress: number;
    createdAt: string;
    completedAt?: string;
    error?: string;
}

export interface EnvVariable {
    key: string;
    value: string;
    masked: boolean;
}

/**
 * File System API
 */
export const fileSystemAPI = {
    // Получить дерево файлов
    async getFileTree(): Promise<Record<string, FileItem[]>> {
        // DEMO MODE: Возвращаем демо-данные сразу
        if (DEMO_MODE) {
            return {
                'config': [
                    { name: 'app.json', path: 'config/app.json', type: 'file', size: 1024 },
                    { name: 'database.json', path: 'config/database.json', type: 'file', size: 512 },
                    { name: 'redis.json', path: 'config/redis.json', type: 'file', size: 256 }
                ],
                'src': [
                    { name: 'index.ts', path: 'src/index.ts', type: 'file', size: 2048 },
                    { name: 'routes.ts', path: 'src/routes.ts', type: 'file', size: 4096 },
                    { name: 'middleware.ts', path: 'src/middleware.ts', type: 'file', size: 1536 }
                ],
                'public': [
                    { name: 'index.html', path: 'public/index.html', type: 'file', size: 3072 },
                    { name: 'styles.css', path: 'public/styles.css', type: 'file', size: 8192 }
                ]
            };
        }

        try {
            const response = await fetch(`${API_BASE}/api/dev/files/tree`);
            if (!response.ok) throw new Error('Failed to fetch file tree');
            return await response.json();
        } catch (error) {
            console.error('File tree error:', error);
            // Fallback на демо-данные
            return {
                'config': [
                    { name: 'app.json', path: 'config/app.json', type: 'file', size: 1024 },
                    { name: 'database.json', path: 'config/database.json', type: 'file', size: 512 },
                    { name: 'redis.json', path: 'config/redis.json', type: 'file', size: 256 }
                ],
                'src': [
                    { name: 'index.ts', path: 'src/index.ts', type: 'file', size: 2048 },
                    { name: 'routes.ts', path: 'src/routes.ts', type: 'file', size: 4096 },
                    { name: 'middleware.ts', path: 'src/middleware.ts', type: 'file', size: 1536 }
                ],
                'public': [
                    { name: 'index.html', path: 'public/index.html', type: 'file', size: 3072 },
                    { name: 'styles.css', path: 'public/styles.css', type: 'file', size: 8192 }
                ]
            };
        }
    },

    // Получить содержимое файла
    async getFileContent(path: string): Promise<string> {
        // DEMO MODE: Возвращаем демо-контент
        if (DEMO_MODE) {
            return `// ${path}\n// Demo file content\n\n{\n  "demo": true,\n  "path": "${path}",\n  "note": "This is demo data. Connect backend for real content."\n}`;
        }

        try {
            const response = await fetch(`${API_BASE}/api/dev/files/content?path=${encodeURIComponent(path)}`);
            if (!response.ok) throw new Error('Failed to fetch file content');
            const data = await response.json();
            return data.content;
        } catch (error) {
            console.error('File content error:', error);
            return `// ${path}\n// File content could not be loaded\n// Error: ${error}`;
        }
    },

    // Сохранить файл
    async saveFile(path: string, content: string): Promise<boolean> {
        try {
            const response = await fetch(`${API_BASE}/api/dev/files/save`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ path, content })
            });
            return response.ok;
        } catch (error) {
            console.error('File save error:', error);
            return false;
        }
    },

    // Удалить файл
    async deleteFile(path: string): Promise<boolean> {
        try {
            const response = await fetch(`${API_BASE}/api/dev/files/delete`, {
                method: 'DELETE',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ path })
            });
            return response.ok;
        } catch (error) {
            console.error('File delete error:', error);
            return false;
        }
    }
};

/**
 * SQL Console API
 */
export const sqlAPI = {
    async executeQuery(query: string): Promise<SQLResult> {
        const startTime = Date.now();
        try {
            const response = await fetch(`${API_BASE}/api/dev/sql/execute`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ query })
            });

            if (!response.ok) {
                const error = await response.json();
                return {
                    columns: [],
                    rows: [],
                    rowCount: 0,
                    executionTime: Date.now() - startTime,
                    error: error.message || 'Query execution failed'
                };
            }

            const data = await response.json();
            return {
                columns: data.columns || [],
                rows: data.rows || [],
                rowCount: data.rowCount || 0,
                executionTime: Date.now() - startTime
            };
        } catch (error) {
            return {
                columns: [],
                rows: [],
                rowCount: 0,
                executionTime: Date.now() - startTime,
                error: error instanceof Error ? error.message : 'Unknown error'
            };
        }
    }
};

/**
 * Terminal API
 */
export const terminalAPI = {
    async executeCommand(command: string): Promise<string> {
        try {
            const response = await fetch(`${API_BASE}/api/dev/terminal/execute`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ command })
            });

            if (!response.ok) throw new Error('Command execution failed');

            const data = await response.json();
            return data.output || '';
        } catch (error) {
            return `Error: ${error instanceof Error ? error.message : 'Unknown error'}`;
        }
    }
};

/**
 * System Monitor API
 */
export const monitorAPI = {
    async getMetrics(): Promise<SystemMetrics> {
        // DEMO MODE: Возвращаем симулированные метрики
        if (DEMO_MODE) {
            return {
                cpu: {
                    usage: Math.random() * 100,
                    cores: 8,
                    model: 'Intel Core i7'
                },
                memory: {
                    total: 16384,
                    used: 10240,
                    free: 6144,
                    usagePercent: 62.5 + (Math.random() - 0.5) * 20
                },
                disk: {
                    total: 512000,
                    used: 256000,
                    free: 256000
                }
            };
        }

        try {
            const response = await fetch(`${API_BASE}/api/dev/monitor/metrics`);
            if (!response.ok) throw new Error('Failed to fetch metrics');
            return await response.json();
        } catch (error) {
            console.error('Metrics error:', error);
            // Fallback на симуляцию
            return {
                cpu: {
                    usage: Math.random() * 100,
                    cores: 8,
                    model: 'Intel Core i7'
                },
                memory: {
                    total: 16384,
                    used: 10240,
                    free: 6144,
                    usagePercent: 62.5
                },
                disk: {
                    total: 512000,
                    used: 256000,
                    free: 256000
                }
            };
        }
    },

    async getEnvVariables(): Promise<EnvVariable[]> {
        // DEMO MODE: Возвращаем демо env vars
        if (DEMO_MODE) {
            return [
                { key: 'NODE_ENV', value: 'production', masked: false },
                { key: 'DATABASE_URL', value: 'postgres://****:****@localhost:5432/db', masked: true },
                { key: 'GEMINI_API_KEY', value: 'AIzaSy********************BY', masked: true },
                { key: 'REDIS_URL', value: 'redis://localhost:6379', masked: false }
            ];
        }

        try {
            const response = await fetch(`${API_BASE}/api/dev/monitor/env`);
            if (!response.ok) throw new Error('Failed to fetch env variables');
            return await response.json();
        } catch (error) {
            console.error('Env variables error:', error);
            return [
                { key: 'NODE_ENV', value: 'production', masked: false },
                { key: 'DATABASE_URL', value: 'postgres://****:****@localhost:5432/db', masked: true },
                { key: 'GEMINI_API_KEY', value: 'AIzaSy********************BY', masked: true },
                { key: 'REDIS_URL', value: 'redis://localhost:6379', masked: false }
            ];
        }
    }
};

/**
 * API Playground
 */
export const apiPlaygroundAPI = {
    async sendRequest(method: string, url: string, body?: any): Promise<any> {
        try {
            const options: RequestInit = {
                method,
                headers: { 'Content-Type': 'application/json' }
            };

            if (body && (method === 'POST' || method === 'PUT')) {
                options.body = JSON.stringify(body);
            }

            const fullUrl = url.startsWith('http') ? url : `${API_BASE}${url}`;
            const response = await fetch(fullUrl, options);

            const data = await response.json();

            return {
                status: response.status,
                statusText: response.statusText,
                headers: Object.fromEntries(response.headers.entries()),
                data
            };
        } catch (error) {
            return {
                status: 0,
                statusText: 'Network Error',
                error: error instanceof Error ? error.message : 'Unknown error'
            };
        }
    }
};

/**
 * Job Queues API
 */
export const jobQueueAPI = {
    async getJobs(): Promise<JobQueueItem[]> {
        // DEMO MODE: Возвращаем демо jobs
        if (DEMO_MODE) {
            return [
                {
                    id: '1',
                    name: 'Generate PDF Report',
                    status: 'completed',
                    progress: 100,
                    createdAt: new Date(Date.now() - 120000).toISOString(),
                    completedAt: new Date(Date.now() - 60000).toISOString()
                },
                {
                    id: '2',
                    name: 'Process AI Analysis',
                    status: 'running',
                    progress: 45,
                    createdAt: new Date(Date.now() - 30000).toISOString()
                },
                {
                    id: '3',
                    name: 'Send Email Notification',
                    status: 'failed',
                    progress: 0,
                    createdAt: new Date(Date.now() - 600000).toISOString(),
                    error: 'SMTP connection timeout'
                }
            ];
        }

        try {
            const response = await fetch(`${API_BASE}/api/dev/jobs`);
            if (!response.ok) throw new Error('Failed to fetch jobs');
            return await response.json();
        } catch (error) {
            console.error('Jobs error:', error);
            // Fallback на демо-данные
            return [
                {
                    id: '1',
                    name: 'Generate PDF Report',
                    status: 'completed',
                    progress: 100,
                    createdAt: new Date(Date.now() - 120000).toISOString(),
                    completedAt: new Date(Date.now() - 60000).toISOString()
                },
                {
                    id: '2',
                    name: 'Process AI Analysis',
                    status: 'running',
                    progress: 45,
                    createdAt: new Date(Date.now() - 30000).toISOString()
                },
                {
                    id: '3',
                    name: 'Send Email Notification',
                    status: 'failed',
                    progress: 0,
                    createdAt: new Date(Date.now() - 600000).toISOString(),
                    error: 'SMTP connection timeout'
                }
            ];
        }
    },

    async retryJob(id: string): Promise<boolean> {
        try {
            const response = await fetch(`${API_BASE}/api/dev/jobs/${id}/retry`, {
                method: 'POST'
            });
            return response.ok;
        } catch (error) {
            console.error('Job retry error:', error);
            return false;
        }
    }
};

/**
 * Webhooks API
 */
export const webhookAPI = {
    async triggerWebhook(event: string, payload: any): Promise<boolean> {
        try {
            const response = await fetch(`${API_BASE}/api/dev/webhooks/trigger`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ event, payload })
            });
            return response.ok;
        } catch (error) {
            console.error('Webhook trigger error:', error);
            return false;
        }
    }
};

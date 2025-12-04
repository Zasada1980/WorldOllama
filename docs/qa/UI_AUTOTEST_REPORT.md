{
  "config": {
    "rootDir": "E:/WORLD_OLLAMA/client",
    "forbidOnly": false,
    "fullyParallel": false,
    "globalSetup": null,
    "globalTeardown": null,
    "globalTimeout": 0,
    "grep": {},
    "grepInvert": null,
    "maxFailures": 0,
    "metadata": {
      "actualWorkers": 1
    },
    "preserveOutput": "always",
    "reporter": [
      [
        "html"
      ],
      [
        "json"
      ]
    ],
    "reportSlowTests": {
      "max": 5,
      "threshold": 300000
    },
    "quiet": false,
    "projects": [
      {
        "outputDir": "E:/WORLD_OLLAMA/client/test-results",
        "repeatEach": 1,
        "retries": 0,
        "metadata": {
          "actualWorkers": 1
        },
        "id": "",
        "name": "",
        "testDir": "E:/WORLD_OLLAMA/client",
        "testIgnore": [],
        "testMatch": [
          "**/*.@(spec|test).?(c|m)[jt]s?(x)"
        ],
        "timeout": 30000
      }
    ],
    "shard": null,
    "tags": [],
    "updateSnapshots": "missing",
    "updateSourceMethod": "patch",
    "version": "1.57.0",
    "workers": 14,
    "webServer": null
  },
  "suites": [
    {
      "title": "tests\\ui\\basic_panels.spec.ts",
      "file": "tests/ui/basic_panels.spec.ts",
      "column": 0,
      "line": 0,
      "specs": [
        {
          "title": "ChatPanel: ╨╛╤В╨┐╤А╨░╨▓╨║╨░ ╤Б╨╛╨╛╨▒╤Й╨╡╨╜╨╕╤П",
          "ok": false,
          "tags": [],
          "tests": [
            {
              "timeout": 30000,
              "annotations": [],
              "expectedStatus": "passed",
              "projectId": "",
              "projectName": "",
              "results": [
                {
                  "workerIndex": 0,
                  "parallelIndex": 0,
                  "status": "failed",
                  "duration": 3417,
                  "error": {
                    "message": "Error: page.goto: net::ERR_CONNECTION_REFUSED at http://localhost:1420/\nCall log:\n\u001b[2m  - navigating to \"http://localhost:1420/\", waiting until \"load\"\u001b[22m\n",
                    "stack": "Error: page.goto: net::ERR_CONNECTION_REFUSED at http://localhost:1420/\nCall log:\n\u001b[2m  - navigating to \"http://localhost:1420/\", waiting until \"load\"\u001b[22m\n\n    at E:\\WORLD_OLLAMA\\client\\tests\\ui\\basic_panels.spec.ts:8:14",
                    "location": {
                      "file": "E:\\WORLD_OLLAMA\\client\\tests\\ui\\basic_panels.spec.ts",
                      "column": 14,
                      "line": 8
                    },
                    "snippet": "\u001b[0m \u001b[90m  6 |\u001b[39m \u001b[90m// ...existing code...\u001b[39m\n \u001b[90m  7 |\u001b[39m test(\u001b[32m'ChatPanel: ╨╛╤В╨┐╤А╨░╨▓╨║╨░ ╤Б╨╛╨╛╨▒╤Й╨╡╨╜╨╕╤П'\u001b[39m\u001b[33m,\u001b[39m \u001b[36masync\u001b[39m ({ page }) \u001b[33m=>\u001b[39m {\n\u001b[31m\u001b[1m>\u001b[22m\u001b[39m\u001b[90m  8 |\u001b[39m   \u001b[36mawait\u001b[39m page\u001b[33m.\u001b[39mgoto(\u001b[32m'http://localhost:1420'\u001b[39m)\u001b[33m;\u001b[39m \u001b[90m// Tauri dev ╨┐╨╛╤А╤В\u001b[39m\n \u001b[90m    |\u001b[39m              \u001b[31m\u001b[1m^\u001b[22m\u001b[39m\n \u001b[90m  9 |\u001b[39m   \u001b[36mawait\u001b[39m page\u001b[33m.\u001b[39mclick(\u001b[32m'text=Chat'\u001b[39m)\u001b[33m;\u001b[39m\n \u001b[90m 10 |\u001b[39m   \u001b[36mawait\u001b[39m page\u001b[33m.\u001b[39mfill(\u001b[32m'textarea[placeholder=\"╨Т╨▓╨╡╨┤╨╕╤В╨╡ ╤Б╨╛╨╛╨▒╤Й╨╡╨╜╨╕╨╡\"]'\u001b[39m\u001b[33m,\u001b[39m \u001b[32m'╨Я╤А╨╕╨▓╨╡╤В, AI!'\u001b[39m)\u001b[33m;\u001b[39m\n \u001b[90m 11 |\u001b[39m   \u001b[36mawait\u001b[39m page\u001b[33m.\u001b[39mclick(\u001b[32m'button:has-text(\"Send\")'\u001b[39m)\u001b[33m;\u001b[39m\u001b[0m"
                  },
                  "errors": [
                    {
                      "location": {
                        "file": "E:\\WORLD_OLLAMA\\client\\tests\\ui\\basic_panels.spec.ts",
                        "column": 14,
                        "line": 8
                      },
                      "message": "Error: page.goto: net::ERR_CONNECTION_REFUSED at http://localhost:1420/\nCall log:\n\u001b[2m  - navigating to \"http://localhost:1420/\", waiting until \"load\"\u001b[22m\n\n\n   6 | // ...existing code...\n   7 | test('ChatPanel: ╨╛╤В╨┐╤А╨░╨▓╨║╨░ ╤Б╨╛╨╛╨▒╤Й╨╡╨╜╨╕╤П', async ({ page }) => {\n>  8 |   await page.goto('http://localhost:1420'); // Tauri dev ╨┐╨╛╤А╤В\n     |              ^\n   9 |   await page.click('text=Chat');\n  10 |   await page.fill('textarea[placeholder=\"╨Т╨▓╨╡╨┤╨╕╤В╨╡ ╤Б╨╛╨╛╨▒╤Й╨╡╨╜╨╕╨╡\"]', '╨Я╤А╨╕╨▓╨╡╤В, AI!');\n  11 |   await page.click('button:has-text(\"Send\")');\n    at E:\\WORLD_OLLAMA\\client\\tests\\ui\\basic_panels.spec.ts:8:14"
                    }
                  ],
                  "stdout": [],
                  "stderr": [],
                  "retry": 0,
                  "startTime": "2025-12-03T13:24:24.668Z",
                  "annotations": [],
                  "attachments": [],
                  "errorLocation": {
                    "file": "E:\\WORLD_OLLAMA\\client\\tests\\ui\\basic_panels.spec.ts",
                    "column": 14,
                    "line": 8
                  }
                }
              ],
              "status": "unexpected"
            }
          ],
          "id": "a80ef05e8ff84b33ac7c-e8cd04ca0a0d31e96c30",
          "file": "tests/ui/basic_panels.spec.ts",
          "line": 7,
          "column": 1
        },
        {
          "title": "SystemStatusPanel: ╨┐╤А╨╛╨▓╨╡╤А╨║╨░ ╤Б╤В╨░╤В╤Г╤Б╨░ ╤Б╨╡╤А╨▓╨╕╤Б╨╛╨▓",
          "ok": false,
          "tags": [],
          "tests": [
            {
              "timeout": 30000,
              "annotations": [],
              "expectedStatus": "passed",
              "projectId": "",
              "projectName": "",
              "results": [
                {
                  "workerIndex": 1,
                  "parallelIndex": 0,
                  "status": "failed",
                  "duration": 3449,
                  "error": {
                    "message": "Error: page.goto: net::ERR_CONNECTION_REFUSED at http://localhost:1420/\nCall log:\n\u001b[2m  - navigating to \"http://localhost:1420/\", waiting until \"load\"\u001b[22m\n",
                    "stack": "Error: page.goto: net::ERR_CONNECTION_REFUSED at http://localhost:1420/\nCall log:\n\u001b[2m  - navigating to \"http://localhost:1420/\", waiting until \"load\"\u001b[22m\n\n    at E:\\WORLD_OLLAMA\\client\\tests\\ui\\basic_panels.spec.ts:16:14",
                    "location": {
                      "file": "E:\\WORLD_OLLAMA\\client\\tests\\ui\\basic_panels.spec.ts",
                      "column": 14,
                      "line": 16
                    },
                    "snippet": "\u001b[0m \u001b[90m 14 |\u001b[39m\n \u001b[90m 15 |\u001b[39m test(\u001b[32m'SystemStatusPanel: ╨┐╤А╨╛╨▓╨╡╤А╨║╨░ ╤Б╤В╨░╤В╤Г╤Б╨░ ╤Б╨╡╤А╨▓╨╕╤Б╨╛╨▓'\u001b[39m\u001b[33m,\u001b[39m \u001b[36masync\u001b[39m ({ page }) \u001b[33m=>\u001b[39m {\n\u001b[31m\u001b[1m>\u001b[22m\u001b[39m\u001b[90m 16 |\u001b[39m   \u001b[36mawait\u001b[39m page\u001b[33m.\u001b[39mgoto(\u001b[32m'http://localhost:1420'\u001b[39m)\u001b[33m;\u001b[39m\n \u001b[90m    |\u001b[39m              \u001b[31m\u001b[1m^\u001b[22m\u001b[39m\n \u001b[90m 17 |\u001b[39m   \u001b[36mawait\u001b[39m page\u001b[33m.\u001b[39mclick(\u001b[32m'text=System Status'\u001b[39m)\u001b[33m;\u001b[39m\n \u001b[90m 18 |\u001b[39m   \u001b[36mawait\u001b[39m expect(page\u001b[33m.\u001b[39mlocator(\u001b[32m'.status-ollama'\u001b[39m))\u001b[33m.\u001b[39mtoHaveText(\u001b[35m/Running|OK/\u001b[39m)\u001b[33m;\u001b[39m\n \u001b[90m 19 |\u001b[39m   \u001b[36mawait\u001b[39m expect(page\u001b[33m.\u001b[39mlocator(\u001b[32m'.status-cortex'\u001b[39m))\u001b[33m.\u001b[39mtoHaveText(\u001b[35m/Running|OK/\u001b[39m)\u001b[33m;\u001b[39m\u001b[0m"
                  },
                  "errors": [
                    {
                      "location": {
                        "file": "E:\\WORLD_OLLAMA\\client\\tests\\ui\\basic_panels.spec.ts",
                        "column": 14,
                        "line": 16
                      },
                      "message": "Error: page.goto: net::ERR_CONNECTION_REFUSED at http://localhost:1420/\nCall log:\n\u001b[2m  - navigating to \"http://localhost:1420/\", waiting until \"load\"\u001b[22m\n\n\n  14 |\n  15 | test('SystemStatusPanel: ╨┐╤А╨╛╨▓╨╡╤А╨║╨░ ╤Б╤В╨░╤В╤Г╤Б╨░ ╤Б╨╡╤А╨▓╨╕╤Б╨╛╨▓', async ({ page }) => {\n> 16 |   await page.goto('http://localhost:1420');\n     |              ^\n  17 |   await page.click('text=System Status');\n  18 |   await expect(page.locator('.status-ollama')).toHaveText(/Running|OK/);\n  19 |   await expect(page.locator('.status-cortex')).toHaveText(/Running|OK/);\n    at E:\\WORLD_OLLAMA\\client\\tests\\ui\\basic_panels.spec.ts:16:14"
                    }
                  ],
                  "stdout": [],
                  "stderr": [],
                  "retry": 0,
                  "startTime": "2025-12-03T13:24:28.844Z",
                  "annotations": [],
                  "attachments": [],
                  "errorLocation": {
                    "file": "E:\\WORLD_OLLAMA\\client\\tests\\ui\\basic_panels.spec.ts",
                    "column": 14,
                    "line": 16
                  }
                }
              ],
              "status": "unexpected"
            }
          ],
          "id": "a80ef05e8ff84b33ac7c-46a0121f116341f3162f",
          "file": "tests/ui/basic_panels.spec.ts",
          "line": 15,
          "column": 1
        },
        {
          "title": "TrainingPanel: ╨╖╨░╨┐╤Г╤Б╨║ ╨╛╨▒╤Г╤З╨╡╨╜╨╕╤П",
          "ok": false,
          "tags": [],
          "tests": [
            {
              "timeout": 30000,
              "annotations": [],
              "expectedStatus": "passed",
              "projectId": "",
              "projectName": "",
              "results": [
                {
                  "workerIndex": 2,
                  "parallelIndex": 0,
                  "status": "failed",
                  "duration": 3423,
                  "error": {
                    "message": "Error: page.goto: net::ERR_CONNECTION_REFUSED at http://localhost:1420/\nCall log:\n\u001b[2m  - navigating to \"http://localhost:1420/\", waiting until \"load\"\u001b[22m\n",
                    "stack": "Error: page.goto: net::ERR_CONNECTION_REFUSED at http://localhost:1420/\nCall log:\n\u001b[2m  - navigating to \"http://localhost:1420/\", waiting until \"load\"\u001b[22m\n\n    at E:\\WORLD_OLLAMA\\client\\tests\\ui\\basic_panels.spec.ts:23:14",
                    "location": {
                      "file": "E:\\WORLD_OLLAMA\\client\\tests\\ui\\basic_panels.spec.ts",
                      "column": 14,
                      "line": 23
                    },
                    "snippet": "\u001b[0m \u001b[90m 21 |\u001b[39m\n \u001b[90m 22 |\u001b[39m test(\u001b[32m'TrainingPanel: ╨╖╨░╨┐╤Г╤Б╨║ ╨╛╨▒╤Г╤З╨╡╨╜╨╕╤П'\u001b[39m\u001b[33m,\u001b[39m \u001b[36masync\u001b[39m ({ page }) \u001b[33m=>\u001b[39m {\n\u001b[31m\u001b[1m>\u001b[22m\u001b[39m\u001b[90m 23 |\u001b[39m   \u001b[36mawait\u001b[39m page\u001b[33m.\u001b[39mgoto(\u001b[32m'http://localhost:1420'\u001b[39m)\u001b[33m;\u001b[39m\n \u001b[90m    |\u001b[39m              \u001b[31m\u001b[1m^\u001b[22m\u001b[39m\n \u001b[90m 24 |\u001b[39m   \u001b[36mawait\u001b[39m page\u001b[33m.\u001b[39mclick(\u001b[32m'text=Training'\u001b[39m)\u001b[33m;\u001b[39m\n \u001b[90m 25 |\u001b[39m   \u001b[36mawait\u001b[39m page\u001b[33m.\u001b[39mselectOption(\u001b[32m'select[name=\"profile\"]'\u001b[39m\u001b[33m,\u001b[39m \u001b[32m'triz_engineer'\u001b[39m)\u001b[33m;\u001b[39m\n \u001b[90m 26 |\u001b[39m   \u001b[36mawait\u001b[39m page\u001b[33m.\u001b[39mfill(\u001b[32m'input[name=\"epochs\"]'\u001b[39m\u001b[33m,\u001b[39m \u001b[32m'3'\u001b[39m)\u001b[33m;\u001b[39m\u001b[0m"
                  },
                  "errors": [
                    {
                      "location": {
                        "file": "E:\\WORLD_OLLAMA\\client\\tests\\ui\\basic_panels.spec.ts",
                        "column": 14,
                        "line": 23
                      },
                      "message": "Error: page.goto: net::ERR_CONNECTION_REFUSED at http://localhost:1420/\nCall log:\n\u001b[2m  - navigating to \"http://localhost:1420/\", waiting until \"load\"\u001b[22m\n\n\n  21 |\n  22 | test('TrainingPanel: ╨╖╨░╨┐╤Г╤Б╨║ ╨╛╨▒╤Г╤З╨╡╨╜╨╕╤П', async ({ page }) => {\n> 23 |   await page.goto('http://localhost:1420');\n     |              ^\n  24 |   await page.click('text=Training');\n  25 |   await page.selectOption('select[name=\"profile\"]', 'triz_engineer');\n  26 |   await page.fill('input[name=\"epochs\"]', '3');\n    at E:\\WORLD_OLLAMA\\client\\tests\\ui\\basic_panels.spec.ts:23:14"
                    }
                  ],
                  "stdout": [],
                  "stderr": [],
                  "retry": 0,
                  "startTime": "2025-12-03T13:24:32.857Z",
                  "annotations": [],
                  "attachments": [],
                  "errorLocation": {
                    "file": "E:\\WORLD_OLLAMA\\client\\tests\\ui\\basic_panels.spec.ts",
                    "column": 14,
                    "line": 23
                  }
                }
              ],
              "status": "unexpected"
            }
          ],
          "id": "a80ef05e8ff84b33ac7c-6e97aa7838bf09ab13b4",
          "file": "tests/ui/basic_panels.spec.ts",
          "line": 22,
          "column": 1
        },
        {
          "title": "FlowsPanel: ╨╖╨░╨┐╤Г╤Б╨║ quick_status flow",
          "ok": false,
          "tags": [],
          "tests": [
            {
              "timeout": 30000,
              "annotations": [],
              "expectedStatus": "passed",
              "projectId": "",
              "projectName": "",
              "results": [
                {
                  "workerIndex": 3,
                  "parallelIndex": 0,
                  "status": "failed",
                  "duration": 3424,
                  "error": {
                    "message": "Error: page.goto: net::ERR_CONNECTION_REFUSED at http://localhost:1420/\nCall log:\n\u001b[2m  - navigating to \"http://localhost:1420/\", waiting until \"load\"\u001b[22m\n",
                    "stack": "Error: page.goto: net::ERR_CONNECTION_REFUSED at http://localhost:1420/\nCall log:\n\u001b[2m  - navigating to \"http://localhost:1420/\", waiting until \"load\"\u001b[22m\n\n    at E:\\WORLD_OLLAMA\\client\\tests\\ui\\basic_panels.spec.ts:32:14",
                    "location": {
                      "file": "E:\\WORLD_OLLAMA\\client\\tests\\ui\\basic_panels.spec.ts",
                      "column": 14,
                      "line": 32
                    },
                    "snippet": "\u001b[0m \u001b[90m 30 |\u001b[39m\n \u001b[90m 31 |\u001b[39m test(\u001b[32m'FlowsPanel: ╨╖╨░╨┐╤Г╤Б╨║ quick_status flow'\u001b[39m\u001b[33m,\u001b[39m \u001b[36masync\u001b[39m ({ page }) \u001b[33m=>\u001b[39m {\n\u001b[31m\u001b[1m>\u001b[22m\u001b[39m\u001b[90m 32 |\u001b[39m   \u001b[36mawait\u001b[39m page\u001b[33m.\u001b[39mgoto(\u001b[32m'http://localhost:1420'\u001b[39m)\u001b[33m;\u001b[39m\n \u001b[90m    |\u001b[39m              \u001b[31m\u001b[1m^\u001b[22m\u001b[39m\n \u001b[90m 33 |\u001b[39m   \u001b[36mawait\u001b[39m page\u001b[33m.\u001b[39mclick(\u001b[32m'text=Flows'\u001b[39m)\u001b[33m;\u001b[39m\n \u001b[90m 34 |\u001b[39m   \u001b[36mawait\u001b[39m page\u001b[33m.\u001b[39mclick(\u001b[32m'button:has-text(\"Run quick_status\")'\u001b[39m)\u001b[33m;\u001b[39m\n \u001b[90m 35 |\u001b[39m   \u001b[36mawait\u001b[39m expect(page\u001b[33m.\u001b[39mlocator(\u001b[32m'.flow-status'\u001b[39m))\u001b[33m.\u001b[39mtoHaveText(\u001b[35m/success|OK/\u001b[39m)\u001b[33m;\u001b[39m\u001b[0m"
                  },
                  "errors": [
                    {
                      "location": {
                        "file": "E:\\WORLD_OLLAMA\\client\\tests\\ui\\basic_panels.spec.ts",
                        "column": 14,
                        "line": 32
                      },
                      "message": "Error: page.goto: net::ERR_CONNECTION_REFUSED at http://localhost:1420/\nCall log:\n\u001b[2m  - navigating to \"http://localhost:1420/\", waiting until \"load\"\u001b[22m\n\n\n  30 |\n  31 | test('FlowsPanel: ╨╖╨░╨┐╤Г╤Б╨║ quick_status flow', async ({ page }) => {\n> 32 |   await page.goto('http://localhost:1420');\n     |              ^\n  33 |   await page.click('text=Flows');\n  34 |   await page.click('button:has-text(\"Run quick_status\")');\n  35 |   await expect(page.locator('.flow-status')).toHaveText(/success|OK/);\n    at E:\\WORLD_OLLAMA\\client\\tests\\ui\\basic_panels.spec.ts:32:14"
                    }
                  ],
                  "stdout": [],
                  "stderr": [],
                  "retry": 0,
                  "startTime": "2025-12-03T13:24:36.852Z",
                  "annotations": [],
                  "attachments": [],
                  "errorLocation": {
                    "file": "E:\\WORLD_OLLAMA\\client\\tests\\ui\\basic_panels.spec.ts",
                    "column": 14,
                    "line": 32
                  }
                }
              ],
              "status": "unexpected"
            }
          ],
          "id": "a80ef05e8ff84b33ac7c-ca176d8a5bb5c78c261f",
          "file": "tests/ui/basic_panels.spec.ts",
          "line": 31,
          "column": 1
        }
      ]
    }
  ],
  "errors": [],
  "stats": {
    "startTime": "2025-12-03T13:24:24.051Z",
    "duration": 16338.198,
    "expected": 0,
    "skipped": 0,
    "unexpected": 4,
    "flaky": 0
  }
}

[36m  Serving HTML report at http://localhost:9323. Press Ctrl+C to quit.[39m

# PowerShell TODO MCP Proxy Server
# 最速起動版 with C# integration

Write-Host "⚡ PowerShell TODO MCP Server 起動中..." -ForegroundColor Cyan

# C#クラス定義
Add-Type @"
using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;
using System.Text.Json.Serialization;

public class TodoItem {
    [JsonPropertyName("id")]
    public long Id { get; set; }
    
    [JsonPropertyName("timestamp")]
    public DateTime Timestamp { get; set; }
    
    [JsonPropertyName("items")]
    public List<string> Items { get; set; } = new List<string>();
    
    [JsonPropertyName("category")]
    public string Category { get; set; } = "general";
    
    [JsonPropertyName("priority")]
    public string Priority { get; set; } = "medium";
}

public class TodoManager {
    private const string FilePath = "todos.json";
    
    public List<TodoItem> LoadTodos() {
        try {
            if (!File.Exists(FilePath)) return new List<TodoItem>();
            var json = File.ReadAllText(FilePath);
            return JsonSerializer.Deserialize<List<TodoItem>>(json) ?? new List<TodoItem>();
        } catch {
            return new List<TodoItem>();
        }
    }
    
    public void SaveTodos(List<TodoItem> todos) {
        try {
            var options = new JsonSerializerOptions { WriteIndented = true };
            var json = JsonSerializer.Serialize(todos, options);
            File.WriteAllText(FilePath, json);
        } catch (Exception ex) {
            Console.WriteLine("Error saving todos: " + ex.Message);
        }
    }
    
    public TodoItem CreateTodo(List<string> items, string category = "general", string priority = "medium") {
        return new TodoItem {
            Id = DateTimeOffset.Now.ToUnixTimeMilliseconds(),
            Timestamp = DateTime.Now,
            Items = items ?? new List<string>(),
            Category = category,
            Priority = priority
        };
    }
}

public class LLMResponseGenerator {
    public static (string content, bool shouldCallTool, List<string> extractedItems) GenerateResponse(string userMessage) {
        var items = new List<string>();
        
        if (userMessage.Contains("週末") || userMessage.Contains("予定")) {
            return ("週末の予定を整理しましょう！やりたいことを教えてください。整理して保存しますよ。", false, items);
        }
        
        if (userMessage.Contains("洗濯") || userMessage.Contains("買い物") || userMessage.Contains("映画") || userMessage.Contains("読書")) {
            if (userMessage.Contains("映画")) items.Add("友達と映画を見る");
            if (userMessage.Contains("洗濯")) items.Add("洗濯をする");
            if (userMessage.Contains("買い物")) items.Add("買い物に行く");
            if (userMessage.Contains("読書")) items.Add("読書をする");
            
            var content = "以下のタスクを整理しました：\n" + string.Join("\n", items.ConvertAll(item => "• " + item)) + 
                         "\n\n優先順位を付けて保存しますね。";
            return (content, true, items);
        }
        
        return ("どのようなことを整理したいですか？具体的に教えてください。", false, items);
    }
}
"@

# HTTPサーバー設定
$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add("http://localhost:3000/")

# CORS対応
$listener.AuthenticationSchemes = [System.Net.AuthenticationSchemes]::Anonymous

try {
    $listener.Start()
    Write-Host "🚀 サーバー起動完了!" -ForegroundColor Green
    Write-Host "📝 ブラウザで http://localhost:3000/todo-app.html を開いてください" -ForegroundColor Yellow
    Write-Host "🛑 停止するには Ctrl+C を押してください" -ForegroundColor Red
    Write-Host ""
    
    # TodoManagerインスタンス作成
    $todoManager = [TodoManager]::new()
    
    # メインループ
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        
        # CORS ヘッダー設定
        $response.Headers.Add("Access-Control-Allow-Origin", "*")
        $response.Headers.Add("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        $response.Headers.Add("Access-Control-Allow-Headers", "Content-Type")
        
        # OPTIONSリクエスト（プリフライト）対応
        if ($request.HttpMethod -eq "OPTIONS") {
            $response.StatusCode = 200
            $response.Close()
            continue
        }
        
        $url = $request.Url.AbsolutePath
        Write-Host "📝 Request: $($request.HttpMethod) $url" -ForegroundColor Gray
        
        try {
            switch ($url) {
                "/todo-app.html" {
                    # HTMLファイル配信
                    if (Test-Path "todo-app.html") {
                        $html = Get-Content "todo-app.html" -Raw -Encoding UTF8
                        $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
                        $response.ContentType = "text/html; charset=utf-8"
                        $response.ContentLength64 = $buffer.Length
                        $response.OutputStream.Write($buffer, 0, $buffer.Length)
                    } else {
                        $response.StatusCode = 404
                        $errorMsg = "todo-app.html not found"
                        $buffer = [System.Text.Encoding]::UTF8.GetBytes($errorMsg)
                        $response.OutputStream.Write($buffer, 0, $buffer.Length)
                    }
                }
                
                "/api/chat" {
                    if ($request.HttpMethod -eq "POST") {
                        # リクエストボディ読み込み
                        $reader = [System.IO.StreamReader]::new($request.InputStream, $request.ContentEncoding)
                        $requestBody = $reader.ReadToEnd()
                        $reader.Close()
                        
                        $requestData = $requestBody | ConvertFrom-Json
                        $lastMessage = $requestData.messages[-1].content
                        
                        # LLM応答生成
                        $llmResult = [LLMResponseGenerator]::GenerateResponse($lastMessage)
                        
                        # JSON応答作成
                        $responseObj = @{
                            type = "message"
                            role = "assistant"
                            content = @(@{
                                type = "text"
                                text = $llmResult.Item1
                            })
                        }
                        
                        # ツール呼び出しが必要な場合
                        if ($llmResult.Item2) {
                            $responseObj.tool_calls = @(@{
                                type = "function"
                                function = @{
                                    name = "todo_save"
                                    arguments = (@{
                                        items = $llmResult.Item3
                                        category = "weekend"
                                        priority = "medium"
                                    } | ConvertTo-Json -Compress)
                                }
                            })
                        }
                        
                        $jsonResponse = $responseObj | ConvertTo-Json -Depth 10
                        $buffer = [System.Text.Encoding]::UTF8.GetBytes($jsonResponse)
                        $response.ContentType = "application/json; charset=utf-8"
                        $response.ContentLength64 = $buffer.Length
                        $response.OutputStream.Write($buffer, 0, $buffer.Length)
                    }
                }
                
                "/api/tool/todo_save" {
                    if ($request.HttpMethod -eq "POST") {
                        # リクエストボディ読み込み
                        $reader = [System.IO.StreamReader]::new($request.InputStream, $request.ContentEncoding)
                        $requestBody = $reader.ReadToEnd()
                        $reader.Close()
                        
                        $requestData = $requestBody | ConvertFrom-Json
                        $params = $requestData.params
                        
                        # TODO作成・保存
                        $newTodo = $todoManager.CreateTodo(
                            $params.items, 
                            $params.category, 
                            $params.priority
                        )
                        
                        $todos = $todoManager.LoadTodos()
                        $todos.Add($newTodo)
                        $todoManager.SaveTodos($todos)
                        
                        # 成功応答
                        $responseObj = @{
                            success = $true
                            message = "$($params.items.Count)個のタスクを保存しました！"
                            data = @{
                                id = $newTodo.Id
                                timestamp = $newTodo.Timestamp.ToString("yyyy-MM-ddTHH:mm:ss")
                                items = $newTodo.Items
                                category = $newTodo.Category
                                priority = $newTodo.Priority
                            }
                        }
                        
                        $jsonResponse = $responseObj | ConvertTo-Json -Depth 10
                        $buffer = [System.Text.Encoding]::UTF8.GetBytes($jsonResponse)
                        $response.ContentType = "application/json; charset=utf-8"
                        $response.ContentLength64 = $buffer.Length
                        $response.OutputStream.Write($buffer, 0, $buffer.Length)
                        
                        Write-Host "💾 TODO保存完了: $($params.items.Count)件" -ForegroundColor Green
                    }
                }
                
                "/api/tool/todo_get" {
                    if ($request.HttpMethod -eq "POST") {
                        $todos = $todoManager.LoadTodos()
                        
                        # データ変換
                        $todoData = @()
                        foreach ($todo in $todos) {
                            $todoData += @{
                                id = $todo.Id
                                timestamp = $todo.Timestamp.ToString("yyyy-MM-ddTHH:mm:ss")
                                items = $todo.Items
                                category = $todo.Category
                                priority = $todo.Priority
                            }
                        }
                        
                        $responseObj = @{
                            success = $true
                            data = $todoData
                            count = $todos.Count
                        }
                        
                        $jsonResponse = $responseObj | ConvertTo-Json -Depth 10
                        $buffer = [System.Text.Encoding]::UTF8.GetBytes($jsonResponse)
                        $response.ContentType = "application/json; charset=utf-8"
                        $response.ContentLength64 = $buffer.Length
                        $response.OutputStream.Write($buffer, 0, $buffer.Length)
                        
                        Write-Host "📖 TODO取得: $($todos.Count)件" -ForegroundColor Cyan
                    }
                }
                
                default {
                    $response.StatusCode = 404
                    $errorMsg = "Endpoint not found: $url"
                    $buffer = [System.Text.Encoding]::UTF8.GetBytes($errorMsg)
                    $response.OutputStream.Write($buffer, 0, $buffer.Length)
                    Write-Host "❌ 404: $url" -ForegroundColor Red
                }
            }
        } catch {
            Write-Host "⚠️ Error: $($_.Exception.Message)" -ForegroundColor Red
            $response.StatusCode = 500
            $errorMsg = "Internal Server Error: $($_.Exception.Message)"
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($errorMsg)
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        } finally {
            $response.Close()
        }
    }
} catch {
    Write-Host "❌ サーバー起動エラー: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    if ($listener -and $listener.IsListening) {
        $listener.Stop()
        Write-Host "🛑 サーバー停止" -ForegroundColor Yellow
    }
}
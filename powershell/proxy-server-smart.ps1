# スマートTODO MCP サーバー - 修正版

function INIT-TODO {
    Add-Type -AssemblyName System.Net
    Add-Type -AssemblyName System.Web
    
    Add-Type @"
using System; using System.Collections.Generic; using System.IO; using System.Text.Json; using System.Text.Json.Serialization;
public class Todo { 
    [JsonPropertyName("id")] public long Id { get; set; }
    [JsonPropertyName("timestamp")] public DateTime Timestamp { get; set; }
    [JsonPropertyName("items")] public List<string> Items { get; set; } = new List<string>();
    [JsonPropertyName("category")] public string Category { get; set; } = "general";
    [JsonPropertyName("priority")] public string Priority { get; set; } = "medium";
}
public class TodoMgr {
    const string F = "todos.json";
    public List<Todo> Load() => File.Exists(F) ? JsonSerializer.Deserialize<List<Todo>>(File.ReadAllText(F)) ?? new List<Todo>() : new List<Todo>();
    public void Save(List<Todo> t) => File.WriteAllText(F, JsonSerializer.Serialize(t, new JsonSerializerOptions { WriteIndented = true }));
    public Todo Create(List<string> items, string cat = "general", string pri = "medium") => new Todo { Id = DateTimeOffset.Now.ToUnixTimeMilliseconds(), Timestamp = DateTime.Now, Items = items ?? new List<string>(), Category = cat, Priority = pri };
}
public class LLM {
    public static (string content, bool tool, List<string> items) Parse(string msg) {
        var items = new List<string>();
        if (msg.Contains("週末") || msg.Contains("予定")) return ("週末の予定を整理しましょう！やりたいことを教えてください。", false, items);
        if (msg.Contains("洗濯") || msg.Contains("買い物") || msg.Contains("映画") || msg.Contains("読書")) {
            if (msg.Contains("映画")) items.Add("友達と映画を見る");
            if (msg.Contains("洗濯")) items.Add("洗濯をする");
            if (msg.Contains("買い物")) items.Add("買い物に行く");
            if (msg.Contains("読書")) items.Add("読書をする");
            return ("以下のタスクを整理しました：\n" + string.Join("\n", items.ConvertAll(i => "• " + i)) + "\n\n優先順位を付けて保存しますね。", true, items);
        }
        return ("どのようなことを整理したいですか？", false, items);
    }
}
"@
    
    $global:tm = [TodoMgr]::new()
    $global:ls = [System.Net.HttpListener]::new()
    $ls.Prefixes.Add("http://*:8080/")
    $ls.Start()
    
    Write-Host "⚡ TODO MCP サーバー起動完了 http://*:8080/" -ForegroundColor Green
    Write-Host "📝 http://localhost:8080/todo-app.html でアクセス" -ForegroundColor Cyan
    Write-Host "🛑 Ctrl+C で終了" -ForegroundColor Red
}

function SET-CORS($rs) {
    $rs.AddHeader("Access-Control-Allow-Origin", "*")
    $rs.AddHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
    $rs.AddHeader("Access-Control-Allow-Headers", "Content-Type")
    $rs.ContentType = "application/json; charset=utf-8"
}

function SEND-JSON($rs, $obj) {
    $json = ConvertTo-Json $obj -Depth 10
    $buf = [System.Text.Encoding]::UTF8.GetBytes($json)
    $rs.ContentLength64 = $buf.Length
    $rs.OutputStream.Write($buf, 0, $buf.Length)
    $rs.OutputStream.Flush()
}

function SEND-HTML($rs, $file) {
    if (Test-Path $file) {
        $html = Get-Content $file -Raw -Encoding UTF8
        $buf = [System.Text.Encoding]::UTF8.GetBytes($html)
        $rs.ContentType = "text/html; charset=utf-8"
        $rs.ContentLength64 = $buf.Length
        $rs.OutputStream.Write($buf, 0, $buf.Length)
        $rs.OutputStream.Flush()
        $rs.StatusCode = 200
    } else {
        $rs.StatusCode = 404
        $errorObj = @{ error = "File not found: $file" }
        SEND-JSON $rs $errorObj
    }
}

function HANDLE-CHAT($rq, $rs) {
    $reader = [System.IO.StreamReader]::new($rq.InputStream, $rq.ContentEncoding)
    $body = $reader.ReadToEnd() | ConvertFrom-Json
    $reader.Close()
    
    $msg = $body.messages[-1].content
    $result = [LLM]::Parse($msg)
    
    $response = @{
        type = "message"
        role = "assistant"
        content = @(@{ type = "text"; text = $result.Item1 })
    }
    
    if ($result.Item2) {
        $toolArgs = @{ items = $result.Item3; category = "weekend"; priority = "medium" }
        $response.tool_calls = @(@{
            type = "function"
            function = @{
                name = "todo_save"
                arguments = ($toolArgs | ConvertTo-Json -Compress)
            }
        })
    }
    
    SEND-JSON $rs $response
    Write-Host "💬 Chat: $($msg.Substring(0, [Math]::Min(30, $msg.Length)))..." -ForegroundColor Yellow
}

function HANDLE-SAVE($rq, $rs) {
    $reader = [System.IO.StreamReader]::new($rq.InputStream, $rq.ContentEncoding)
    $body = $reader.ReadToEnd() | ConvertFrom-Json
    $reader.Close()
    
    $params = $body.params
    $todo = $global:tm.Create($params.items, $params.category, $params.priority)
    $todos = $global:tm.Load()
    $todos.Add($todo)
    $global:tm.Save($todos)
    
    $responseObj = @{
        success = $true
        message = "$($params.items.Count)個のタスクを保存しました！"
        data = @{
            id = $todo.Id
            timestamp = $todo.Timestamp.ToString("yyyy-MM-ddTHH:mm:ss")
            items = $todo.Items
            category = $todo.Category
            priority = $todo.Priority
        }
    }
    
    SEND-JSON $rs $responseObj
    Write-Host "💾 保存: $($params.items.Count)件" -ForegroundColor Green
}

function HANDLE-GET($rs) {
    $todos = $global:tm.Load()
    $todoArray = @()
    foreach ($todo in $todos) {
        $todoArray += @{
            id = $todo.Id
            timestamp = $todo.Timestamp.ToString("yyyy-MM-ddTHH:mm:ss")
            items = $todo.Items
            category = $todo.Category
            priority = $todo.Priority
        }
    }
    
    $responseObj = @{
        success = $true
        data = $todoArray
        count = $todos.Count
    }
    
    SEND-JSON $rs $responseObj
    Write-Host "📖 取得: $($todos.Count)件" -ForegroundColor Cyan
}

function HANDLE-REQUEST($ct) {
    $rq = $ct.Request
    $rs = $ct.Response
    
    SET-CORS $rs
    
    if ($rq.HttpMethod -eq "OPTIONS") {
        $rs.StatusCode = 200
        $rs.ContentLength64 = 0
        $rs.Close()
        return
    }
    
    $path = $rq.Url.LocalPath
    Write-Host "📝 $($rq.HttpMethod) $path" -ForegroundColor Gray
    
    try {
        switch ($path) {
            "/todo-app.html" { SEND-HTML $rs "todo-app.html" }
            "/api/chat" { if ($rq.HttpMethod -eq "POST") { HANDLE-CHAT $rq $rs } }
            "/api/tool/todo_save" { if ($rq.HttpMethod -eq "POST") { HANDLE-SAVE $rq $rs } }
            "/api/tool/todo_get" { if ($rq.HttpMethod -eq "POST") { HANDLE-GET $rs } }
            default { 
                $rs.StatusCode = 404
                $errorObj = @{ error = "Endpoint not found: $path" }
                SEND-JSON $rs $errorObj
                Write-Host "❌ 404: $path" -ForegroundColor Red
            }
        }
    } catch {
        $rs.StatusCode = 500
        $errorObj = @{ error = "Server error: $($_.Exception.Message)" }
        SEND-JSON $rs $errorObj
        Write-Host "⚠️ Error: $($_.Exception.Message)" -ForegroundColor Red
    } finally {
        $rs.Close()
    }
}

function RUN-SERVER {
    while ($global:ls.IsListening) {
        try {
            $ct = $global:ls.GetContext()
            HANDLE-REQUEST $ct
        } catch {
            Write-Host "🚨 Server error: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

try {
    INIT-TODO
    RUN-SERVER
} catch {
    Write-Host "❌ 起動エラー: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    if ($global:ls -and $global:ls.IsListening) {
        $global:ls.Stop()
        Write-Host "🛑 サーバー停止" -ForegroundColor Yellow
    }
}
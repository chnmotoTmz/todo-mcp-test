function INIT-TODO {
    Add-Type -AssemblyName System.Net

    # C#は最小限：LLM処理のみ
    Add-Type @"
using System;
using System.Collections.Generic;

public class LLM 
{
    public static LLMResult Parse(string message) 
    {
        var items = new List<string>();
        var needsTool = false;
        var content = "";
        
        if (message.Contains("週末") || message.Contains("予定")) 
        {
            content = "週末の予定を整理しましょう！やりたいことを教えてください。";
        }
        else if (message.Contains("洗濯") || message.Contains("買い物") || message.Contains("映画") || message.Contains("読書")) 
        {
            if (message.Contains("映画")) items.Add("友達と映画を見る");
            if (message.Contains("洗濯")) items.Add("洗濯をする");
            if (message.Contains("買い物")) items.Add("買い物に行く");
            if (message.Contains("読書")) items.Add("読書をする");
            
            content = "以下のタスクを整理しました：\n";
            foreach (var item in items)
            {
                content += "• " + item + "\n";
            }
            content += "\n優先順位を付けて保存しますね。";
            needsTool = true;
        }
        else 
        {
            content = "どのようなことを整理したいですか？";
        }
        
        return new LLMResult { Content = content, NeedsTool = needsTool, Items = items };
    }
}

public class LLMResult
{
    public string Content { get; set; }
    public bool NeedsTool { get; set; }
    public List<string> Items { get; set; }
    
    public LLMResult()
    {
        Items = new List<string>();
    }
}
"@
    
    $global:ls = [System.Net.HttpListener]::new()
    $ls.Prefixes.Add("http://*:3000/")
    $ls.Start()
    
    Write-Host "⚡ TODO サーバー起動完了 http://*:3000/" -ForegroundColor Green
    Write-Host "📝 http://localhost:3000/todo-app.html でアクセス" -ForegroundColor Cyan
    Write-Host "💾 データはJavaScript側で管理" -ForegroundColor Yellow
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
        SEND-JSON $rs @{ error = "File not found: $file" }
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
        content = @(@{ type = "text"; text = $result.Content })
    }
    
    if ($result.NeedsTool) {
        $toolArgs = @{ 
            items = @($result.Items)
            category = "weekend"
            priority = "medium"
            timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
            id = [DateTimeOffset]::Now.ToUnixTimeMilliseconds()
        }
        $response.tool_calls = @(@{
            type = "function"
            function = @{
                name = "todo_save"
                arguments = ($toolArgs | ConvertTo-Json -Compress)
            }
        })
    }
    
    SEND-JSON $rs $response
    Write-Host "💬 LLM処理: $($msg.Substring(0, [Math]::Min(30, $msg.Length)))..." -ForegroundColor Yellow
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
            "/api/chat" { 
                if ($rq.HttpMethod -eq "POST") { 
                    HANDLE-CHAT $rq $rs 
                } else {
                    $rs.StatusCode = 405
                    SEND-JSON $rs @{ error = "Method not allowed" }
                }
            }
            default { 
                $rs.StatusCode = 404
                SEND-JSON $rs @{ error = "Endpoint not found: $path" }
                Write-Host "❌ 404: $path" -ForegroundColor Red
            }
        }
    } catch {
        $rs.StatusCode = 500
        SEND-JSON $rs @{ error = "Server error: $($_.Exception.Message)" }
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
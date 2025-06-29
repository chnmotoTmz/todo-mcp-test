# 📚 PowerShell+JavaScript プラットフォーム 学習ガイド

## 🎯 このガイドの目的

**美しいPowerShellコード**と**効果的な責任分担設計**を学習し、実用的なアプリケーション開発スキルを段階的に習得する。

## 📖 学習コンテンツ構成

### 📁 ファイル構成と役割

```
learning-platform/
├── proxy.ps1              # 📖 教科書: PowerShell美学の完全実装
├── todo-app.html          # 📖 教科書: JavaScript責任分担の模範
├── README.md              # 📋 概要とアーキテクチャ説明
├── LEARNING_GUIDE.md      # 📚 このファイル: 段階的学習方法
└── examples/              # 🧪 実習用例題集
    ├── step1-basic.md     # 基本動作確認
    ├── step2-customize.md # カスタマイズ実習
    └── step3-advanced.md  # 応用開発
```

## 🏃‍♂️ 学習の進め方

### Phase 1: 理解フェーズ (2時間)

#### 🔍 コード観察 (30分)
1. **proxy.ps1を読む**
   - 関数分割の美学を観察
   - 短縮命名パターンの理解
   - グローバル変数の使用方法

2. **todo-app.html を読む**
   - JavaScript責任範囲の確認
   - ローカルストレージ活用方法
   - DOM操作パターンの学習

#### ⚙️ 動作確認 (30分)
```powershell
# 1. サーバー起動
.\proxy.ps1

# 2. ブラウザテスト
# http://localhost:3000/todo-app.html
# 「洗濯、買い物、読書もしたい」を入力

# 3. 動作フロー確認
# ユーザー入力 → JavaScript → PowerShell → C#LLM → JavaScript表示
```

#### 📐 設計理解 (60分)
```
責任分担の確認:
✅ PowerShell: LLM処理、HTTP サーバー、CORS
✅ JavaScript: GUI操作、データ表示、ローカル保存
❌ 混在: 絶対に責任を越境させない
```

### Phase 2: 実習フェーズ (4時間)

#### 🎨 美学実習: コード改善 (90分)

**実習1: 関数分割を実践**
```powershell
# 新しい機能を追加する際の正しい分割方法
function HANDLE-WEATHER($rq, $rs) {
    # 天気予報API呼び出し処理
    $weatherData = GET-WEATHER-DATA
    SEND-JSON $rs $weatherData
}

function GET-WEATHER-DATA {
    # 実際のAPI呼び出し
    return @{ weather = "晴れ"; temperature = "25度" }
}
```

**実習2: 短縮命名を実践**
```powershell
# 冗長命名を短縮命名に変換する練習
$weatherApiRequestConfiguration = @{}  # ❌
$wtApi = @{}                           # ✅

$userInputProcessingResult = ""        # ❌  
$userResult = ""                       # ✅
```

**実習3: グローバル変数を実践**
```powershell
# 共有データの適切な管理
$global:config = @{
    port = 3000
    apiKeys = @{}
}

function INIT-CONFIG {
    $global:config.apiKeys.weather = "your-api-key"
}
```

#### 🔧 機能拡張実習 (90分)

**実習4: 新パターン追加**
```powershell
# LLMクラスに買い物パターン追加
else if (message.Contains("買い物") && message.Contains("リスト")) 
{
    if (message.Contains("牛乳")) items.Add("牛乳を買う");
    if (message.Contains("パン")) items.Add("パンを買う");
    // パターン追加
}
```

**実習5: UI機能追加**
```javascript
// カテゴリ別表示機能
function showTodosByCategory(category) {
    const filtered = todos.filter(todo => todo.category === category);
    // 表示処理
}

// 検索機能
function searchTodos(keyword) {
    const results = todos.filter(todo => 
        todo.items.some(item => item.includes(keyword))
    );
    // 結果表示
}
```

#### 🌐 外部API統合実習 (60分)

**実習6: 天気API統合**
```powershell
function HANDLE-WEATHER-API($location) {
    $apiUrl = "https://api.openweathermap.org/data/2.5/weather"
    $params = @{
        q = $location
        appid = $global:config.apiKeys.weather
    }
    
    $weather = Invoke-RestMethod -Uri $apiUrl -Body $params
    return @{
        location = $location
        temperature = $weather.main.temp
        description = $weather.weather[0].description
    }
}
```

### Phase 3: 応用フェーズ (6時間)

#### 🏗️ 独自アプリ開発 (360分)

**プロジェクト例: 日記管理システム**

1. **設計段階 (60分)**
   ```
   PowerShell責任: 日記保存、検索、AI要約
   JavaScript責任: エディタUI、カレンダー表示
   ```

2. **PowerShell実装 (120分)**
   ```powershell
   function INIT-DIARY { /* 初期化 */ }
   function SAVE-DIARY($entry) { /* 保存 */ }
   function SEARCH-DIARY($keyword) { /* 検索 */ }
   function AI-SUMMARIZE($entries) { /* AI要約 */ }
   ```

3. **JavaScript実装 (120分)**
   ```javascript
   class DiaryApp {
       constructor() { /* UI初期化 */ }
       saveEntry(text) { /* サーバー送信 */ }
       displayEntries(entries) { /* 表示 */ }
   }
   ```

4. **統合テスト (60分)**
   - 機能動作確認
   - エラーハンドリング
   - ユーザビリティ改善

## 📊 学習進捗チェックリスト

### ✅ Phase 1: 理解フェーズ
- [ ] PowerShell美学（関数分割・短縮命名・グローバル変数）を理解
- [ ] 責任分担設計を理解
- [ ] 基本動作を確認
- [ ] アーキテクチャ図を描ける

### ✅ Phase 2: 実習フェーズ  
- [ ] 美しいPowerShell関数を3つ以上書ける
- [ ] LLMパターンを2つ以上追加できる
- [ ] JavaScript UI機能を3つ以上追加できる
- [ ] 外部API統合を1つ以上実装できる

### ✅ Phase 3: 応用フェーズ
- [ ] 独自アプリのアーキテクチャ設計ができる
- [ ] PowerShell側の完全実装ができる
- [ ] JavaScript側の完全実装ができる
- [ ] エラーハンドリングとテストができる

## 🎓 学習成果物

### 提出物リスト
1. **カスタマイズ版TODO**: オリジナル機能追加
2. **コード解説文書**: 美学ポイントの説明
3. **独自アプリ**: 完全にオリジナルなアプリケーション
4. **学習レポート**: 習得したスキルと気づき

### 評価基準
- **美学度**: PowerShell美学の実践度
- **分離度**: 責任分担の徹底度  
- **実用性**: 実際に使える機能レベル
- **創造性**: オリジナリティと発想力

## 🚀 次のステップ

### 上級者向け発展
1. **プラットフォーム化**: 汎用フレームワーク開発
2. **コミュニティ貢献**: 教材改善・事例追加
3. **指導者育成**: 他者への指導・メンタリング

### キャリア活用
- **PowerShell エキスパート**: 企業システム自動化
- **フルスタック開発者**: Webアプリケーション開発
- **アーキテクト**: システム設計・技術選定

## 💡 学習のコツ

### 効果的な学習方法
1. **手を動かす**: コードを書かずに理解しない
2. **小さく始める**: 完璧を求めず動くものから
3. **美学を意識**: ただ動くだけでなく美しく
4. **責任を守る**: 設計原則を絶対に守る

### よくある間違い
- ❌ PowerShellでDOM操作しようとする
- ❌ JavaScriptで外部API直接呼び出し  
- ❌ 関数分割せずに長大なコード作成
- ❌ 冗長な変数名で可読性低下

---

**🎯 美しいコードを書く習慣が、優秀な開発者への第一歩**
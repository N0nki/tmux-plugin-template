# 設計

## 目的

この設計は、`tmux display-popup + fzf` を使った検索・選択フローを汎用化した tmux プラグインテンプレートを定義する。
テンプレート本体は共通フローと実行基盤のみを提供し、個別ユースケースは `profile` として差し込む。

## 設計原則

- core は汎用フローだけを持つ
- profile はユースケース固有のロジックだけを持つ
- shell ベースで小さく保つ
- tmux option で最低限の挙動を制御できるようにする
- エラーは popup 内で完結して確認できるようにする
- 1 回の選択フローを明確な段階に分ける

## システム構成

テンプレートは 3 層で構成する。

### 1. tmux layer

tmux plugin として読み込まれ、キーバインドと popup 起動を担当する。

- tmux option の読み取り
- key binding の登録
- popup のサイズ指定
- 実行対象 profile の指定

### 2. core layer

popup 内で実行される共通ロジックを担当する。

- 依存関係チェック
- profile の読み込み
- source, transform, fzf, resolve, action の制御
- エラーハンドリング
- clipboard や cache などの共通ヘルパー

### 3. profile layer

個別ユースケースを実装する。

- データソース定義
- `fzf` 表示用整形
- 選択値の解決
- 最終アクションの上書きや補助情報の定義

## ディレクトリ構成

初期構成は以下を想定する。

```text
.
├── doc/
│   ├── requirements.ja.md
│   ├── requirements.md
│   └── design.ja.md
├── plugin/
│   └── tmux-plugin-template.tmux
├── scripts/
│   ├── run.sh
│   ├── core/
│   │   ├── actions.sh
│   │   ├── cache.sh
│   │   ├── clipboard.sh
│   │   ├── errors.sh
│   │   ├── fzf.sh
│   │   ├── profile.sh
│   │   ├── tmux_options.sh
│   │   └── validate.sh
│   └── profiles/
│       └── example.sh
└── README.md
```

## 実行フロー

1 回の popup フローは以下で構成する。

```text
tmux key binding
  -> display-popup
  -> scripts/run.sh --profile <name> --target-pane <pane_id>
  -> core: 設定読込
  -> core: 依存確認
  -> core: profile 読込
  -> profile_source
  -> profile_transform
  -> fzf
  -> profile_resolve
  -> action
```

各段階の責務は以下の通り。

- `profile_source`: 元データを標準出力へ返す
- `profile_transform`: `fzf` に流す行フォーマットへ変換する
- `fzf`: 行選択を行う
- `profile_resolve`: 選択行から action に必要な値を生成する
- `action`: 値を clipboard, send-keys, stdout, custom command のいずれかに渡す

`send-keys` 用の送信先 pane は popup 自身の pane ではなく、popup を開いた元の pane を使う。
そのため tmux layer は popup 起動時に `#{pane_id}` を解決し、`run.sh` に明示的に渡す必要がある。

## Profile 契約

profile は `scripts/profiles/*.sh` に配置する shell スクリプトとし、規約ベースで関数を提供する。

### 必須関数

```bash
profile_source
profile_transform
profile_resolve
```

### 任意関数

```bash
profile_check_dependencies
profile_preview
profile_action
profile_on_error
profile_cache_key
profile_cache_get
profile_is_cacheable
```

### 必須関数の契約

#### `profile_source`

- 入力: なし
- 出力: 生データを標準出力へ出す
- 失敗時: 非 0 で終了し、標準エラーに理由を出す

#### `profile_transform`

- 入力: `profile_source` の標準出力
- 出力: `fzf` に流す行データ
- 1 行は表示列と内部値を区切り文字で持てる
- 初期実装ではタブ区切りを標準とする

#### `profile_resolve`

- 入力: `fzf` で選ばれた 1 行
- 出力: action に渡す最終値
- 失敗時: 非 0 で終了し、標準エラーに理由を出す

### 任意関数の役割

#### `profile_check_dependencies`

- profile 固有の依存コマンドを検証する
- core の共通依存チェック後に呼ぶ

#### `profile_preview`

- 入力: `fzf` でハイライト中の 1 行
- 出力: preview に表示する内容
- core はこの関数を呼ぶ小さなラッパーを経由して `fzf --preview` に接続する
- 生のコマンド文字列を profile から返させないことで、引用や shell 展開の曖昧さを減らす

#### `profile_action`

- profile 固有の action を完全に制御したい場合に使う
- 定義されない場合は core の共通 action を使う

#### `profile_on_error`

- profile 固有の補助メッセージを表示したい場合に使う

#### `profile_cache_key`

- profile ごとの cache 識別子を返す
- 未定義なら profile 名を使う

#### `profile_cache_get`

- cache に保存してよいデータだけを標準出力へ返す
- 未定義なら core は profile のデータを cache しない

#### `profile_is_cacheable`

- cache 可能なら `0` を返す
- 未定義なら非 cacheable とみなす

## 行フォーマット

初期実装では `fzf` に渡す行をタブ区切りで扱う。

例:

```text
display_name<TAB>description<TAB>raw_id
```

方針は以下とする。

- 左側の列は表示用
- 最後の列は `resolve` に必要な内部値として使える
- `fzf --with-nth` で表示列を制御する
- `fzf --delimiter` はデフォルトでタブに固定する
- profile はタブと改行を含む値をそのまま行フォーマットに埋め込まない
- 必要なら識別子のみを行に載せ、詳細は `resolve` または `preview` 側で再取得する

この方式により、表示用テキストと内部識別子を分離できる。

## Action モデル

action は core が提供する共通 action を基本とする。

### `stdout`

- `profile_resolve` の結果をそのまま出力する
- 最も単純なデバッグ用動作として使う

### `clipboard`

- `pbcopy`, `xclip`, `clip.exe` を吸収する
- auto-clear 秒数を設定できる

### `send-keys`

- target pane は popup 起動元の pane を使う
- `TMUX_POPUP_TEMPLATE_TARGET_PANE` のような明示的な変数で core に渡す
- 必要なら tmux option で上書きできる余地を持つ

### `command`

- `profile_resolve` の結果を引数として任意コマンドへ渡す
- 初期実装では安全性のため、1 引数として渡す設計に寄せる
- この action は将来拡張とし、MVP には含めない

## tmux Option 設計

初期バージョンでは、少なくとも以下を持つ。

```text
@popup-template-key
@popup-template-profile
@popup-template-popup-width
@popup-template-popup-height
@popup-template-prompt
@popup-template-action
@popup-template-auto-clear-seconds
@popup-template-use-cache
@popup-template-cache-age
```

### 役割

- `@popup-template-key`: 起動キー
- `@popup-template-profile`: 実行する profile 名
- `@popup-template-popup-width`: popup 幅
- `@popup-template-popup-height`: popup 高さ
- `@popup-template-prompt`: `fzf` prompt
- `@popup-template-action`: `stdout`, `clipboard`, `send-keys`, `command`
- `@popup-template-auto-clear-seconds`: clipboard auto-clear 秒数
- `@popup-template-use-cache`: cache の有効化
- `@popup-template-cache-age`: cache 有効期間

profile 固有の option は profile 名を prefix にして追加する。

例:

```text
@popup-template-example-file
@popup-template-example-command
```

## Cache 設計

cache は初期実装で optional とする。

### 目的

- CLI 実行コストが高い source を再実行しない
- popup の体感速度を改善する

### 方針

- cache は profile が安全と宣言したデータだけを対象にする
- 保存先は `/tmp` を使う
- ファイル名は user と profile 名で分離する
- 書き込みは `mktemp + chmod 600 + mv` の流れで安全に行う
- cache 無効時は一切使わない
- profile が `profile_cache_get` を実装しない限り、core は何も cache しない

### 例

```text
/tmp/tmux-popup-template-<user>-<profile>.cache
```

## エラーハンドリング設計

エラー処理は core に寄せる。

### ルール

- 失敗した段階を明示する
- エラー文は popup 内に表示する
- すぐ終了せず、キー入力で閉じられるようにする
- 必要なら profile 補助メッセージを追加表示する

### エラー表示例

```text
Error in profile_resolve
<stderr message>

Press any key to close...
```

## 依存関係設計

core が最低限チェックする。

- `tmux`
- `fzf`

追加で action や profile ごとの依存をチェックする。

- `clipboard` action: `pbcopy` or `xclip` or `clip.exe`
- profile 固有 CLI: `profile_check_dependencies` で検証

## セキュリティ方針

- shell 展開に依存した危険な文字列結合を避ける
- 可能な限り配列や 1 引数渡しでコマンドを組み立てる
- cache に秘匿値を保存しないことを原則とする
- clipboard auto-clear は共通 action で提供する
- send-keys は誤送信の危険があるため、README に注意を明記する

## MVP 設計

最初に作る範囲は以下とする。

### 含めるもの

- 単一 profile 起動
- `source -> transform -> fzf -> resolve -> action` の共通フロー
- `stdout`, `clipboard`, `send-keys` の 3 action
- popup サイズと prompt の tmux option
- 依存不足と実行失敗の popup 表示
- サンプル profile を 1 つ同梱

### 含めないもの

- 複数 profile の同時登録
- 高度な preview カスタマイズ
- `command` action
- cache
- multi-select
- 複数段階のフロー

## サンプル Profile 案

最初の example profile はファイルまたはコマンド出力を選択できるだけの簡単なものがよい。

例:

- `cat <file>` の行一覧を選ぶ
- `tmux list-sessions` の結果からセッションを選ぶ

このサンプルの目的は、テンプレートの拡張点を最小コストで示すことにある。

## 実装順序

1. `plugin/tmux-plugin-template.tmux` を作る
2. `scripts/run.sh` に共通フローを実装する
3. `scripts/core/` に option, error, clipboard, action を分離する
4. `scripts/profiles/example.sh` を作る
5. README に profile 作成方法を書く
6. 必要なら cache と custom action を次段で追加する

## 将来拡張

- 複数 profile の登録
- preview hook
- custom command action
- multi-select
- JSON Lines のような構造化行フォーマット
- profile metadata による自己記述

## 判断

このテンプレートでは、設定ファイル駆動よりも shell 関数ベースの profile を採用する。
理由は以下の通り。

- shell だけで完結しやすい
- source, resolve, action の柔軟性が高い
- tmux plugin の実装規模に対して十分に単純
- `tmux-op-secure` のような既存 shell 実装を移植しやすい

初期設計では、柔軟性よりも小ささと理解容易性を優先する。

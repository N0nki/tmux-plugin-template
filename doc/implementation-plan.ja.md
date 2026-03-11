# 実装タスク

## 方針

MVP を崩さずに進めるため、実装は土台となる helper 群を先に固め、その上に `run.sh`、action、example profile を載せる順序で進める。
また、MVP 外の機能は初期実装の作業列から外し、後段タスクとして明示的に分離する。

## Phase 1

- `plugin/tmux-plugin-template.tmux` を作成する
- tmux option の既定値を決める
- key binding から `display-popup` で `scripts/run.sh --profile <name> --target-pane <pane_id>` を起動できるようにする

## Phase 2

- `scripts/core/tmux_options.sh` を作る
- tmux option 読み取り関数と既定値解決を実装する
- `popup width`, `popup height`, `prompt`, `action`, `auto-clear-seconds`, `profile` を扱えるようにする

## Phase 3

- `scripts/core/validate.sh` を作る
- 共通依存 `tmux`, `fzf` を検証する
- action ごとの依存チェックを追加する
- profile 側の `profile_check_dependencies` を呼べるようにする

## Phase 4

- `scripts/core/errors.sh` を作る
- 段階名付きで失敗を表示する関数を実装する
- `profile_on_error` があれば追記表示する
- popup を即終了させない待機関数を共通化する

## Phase 5

- `scripts/core/profile.sh` を作る
- `scripts/profiles/<name>.sh` を安全に読み込む
- 必須関数 `profile_source`, `profile_transform`, `profile_resolve` の存在チェックを実装する
- 任意関数の有無を判定できる helper を入れる

## Phase 6

- `scripts/core/fzf.sh` を作る
- タブ区切り行を前提に `fzf` 実行関数を作る
- `--prompt`, `--delimiter`, `--with-nth` の既定値を持たせる

## Phase 7

- `scripts/core/clipboard.sh` を作る
- `pbcopy`, `xclip`, `clip.exe` の抽象化を実装する
- auto-clear をバックグラウンドで処理する

## Phase 8

- `scripts/core/actions.sh` を作る
- `stdout` action を実装する
- `clipboard` action を `clipboard.sh` 経由で実装する
- `send-keys` action を実装する
- profile 独自の `profile_action` があればそちらを優先する

## Phase 9

- `scripts/run.sh` を作成する
- 引数 `--profile` と `--target-pane` を解釈する
- core helper を読み込み、全体フロー `source -> transform -> fzf -> resolve -> action` を統括する
- 失敗時に popup 内でエラー表示してキー入力待ちする共通処理を入れる

## Phase 10

- `scripts/profiles/example.sh` を作る
- 最初のサンプル profile を 1 つ実装する
- 例は `tmux list-sessions` か単純なファイル行選択のどちらかに絞る
- `source`, `transform`, `resolve` の最小実装例として成立させる

## Phase 11

- `README.md` を作る
- インストール方法を書く
- 最低限の設定例を書く
- tmux option 一覧を書く
- profile の作り方を書く
- サンプル profile の使い方を書く
- `send-keys` の注意点を書く

## Phase 12

- 手動確認を行う
- popup が開くことを確認する
- `fzf` 選択が動くことを確認する
- `stdout`, `clipboard`, `send-keys` がそれぞれ動くことを確認する
- 依存不足と profile エラーが popup 内で見えることを確認する

## 最初のマイルストーン

以下が揃えば、cache なしの MVP は一通り動かせる。

1. `plugin/tmux-plugin-template.tmux`
2. `scripts/core/tmux_options.sh`
3. `scripts/core/validate.sh`
4. `scripts/core/errors.sh`
5. `scripts/core/profile.sh`
6. `scripts/core/fzf.sh`
7. `scripts/core/clipboard.sh`
8. `scripts/core/actions.sh`
9. `scripts/run.sh`
10. `scripts/profiles/example.sh`

## 補足

- `run.sh` は helper の上に立つ統合点なので、先に stub だけ作ってもよいが、本実装は後ろに置く方が自然
- cache は MVP 外なので、実装開始時点ではファイルだけ作らず後段に回してよい
- `profile_preview` は設計上は存在するが MVP 外とし、初回実装タスクには含めない
- `command` action も MVP 外とし、実装タスクから外す

## MVP 後タスク

- `profile_preview` hook の実装
- `command` action の実装
- cache の実装
- 複数 profile 登録
- multi-select の検討

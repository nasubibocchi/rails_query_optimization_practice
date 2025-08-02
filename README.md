# Rails クエリ最適化 練習プロジェクト

RailsのActiveRecordにおける `joins`, `includes`, `preload`, `eager_load` の違いを理解し、N+1問題の解決とクエリ最適化のスキルを身につけるための練習プロジェクトです。

## 📚 学習内容

- `joins` + `merge` の使い方と特徴
- `includes` によるEager Loading
- `preload` の動作原理
- `eager_load` の使用場面
- N+1問題の特定と解決
- クエリパフォーマンスの最適化
- 実践的なパフォーマンス改善テクニック

## 🚀 セットアップ

詳細なセットアップ手順は [docs/setup.md](docs/setup.md) を参照してください。

```bash
git clone https://github.com/nasubibocchi/rails_query_optimization_practice.git
cd rails_query_optimization_practice
bundle install
rails db:setup
rails db:seed
```

## 📖 学習の進め方

1. **基礎概念の理解**: [docs/concepts.md](docs/concepts.md) で各メソッドの違いを学習
2. **基本練習**: [docs/basic_exercises.md](docs/basic_exercises.md) で基本的な使い方をマスター
3. **応用練習**: [docs/advanced_exercises.md](docs/advanced_exercises.md) で実践的な問題に挑戦
4. **解答確認**: `docs/solutions/` フォルダで解答例を確認

## 🗂️ データベース構成

このプロジェクトでは以下のモデルを使用しています：

```
User (ユーザー)
├── has_many :posts
└── has_many :comments

Category (カテゴリ)
└── has_many :posts

Post (記事)
├── belongs_to :user
├── belongs_to :category
├── has_many :comments
├── has_many :post_tags
└── has_many :tags, through: :post_tags

Comment (コメント)
├── belongs_to :user
└── belongs_to :post

Tag (タグ)
├── has_many :post_tags
└── has_many :posts, through: :post_tags

PostTag (中間テーブル)
├── belongs_to :post
└── belongs_to :tag
```

## 🔧 便利なコマンド

```bash
# Railsコンソール起動
rails console

# 生成されるSQLの確認
User.joins(:posts).to_sql

# クエリのEXPLAIN実行
User.joins(:posts).explain

# サンプルデータの再生成
rails db:seed:replant
```

## 📝 練習問題の取り組み方

1. まず自分で考えて解答を作成
2. 実際にRailsコンソールで動作確認
3. 生成されるSQLを確認
4. 解答例と比較検討
5. パフォーマンスの違いを測定

## 🎯 学習目標

このプロジェクトを完了すると、以下のスキルが身につきます：

- [ ] 各クエリメソッドの特徴と使い分けができる
- [ ] N+1問題を特定し、適切に解決できる
- [ ] SQLクエリを意識したコードが書ける
- [ ] パフォーマンス問題を診断し、改善できる
- [ ] 実践的なクエリ最適化テクニックを活用できる

## 📂 ファイル構成

- `docs/concepts.md` - 基礎概念の説明
- `docs/basic_exercises.md` - 基本練習問題
- `docs/advanced_exercises.md` - 応用練習問題  
- `docs/solutions/basic_solutions.md` - 基本問題の解答例
- `docs/solutions/advanced_solutions.md` - 応用問題の解答例

## 🤝 貢献

練習問題の改善案や新しい問題のアイデアがあれば、ぜひIssueやPull Requestでお知らせください！

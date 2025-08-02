# セットアップガイド

## 前提条件

- Ruby 3.0+
- Rails 7.0+
- PostgreSQL
- Git

## プロジェクト作成

```bash
rails new rails_query_optimization_practice -d postgresql
cd rails_query_optimization_practice
```

## モデル生成

```bash
# ユーザーモデル
rails generate model User name:string email:string status:string

# カテゴリモデル
rails generate model Category name:string description:text

# 記事モデル
rails generate model Post title:string content:text status:string user:references category:references published_at:datetime

# コメントモデル
rails generate model Comment content:text status:string user:references post:references

# タグモデル
rails generate model Tag name:string

# 記事とタグの中間テーブル
rails generate model PostTag post:references tag:references
```

## モデルファイルの設定

### app/models/user.rb
```ruby
class User < ApplicationRecord
  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy
  
  scope :active, -> { where(status: 'active') }
  scope :inactive, -> { where(status: 'inactive') }
end
```

### app/models/category.rb
```ruby
class Category < ApplicationRecord
  has_many :posts, dependent: :destroy
end
```

### app/models/post.rb
```ruby
class Post < ApplicationRecord
  belongs_to :user
  belongs_to :category
  has_many :comments, dependent: :destroy
  has_many :post_tags, dependent: :destroy
  has_many :tags, through: :post_tags
  
  scope :published, -> { where(status: 'published') }
  scope :draft, -> { where(status: 'draft') }
  scope :recent, -> { order(created_at: :desc) }
end
```

### app/models/comment.rb
```ruby
class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :post
  
  scope :approved, -> { where(status: 'approved') }
  scope :pending, -> { where(status: 'pending') }
end
```

### app/models/tag.rb
```ruby
class Tag < ApplicationRecord
  has_many :post_tags, dependent: :destroy
  has_many :posts, through: :post_tags
end
```

### app/models/post_tag.rb
```ruby
class PostTag < ApplicationRecord
  belongs_to :post
  belongs_to :tag
end
```

## データベースセットアップ

```bash
rails db:migrate
```

## サンプルデータ作成

### db/seeds.rb
```ruby
# ユーザー作成
users = [
  User.create!(name: "田中太郎", email: "tanaka@example.com", status: "active"),
  User.create!(name: "佐藤花子", email: "sato@example.com", status: "active"),
  User.create!(name: "山田次郎", email: "yamada@example.com", status: "inactive")
]

# カテゴリ作成
categories = [
  Category.create!(name: "技術", description: "プログラミング関連"),
  Category.create!(name: "日常", description: "日常の出来事"),
  Category.create!(name: "旅行", description: "旅行記録")
]

# タグ作成
tags = [
  Tag.create!(name: "Ruby"),
  Tag.create!(name: "Rails"),
  Tag.create!(name: "JavaScript"),
  Tag.create!(name: "趣味"),
  Tag.create!(name: "仕事")
]

# 記事作成
posts = [
  Post.create!(title: "Railsの基礎", content: "Railsについて学びました", status: "published", user: users[0], category: categories[0], published_at: 1.week.ago),
  Post.create!(title: "今日の日記", content: "今日は良い天気でした", status: "published", user: users[1], category: categories[1], published_at: 3.days.ago),
  Post.create!(title: "下書き記事", content: "まだ書きかけです", status: "draft", user: users[0], category: categories[0]),
  Post.create!(title: "非アクティブユーザーの記事", content: "このユーザーは非アクティブです", status: "published", user: users[2], category: categories[2], published_at: 2.days.ago)
]

# 記事とタグの関連付け
PostTag.create!(post: posts[0], tag: tags[0]) # Ruby
PostTag.create!(post: posts[0], tag: tags[1]) # Rails
PostTag.create!(post: posts[1], tag: tags[3]) # 趣味
PostTag.create!(post: posts[3], tag: tags[4]) # 仕事

# コメント作成
Comment.create!(content: "とても参考になりました！", status: "approved", user: users[1], post: posts[0])
Comment.create!(content: "質問があります", status: "pending", user: users[0], post: posts[1])
Comment.create!(content: "いいですね", status: "approved", user: users[2], post: posts[0])
```

```bash
rails db:seed
```

## 動作確認

```bash
rails console
```

以下のコマンドで正常にデータが作成されているか確認：

```ruby
User.count
Post.count
Comment.count
Tag.count

# 関連付けの確認
User.first.posts.count
Post.first.comments.count
Post.first.tags.count
```

## トラブルシューティング

### PostgreSQLに接続できない場合

```bash
# PostgreSQLサービスの確認
brew services list | grep postgresql

# PostgreSQLサービス開始
brew services start postgresql
```

### データベース作成でエラーが出る場合

```bash
# データベースを再作成
rails db:drop
rails db:create
rails db:migrate
rails db:seed
```

## 次のステップ

セットアップが完了したら、[concepts.md](concepts.md) で基礎概念を学習しましょう。

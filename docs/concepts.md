# ActiveRecord クエリメソッドの基礎概念

## N+1問題とは

N+1問題は、関連データを取得する際に発生するパフォーマンス問題です。

```ruby
# N+1問題の例（悪い例）
posts = Post.limit(10)  # 1回のクエリ
posts.each do |post|
  puts post.user.name   # 各postに対して1回ずつクエリ（10回）
end
# 合計11回のクエリが実行される
```

## 各メソッドの特徴

### 1. `joins` + `merge`

**特徴:**
- SQL の INNER JOIN を実行
- 関連テーブルのデータは取得されない
- 関連テーブルの条件でフィルタリング可能
- N+1問題が発生する可能性がある

**実行されるSQL:**
```sql
SELECT "posts".* FROM "posts" 
INNER JOIN "users" ON "users"."id" = "posts"."user_id" 
WHERE "users"."status" = 'active'
```

**使用例:**
```ruby
# アクティブなユーザーの記事のみ取得（ユーザー情報は不要）
Post.joins(:user).merge(User.active)
```

### 2. `includes`

**特徴:**
- Eager Loading（一括読み込み）を実行
- 関連データも一緒に取得してメモリに保持
- N+1問題を解決
- 条件によってLEFT JOINまたは別クエリで実行される

**実行されるSQL（パターン1: JOIN）:**
```sql
SELECT "posts".* FROM "posts" 
LEFT OUTER JOIN "users" ON "users"."id" = "posts"."user_id"
```

**実行されるSQL（パターン2: 別クエリ）:**
```sql
SELECT "posts".* FROM "posts"
SELECT "users".* FROM "users" WHERE "users"."id" IN (1,2,3...)
```

**使用例:**
```ruby
# 記事とユーザーを一緒に取得
posts = Post.includes(:user)
posts.each { |post| puts post.user.name }  # 追加クエリなし
```

### 3. `preload`

**特徴:**
- 必ず別クエリで関連データを取得
- メインクエリと関連クエリが分離される
- 関連テーブルの条件をWHERE句に直接使用できない
- N+1問題を解決

**実行されるSQL:**
```sql
-- 1つ目のクエリ
SELECT "posts".* FROM "posts"
-- 2つ目のクエリ  
SELECT "users".* FROM "users" WHERE "users"."id" IN (1,2,3...)
```

**使用例:**
```ruby
# 必ず別クエリで関連データを取得
posts = Post.preload(:user)
posts.each { |post| puts post.user.name }  # 追加クエリなし
```

### 4. `eager_load`

**特徴:**
- 必ずLEFT OUTER JOINで関連データを取得
- 1つのクエリで全てのデータを取得
- 関連テーブルの条件をWHERE句で使用可能
- N+1問題を解決

**実行されるSQL:**
```sql
SELECT "posts".*, "users".* FROM "posts" 
LEFT OUTER JOIN "users" ON "users"."id" = "posts"."user_id"
```

**使用例:**
```ruby
# 必ずJOINで関連データを取得
posts = Post.eager_load(:user).where('users.status = ?', 'active')
```

## 使い分けガイド

| 目的 | 推奨メソッド | 理由 |
|------|------------|------|
| 関連テーブルでフィルタリング（関連データ不要） | `joins` + `merge` | 軽量、条件指定が柔軟 |
| 関連データも使用する（一般的） | `includes` | Rails が最適なクエリを選択 |
| 関連データ必要だが条件不要 | `preload` | クエリが分離されて明確 |
| JOINで条件指定したい | `eager_load` | 1つのクエリで完結 |

## パフォーマンスの測定方法

### クエリ数の確認
```ruby
# クエリ数をカウント
query_count = 0
ActiveSupport::Notifications.subscribe('sql.active_record') do
  query_count += 1
end

# ここでクエリを実行
posts = Post.includes(:user)
posts.each { |post| puts post.user.name }

puts "実行されたクエリ数: #{query_count}"
```

### 実行時間の測定
```ruby
require 'benchmark'

time = Benchmark.measure do
  posts = Post.includes(:user)
  posts.each { |post| puts post.user.name }
end

puts "実行時間: #{time.real}秒"
```

### SQLの確認
```ruby
# 生成されるSQLを確認
puts Post.joins(:user).merge(User.active).to_sql

# EXPLAINでクエリプランを確認
puts Post.joins(:user).merge(User.active).explain
```

## 次のステップ

基礎概念を理解したら、[basic_exercises.md](basic_exercises.md) で実際に手を動かして練習しましょう。

# 基本練習問題 解答例

## 問題1の解答: 基本的なフィルタリング

```ruby
Post.joins(:user).merge(User.active).pluck(:title)
```

**解説:**
- `joins(:user)` でユーザーテーブルと内部結合
- `merge(User.active)` でアクティブなユーザーの条件を適用
- `pluck(:title)` でタイトルのみを取得

**生成されるSQL:**
```sql
SELECT "posts"."title" FROM "posts" 
INNER JOIN "users" ON "users"."id" = "posts"."user_id" 
WHERE "users"."status" = 'active'
```

---

## 問題2の解答: 関連データの取得

```ruby
posts = Post.includes(:user, :category).merge(Post.published)
posts.each do |post|
  puts "#{post.title} by #{post.user.name} in #{post.category.name}"
end
```

**解説:**
- `includes(:user, :category)` で関連データを一括取得
- `merge(Post.published)` で公開済みの条件を適用
- N+1問題を回避

---

## 問題3の解答: 別クエリでの関連データ取得

```ruby
posts = Post.preload(:comments)
posts.each do |post|
  puts "#{post.title}: #{post.comments.count} comments"
end
```

**解説:**
- `preload(:comments)` で必ず別クエリでコメントを取得
- `count` ではなく `size` を使うとメモリ上のデータを使用

**生成されるSQL:**
```sql
-- 1つ目
SELECT "posts".* FROM "posts"
-- 2つ目
SELECT "comments".* FROM "comments" WHERE "comments"."post_id" IN (1,2,3...)
```

---

## 問題4の解答: JOINでの条件指定

```ruby
posts = Post.eager_load(:comments).where(comments: { status: 'approved' })
posts.each do |post|
  puts "#{post.title} has approved comments"
end
```

**解説:**
- `eager_load(:comments)` で必ずJOINを使用
- `where(comments: { status: 'approved' })` でJOINしたテーブルの条件を指定

**生成されるSQL:**
```sql
SELECT "posts".*, "comments".* FROM "posts" 
LEFT OUTER JOIN "comments" ON "comments"."post_id" = "posts"."id" 
WHERE "comments"."status" = 'approved'
```

---

## 問題5の解答: 複数の関連テーブル

```ruby
posts = Post.includes(:user, :category, :tags).merge(Post.published)
posts.each do |post|
  puts "#{post.title}"
  puts "Author: #{post.user.name}"
  puts "Category: #{post.category.name}"
  puts "Tags: #{post.tags.map(&:name).join(', ')}"
end
```

**解説:**
- `includes(:user, :category, :tags)` で複数の関連データを一括取得
- 多対多の関連（tags）も効率的に取得

---

## 問題6の解答: N+1問題の修正

**修正前（問題のあるコード）:**
```ruby
posts = Post.where(status: 'published')
posts.each do |post|
  puts "Author: #{post.user.name}"          # N+1問題
  puts "Category: #{post.category.name}"    # N+1問題
  puts "Comment count: #{post.comments.count}" # N+1問題
end
```

**修正後:**
```ruby
posts = Post.includes(:user, :category, :comments).where(status: 'published')
posts.each do |post|
  puts "Author: #{post.user.name}"
  puts "Category: #{post.category.name}"
  puts "Comment count: #{post.comments.size}" # count ではなく size
end
```

**解説:**
- `includes` で必要な関連データを一括取得
- `count` は都度クエリを実行するが、`size` はメモリ上のデータを使用

---

## 問題7の解答: 条件付き関連データ取得

```ruby
posts = Post.includes(:user, :category)
           .merge(User.active)
           .merge(Post.published)

posts.each do |post|
  puts "#{post.title} by #{post.user.name} (#{post.category.name})"
end
```

**別解（eager_loadを使用）:**
```ruby
posts = Post.eager_load(:user, :category)
           .where(users: { status: 'active' })
           .where(posts: { status: 'published' })

posts.each do |post|
  puts "#{post.title} by #{post.user.name} (#{post.category.name})"
end
```

**解説:**
- `includes` + `merge` は条件とデータ取得を両立
- `eager_load` + `where` はSQLレベルで条件指定

---

## パフォーマンス比較

各解答を以下のコマンドで比較してみましょう：

```ruby
# クエリ数の確認
ActiveRecord::Base.logger = Logger.new(STDOUT)

# 修正前
posts = Post.where(status: 'published')
posts.each { |post| puts post.user.name }

# 修正後
posts = Post.includes(:user).where(status: 'published')
posts.each { |post| puts post.user.name }
```

## 学習のポイント

1. **目的に応じたメソッド選択**
   - データが必要 → `includes`, `preload`, `eager_load`
   - 条件のみ → `joins`

2. **N+1問題の特定**
   - ループ内での関連データアクセスを警戒
   - `count` vs `size` の使い分け

3. **SQLの理解**
   - `to_sql` でクエリを確認する習慣
   - JOINと別クエリの使い分け

次は [advanced_exercises.md](../advanced_exercises.md) に挑戦しましょう！

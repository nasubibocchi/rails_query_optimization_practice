# 基本練習問題

各問題を解いた後、Railsコンソールで実際に動作確認を行ってください。

## 問題1: 基本的なフィルタリング
アクティブなユーザーが書いた記事のタイトル一覧を取得してください。
ユーザー情報は不要です。

**期待する結果:** 記事のタイトルの配列

---

## 問題2: 関連データの取得
公開済みの記事と、その作成者名、カテゴリ名を一緒に取得してください。
N+1問題を避けて実装してください。

**期待する動作:**
```ruby
posts.each do |post|
  puts "#{post.title} by #{post.user.name} in #{post.category.name}"
end
```

---

## 問題3: 別クエリでの関連データ取得
全ての記事とそのコメントを取得してください。
コメントでの絞り込みは行いません。
必ず別クエリで関連データを取得するようにしてください。

**期待する動作:**
```ruby
posts.each do |post|
  puts "#{post.title}: #{post.comments.count} comments"
end
```

---

## 問題4: JOINでの条件指定
承認済みコメントがある記事のみを取得し、記事情報とコメント情報を同時に取得してください。
必ずJOINを使用してください。

**期待する結果:** 承認済みコメントがある記事のみ

---

## 問題5: 複数の関連テーブル
公開済みの記事について、作成者、カテゴリ、タグの情報を一緒に取得してください。
最も効率的な方法で実装してください。

**期待する動作:**
```ruby
posts.each do |post|
  puts "#{post.title}"
  puts "Author: #{post.user.name}"
  puts "Category: #{post.category.name}"
  puts "Tags: #{post.tags.map(&:name).join(', ')}"
end
```

---

## 問題6: N+1問題の修正
以下のコードはN+1問題を含んでいます。修正してください。

```ruby
# 問題のあるコード
posts = Post.where(status: 'published')
posts.each do |post|
  puts "Author: #{post.user.name}"
  puts "Category: #{post.category.name}"
  puts "Comment count: #{post.comments.count}"
end
```

---

## 問題7: 条件付き関連データ取得
以下の条件を全て満たすクエリを作成してください：
- アクティブなユーザーが書いた記事
- 公開済みの記事のみ
- 記事、ユーザー、カテゴリの情報を使用する
- N+1問題を避ける

**期待する動作:**
```ruby
posts.each do |post|
  puts "#{post.title} by #{post.user.name} (#{post.category.name})"
end
```

---

## 動作確認のコマンド

各問題を解いた後、以下のコマンドで確認してください：

```ruby
# Railsコンソール起動
rails console

# SQLの確認
your_query.to_sql

# クエリ数の確認（簡易版）
ActiveRecord::Base.logger = Logger.new(STDOUT)
your_query.load  # クエリ実行

# クエリプランの確認
your_query.explain
```

## ヒント

- `joins` は関連データを取得しない
- `includes` は Rails が最適なクエリを選択する
- `preload` は必ず別クエリ
- `eager_load` は必ずJOIN
- `merge` でモデルのスコープを適用できる

解答例は [solutions/basic_solutions.md](solutions/basic_solutions.md) を参照してください。

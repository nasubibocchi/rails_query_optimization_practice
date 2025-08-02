# 応用練習問題 解答例

## 問題1の解答: ダッシュボードの最適化

```ruby
def blog_dashboard
  posts = Post.includes(:user, :category, :comments, :tags)
              .where(status: 'published')
              .limit(10)
  
  dashboard_data = posts.map do |post|
    approved_comments = post.comments.select { |c| c.status == 'approved' }
    
    {
      title: post.title,
      author: post.user.name,
      category: post.category.name,
      comment_count: approved_comments.size,
      tag_names: post.tags.map(&:name),
      latest_comment: approved_comments.max_by(&:created_at)&.content
    }
  end
  
  dashboard_data
end
```

**改善点:**
- `includes` で必要な関連データを一括取得
- メモリ上でフィルタリングしてN+1問題を解決
- クエリ数を大幅に削減（11+ → 3-4回）

---

## 問題2の解答: 複雑な条件での最適化

```ruby
def recent_popular_posts
  Post.joins(:user, :comments)
      .where('posts.created_at > ?', 30.days.ago)
      .where(users: { status: 'active' })
      .where(comments: { status: 'approved' })
      .group('posts.id, users.name, posts.title')
      .having('COUNT(comments.id) >= 2')
      .pluck('posts.title, users.name, COUNT(comments.id)')
      .map do |title, author_name, comment_count|
        {
          title: title,
          author_name: author_name,
          approved_comment_count: comment_count
        }
      end
end
```

**改善点:**
- 複数の `joins` で必要なテーブルを結合
- `GROUP BY` と `HAVING` で集計条件を指定
- 1回のクエリで全ての条件を処理

**生成されるSQL:**
```sql
SELECT posts.title, users.name, COUNT(comments.id)
FROM "posts" 
INNER JOIN "users" ON "users"."id" = "posts"."user_id" 
INNER JOIN "comments" ON "comments"."post_id" = "posts"."id"
WHERE posts.created_at > '2024-07-03 00:00:00' 
  AND users.status = 'active' 
  AND comments.status = 'approved'
GROUP BY posts.id, users.name, posts.title
HAVING COUNT(comments.id) >= 2
```

---

## 問題3の解答: メモリ効率の改善

```ruby
def export_user_activity
  # 方法1: バッチ処理でメモリ使用量を抑制
  csv_data = []
  
  User.includes(:posts => :comments).find_in_batches(batch_size: 100) do |users|
    users.each do |user|
      user.posts.each do |post|
        post.comments.each do |comment|
          csv_data << [
            user.name,
            user.email,
            post.title,
            comment.content,
            comment.created_at
          ]
        end
      end
    end
  end
  
  csv_data
end

# 方法2: JOINを使って1クエリで必要なデータを取得（最も効率的）
def export_user_activity_optimized
  Comment.joins(post: :user)
         .pluck('users.name', 'users.email', 'posts.title', 
                'comments.content', 'comments.created_at')
end
```

**改善点:**
- `find_in_batches` で大量データを分割処理
- 方法2では1回のクエリで全データを取得
- メモリ使用量を大幅に削減

---

## 問題4の解答: 集計クエリの最適化

```ruby
def user_statistics
  # 1回のクエリで必要な統計を取得
  stats_data = User.left_joins(:posts)
                   .left_joins(posts: :comments)
                   .group('users.id, users.name')
                   .pluck(
                     'users.id',
                     'users.name',
                     'COUNT(DISTINCT posts.id)',
                     'COUNT(DISTINCT CASE WHEN posts.status = \'published\' THEN posts.id END)',
                     'COUNT(comments.id)',
                     'CASE WHEN COUNT(DISTINCT posts.id) > 0 THEN COUNT(comments.id)::float / COUNT(DISTINCT posts.id) ELSE 0 END'
                   )
  
  stats = {}
  stats_data.each do |user_id, name, total_posts, published_posts, total_comments, avg_comments|
    stats[user_id] = {
      name: name,
      total_posts: total_posts,
      published_posts: published_posts,
      total_comments_received: total_comments,
      avg_comments_per_post: avg_comments.round(2)
    }
  end
  
  stats
end
```

**改善点:**
- 複雑な集計をSQLレベルで実行
- クエリ数を大幅に削減（ユーザー数×4 → 1回）
- `LEFT JOIN` で全ユーザーを取得

---

## 問題5の解答: 関連データの条件付き読み込み

```ruby
def posts_with_recent_comments
  posts = Post.published.includes(:user, :category)
  
  # 承認済みコメントをアクティブユーザーのものだけ、各投稿につき最新3件取得
  recent_comments = Comment.joins(:user, :post)
                           .where(status: 'approved', users: { status: 'active' })
                           .where(post_id: posts.pluck(:id))
                           .includes(:user)
                           .order(:post_id, created_at: :desc)
  
  # 投稿ごとにコメントをグループ化し、最新3件に制限
  comments_by_post = recent_comments.group_by(&:post_id)
                                   .transform_values { |comments| comments.first(3) }
  
  posts.map do |post|
    post_comments = comments_by_post[post.id] || []
    
    {
      post: post,
      recent_comments: post_comments.map do |comment|
        {
          content: comment.content,
          author_name: comment.user.name,
          created_at: comment.created_at
        }
      end
    }
  end
end
```

**改善点:**
- 投稿とコメントを別々に取得してN+1を回避
- メモリ上でグループ化と制限を実装
- クエリ数を最小限に抑制

---

## 問題6の解答: キャッシュ戦略

```ruby
def sidebar_data
  Rails.cache.fetch('sidebar_data', expires_in: 1.hour) do
    {
      popular_tags: Rails.cache.fetch('popular_tags', expires_in: 1.day) do
        Tag.joins(:posts)
           .group('tags.id')
           .order('COUNT(posts.id) DESC')
           .limit(10)
           .pluck(:name)
      end,
      
      recent_posts: Rails.cache.fetch('recent_posts', expires_in: 15.minutes) do
        Post.published
            .includes(:user)
            .order(created_at: :desc)
            .limit(5)
            .map { |p| { title: p.title, author: p.user.name } }
      end,
      
      active_users_count: Rails.cache.fetch('active_users_count', expires_in: 30.minutes) do
        User.joins(:posts)
            .where(posts: { created_at: 1.week.ago.. })
            .distinct
            .count
      end
    }
  end
end

# キャッシュ無効化のコールバック
# app/models/post.rb
class Post < ApplicationRecord
  after_create :clear_sidebar_cache
  after_update :clear_sidebar_cache
  after_destroy :clear_sidebar_cache
  
  private
  
  def clear_sidebar_cache
    Rails.cache.delete('sidebar_data')
    Rails.cache.delete('recent_posts')
    
    # タグの人気度に影響する場合のみ
    if saved_change_to_attribute?('status') || destroyed?
      Rails.cache.delete('popular_tags')
    end
  end
end

# app/models/user.rb
class User < ApplicationRecord
  after_update :clear_user_cache, if: :saved_change_to_status?
  
  private
  
  def clear_user_cache
    Rails.cache.delete('active_users_count')
  end
end
```

**キャッシュ戦略:**
- データの変更頻度に応じて有効期限を設定
- 階層的なキャッシュで効率化
- 適切なタイミングでキャッシュを無効化

---

## 問題7の解答: バッチ処理の最適化

```ruby
def update_post_statistics
  # 集計データを一括取得
  stats_data = Post.left_joins(:comments, :tags)
                   .group('posts.id')
                   .pluck(
                     'posts.id',
                     'COUNT(DISTINCT CASE WHEN comments.status = \'approved\' THEN comments.id END)',
                     'COUNT(DISTINCT tags.id)',
                     'MAX(CASE WHEN comments.status = \'approved\' THEN comments.created_at END)'
                   )
  
  # バッチアップデート用のデータを準備
  update_data = stats_data.map do |post_id, comment_count, tag_count, last_commented_at|
    {
      id: post_id,
      approved_comment_count: comment_count,
      tag_count: tag_count,
      last_commented_at: last_commented_at
    }
  end
  
  # バッチアップデート実行
  Post.upsert_all(
    update_data,
    update_only: [:approved_comment_count, :tag_count, :last_commented_at]
  )
end

# さらに大量データの場合は分割処理
def update_post_statistics_chunked
  Post.find_in_batches(batch_size: 1000) do |posts|
    post_ids = posts.pluck(:id)
    
    stats_data = Post.where(id: post_ids)
                     .left_joins(:comments, :tags)
                     .group('posts.id')
                     .pluck(
                       'posts.id',
                       'COUNT(DISTINCT CASE WHEN comments.status = \'approved\' THEN comments.id END)',
                       'COUNT(DISTINCT tags.id)',
                       'MAX(CASE WHEN comments.status = \'approved\' THEN comments.created_at END)'
                     )
    
    update_data = stats_data.map do |post_id, comment_count, tag_count, last_commented_at|
      {
        id: post_id,
        approved_comment_count: comment_count,
        tag_count: tag_count,
        last_commented_at: last_commented_at
      }
    end
    
    Post.upsert_all(
      update_data,
      update_only: [:approved_comment_count, :tag_count, :last_commented_at]
    )
  end
end
```

**改善点:**
- 複雑な集計をSQLレベルで実行
- `upsert_all` でバッチアップデート
- 大量データには分割処理を適用

---

## パフォーマンス測定結果の例

```ruby
# 修正前vs修正後の比較
require 'benchmark'

puts "=== 問題1: ダッシュボード ==="
puts "修正前:"
time1 = Benchmark.measure { blog_dashboard_old }
puts "実行時間: #{time1.real}秒"

puts "修正後:"
time2 = Benchmark.measure { blog_dashboard }
puts "実行時間: #{time2.real}秒"
puts "改善率: #{((time1.real - time2.real) / time1.real * 100).round(1)}%"
```

## 学習のポイント

1. **SQL集計の活用**
   - `GROUP BY`, `HAVING`, `COUNT`, `MAX` などを積極的に使用
   - データベースレベルでの処理が最も効率的

2. **メモリ効率の考慮**
   - `find_in_batches` で大量データを分割処理
   - 必要最小限のデータのみを取得

3. **キャッシュ戦略**
   - データの性質に応じた有効期限設定
   - 適切なタイミングでの無効化

4. **バッチ処理の最適化**
   - `upsert_all` で一括更新
   - トランザクションでの一貫性保証

これらのテクニックは実際のプロダクション環境で大きなパフォーマンス改善をもたらします！

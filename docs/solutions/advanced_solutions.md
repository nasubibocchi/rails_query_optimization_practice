# 応用練習問題 解答例
# 応用練習問題 解答例

## 問題1の解答: ダッシュボードの最適化

```ruby
def blog_dashboard
  posts = Post.includes(:user, :category, :comments, :tags)
              .where(status: 'published')
              .limit(10)
  
  posts.map do |post|
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
end
```

**改善点:**
- `includes` で必要な関連データを一括取得
- メモリ上でフィルタリングしてN+1問題を解決

---

## 問題2の解答: 複雑な条件での最適化

```ruby
def recent_popular_posts
  # アクティブユーザーの記事を取得（関連データも必要なので eager_load）
  posts = Post.eager_load(:user, :comments)
              .where('posts.created_at > ?', 30.days.ago)
              .where(users: { status: 'active' })
  
  result = []
  posts.each do |post|
    approved_comments = post.comments.select { |c| c.status == 'approved' }
    if approved_comments.size >= 2
      result << {
        title: post.title,
        author_name: post.user.name,
        approved_comment_count: approved_comments.size
      }
    end
  end
  
  result
end
```

**改善点:**
- `eager_load` で関連テーブルの条件を指定
- メモリ上でコメント数の条件を処理
- N+1問題を解決

**学習ポイント:** なぜ `eager_load` を選んだのか？関連テーブルの条件が必要だから

---

## 問題3の解答: メモリ効率の改善

```ruby
def export_user_activity
  posts = Post.eager_load(:user).preload(:comments)
  
  csv_data = []
  posts.each do |post|
    post.comments.each do |comment|
      csv_data << [
        post.user.name,
        post.user.email,
        post.title,
        comment.content,
        comment.created_at
      ]
    end
  end
  
  csv_data
end

# 大量データの場合
def export_user_activity_batched
  csv_data = []
  
  Post.preload(:user, :comments).find_in_batches(batch_size: 1000) do |posts|
    posts.each do |post|
      post.comments.each do |comment|
        csv_data << [
          post.user.name,
          post.user.email,
          post.title,
          comment.content,
          comment.created_at
        ]
      end
    end
  end
  
  csv_data
end
```

**改善点:**
- `eager_load(:user).preload(:comments)` で最適化
- `find_in_batches` で大量データを分割処理

**学習ポイント:** なぜユーザーは `eager_load` でコメントは `preload` なのか？

---

## 問題4の解答: 集計クエリの最適化

```ruby
def user_statistics
  users = User.preload(:posts, posts: :comments)
  
  stats = {}
  users.each do |user|
    published_posts = user.posts.select { |p| p.status == 'published' }
    all_comments = user.posts.flat_map(&:comments)
    
    stats[user.id] = {
      name: user.name,
      total_posts: user.posts.size,
      published_posts: published_posts.size,
      total_comments_received: all_comments.size,
      avg_comments_per_post: user.posts.size > 0 ? (all_comments.size.to_f / user.posts.size).round(2) : 0
    }
  end
  
  stats
end
```

**改善点:**
- `preload` で関連データを別クエリで取得
- メモリ上で統計計算を実行

**学習ポイント:** なぜ `preload` を選んだのか？条件がなく純粋にデータが必要だから

---

## 問題5の解答: 関連データの条件付き読み込み

```ruby
def posts_with_recent_comments
  posts = Post.published.preload(:comments, comments: :user)
  
  result = posts.map do |post|
    # アクティブユーザーの承認済みコメントを取得
    approved_comments = post.comments.select do |comment|
      comment.status == 'approved' && comment.user.status == 'active'
    end
    
    # 最新3件に制限
    recent_comments = approved_comments.sort_by(&:created_at).reverse.first(3)
    
    {
      post: post,
      recent_comments: recent_comments.map do |comment|
        {
          content: comment.content,
          author_name: comment.user.name,
          created_at: comment.created_at
        }
      end
    }
  end
  
  result
end
```

**改善点:**
- `preload` で関連データを一括取得
- メモリ上でフィルタリングとソート

**学習ポイント:** なぜ `preload` なのか？複雑な条件があるため

---

## 問題6の解答: キャッシュ戦略

```ruby
def sidebar_data
  Rails.cache.fetch('sidebar_data_v1', expires_in: 15.minutes) do
    {
      popular_tags: Rails.cache.fetch('popular_tags_v1', expires_in: 1.day) do
        tags = Tag.preload(:posts)
        tags.map { |tag| [tag.name, tag.posts.size] }
            .sort_by { |_, count| -count }
            .first(10)
            .map(&:first)
      end,
      
      recent_posts: Rails.cache.fetch('recent_posts_v1', expires_in: 5.minutes) do
        Post.includes(:user)
            .where(status: 'published')
            .order(created_at: :desc)
            .limit(5)
            .map { |p| { title: p.title, author: p.user.name } }
      end,
      
      active_users_count: Rails.cache.fetch('active_users_count_v1', expires_in: 30.minutes) do
        users = User.preload(:posts)
        users.select { |user| user.posts.any? { |post| post.created_at > 1.week.ago } }
             .size
      end
    }
  end
end

# キャッシュ無効化
class Post < ApplicationRecord
  after_create :clear_relevant_caches
  after_update :clear_relevant_caches, if: :saved_change_to_status?
  after_destroy :clear_relevant_caches
  
  private
  
  def clear_relevant_caches
    Rails.cache.delete('sidebar_data_v1')
    Rails.cache.delete('recent_posts_v1')
    Rails.cache.delete('popular_tags_v1')
    Rails.cache.delete('active_users_count_v1')
  end
end
```

**改善点:**
- `preload` と `includes` を使い分け
- メモリ上で集計とソート処理

**学習ポイント:** なぜタグは `preload` で最近の投稿は `includes` なのか？

---

## 問題7の解答: バッチ処理の最適化

```ruby
def update_post_statistics
  posts = Post.preload(:comments, :tags)
  
  Post.transaction do
    posts.each do |post|
      approved_comments = post.comments.select { |c| c.status == 'approved' }
      
      post.update!(
        approved_comment_count: approved_comments.size,
        tag_count: post.tags.size,
        last_commented_at: approved_comments.map(&:created_at).max
      )
    end
  end
end

# 大量データの場合
def update_post_statistics_batched
  Post.preload(:comments, :tags).find_in_batches(batch_size: 1000) do |posts|
    Post.transaction do
      posts.each do |post|
        approved_comments = post.comments.select { |c| c.status == 'approved' }
        
        post.update!(
          approved_comment_count: approved_comments.size,
          tag_count: post.tags.size,
          last_commented_at: approved_comments.map(&:created_at).max
        )
      end
    end
  end
end
```

**改善点:**
- `preload` で関連データを一括取得
- メモリ上で統計計算
- バッチ処理でメモリ効率化

**学習ポイント:** なぜ `preload` なのか？単純にデータが必要で条件がないから

---

## 学習のポイント

### メソッドの使い分け
1. **`includes`** - Rails に最適化を任せたい場合
2. **`preload`** - 確実に別クエリで取得したい場合
3. **`eager_load`** - 関連テーブルの条件が必要な場合
4. **`joins`** - 関連データは不要で条件のみ必要な場合

### 選択理由の例
- **問題2**: `eager_load` → 関連テーブル（users）の条件が必要
- **問題3**: `eager_load` + `preload` → ユーザーは条件あり、コメントは条件なし
- **問題4**: `preload` → 純粋にデータが必要、条件なし
- **問題6**: 混在 → 用途に応じて使い分け



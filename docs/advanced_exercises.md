# 応用練習問題

実際の開発でよく遭遇するパフォーマンス問題をベースにした練習問題です。

## 問題1: ダッシュボードの最適化
以下のコードはN+1問題を含んでいます。最適化してください。

```ruby
def blog_dashboard
  posts = Post.where(status: 'published').limit(10)
  
  dashboard_data = posts.map do |post|
    {
      title: post.title,
      author: post.user.name,
      category: post.category.name,
      comment_count: post.comments.where(status: 'approved').count,
      tag_names: post.tags.pluck(:name),
      latest_comment: post.comments.order(created_at: :desc).first&.content
    }
  end
  
  dashboard_data
end
```

**目標:** 同じ結果を返しつつ、SQLクエリ数を最小限に抑える

---

## 問題2: 複雑な条件での最適化
以下の要件を満たすクエリを、可能な限り少ないSQLクエリで実現してください。

**要件:**
- 過去30日以内に投稿された記事
- その記事の作成者がアクティブ
- 承認済みコメントが2件以上ある記事
- 結果には記事のタイトル、作成者名、承認済みコメント数を含める

```ruby
# 現在のコード（非効率）
def recent_popular_posts
  recent_posts = Post.where('created_at > ?', 30.days.ago)
  
  result = []
  recent_posts.each do |post|
    if post.user.status == 'active'
      approved_comments = post.comments.where(status: 'approved')
      if approved_comments.count >= 2
        result << {
          title: post.title,
          author_name: post.user.name,
          approved_comment_count: approved_comments.count
        }
      end
    end
  end
  
  result
end
```

---

## 問題3: メモリ効率の改善
大量のデータを扱う際のメモリ使用量を最適化してください。

```ruby
# 現在のコード（メモリを大量消費）
def export_user_activity
  users = User.includes(:posts, :comments)
  
  csv_data = []
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
  
  csv_data
end
```

**想定:** 10万件のコメントがある場合を考慮してください

---

## 問題4: 集計クエリの最適化
以下の統計情報を効率的に取得してください。

```ruby
# 現在のコード（非効率）
def user_statistics
  stats = {}
  
  User.find_each do |user|
    stats[user.id] = {
      name: user.name,
      total_posts: user.posts.count,
      published_posts: user.posts.where(status: 'published').count,
      total_comments_received: user.posts.joins(:comments).count,
      avg_comments_per_post: user.posts.joins(:comments).count.to_f / [user.posts.count, 1].max
    }
  end
  
  stats
end
```

---

## 問題5: 関連データの条件付き読み込み
以下の要件を満たすクエリを作成してください。

**要件:**
- 記事一覧を表示
- 各記事に対して：
  - 最新の承認済みコメント3件（あれば）
  - アクティブなユーザーからのコメントのみ
  - コメントした人の名前も表示
- できるだけ少ないクエリで実現

```ruby
# 現在のコード
def posts_with_recent_comments
  posts = Post.published.includes(:comments)
  
  result = posts.map do |post|
    recent_comments = post.comments
                         .joins(:user)
                         .where(status: 'approved', users: { status: 'active' })
                         .order(created_at: :desc)
                         .limit(3)
                         .includes(:user)
    
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

---

## 問題6: キャッシュ戦略
以下のコードに適切なキャッシュを実装してください。

```ruby
# 現在のコード（毎回DBアクセス）
def sidebar_data
  {
    popular_tags: Tag.joins(:posts)
                     .group('tags.id')
                     .order('COUNT(posts.id) DESC')
                     .limit(10)
                     .pluck(:name),
    
    recent_posts: Post.published
                     .includes(:user)
                     .order(created_at: :desc)
                     .limit(5)
                     .map { |p| { title: p.title, author: p.user.name } },
    
    active_users_count: User.joins(:posts)
                           .where(posts: { created_at: 1.week.ago.. })
                           .distinct
                           .count
  }
end
```

**考慮事項:**
- どのデータをキャッシュすべきか
- キャッシュの有効期限
- キャッシュの無効化タイミング

---

## 問題7: バッチ処理の最適化
以下のバッチ処理を最適化してください。

```ruby
# 現在のコード（タイムアウトする可能性）
def update_post_statistics
  Post.find_each do |post|
    comment_count = post.comments.where(status: 'approved').count
    tag_count = post.tags.count
    
    post.update!(
      approved_comment_count: comment_count,
      tag_count: tag_count,
      last_commented_at: post.comments.where(status: 'approved').maximum(:created_at)
    )
  end
end
```

**要件:**
- 大量のデータ（100万件の投稿）でも効率的に動作
- データベースの負荷を最小限に抑える

---

## 検証ポイント

各問題を解いた後、以下の点を確認してください：

### パフォーマンス測定
```ruby
require 'benchmark'

# 実行時間の測定
time = Benchmark.measure { your_solution }
puts "実行時間: #{time.real}秒"

# メモリ使用量の測定（簡易版）
before = `ps -o rss= -p #{Process.pid}`.to_i
your_solution
after = `ps -o rss= -p #{Process.pid}`.to_i
puts "メモリ使用量の変化: #{after - before}KB"
```

### クエリ数の確認
```ruby
query_count = 0
ActiveSupport::Notifications.subscribe('sql.active_record') do
  query_count += 1
```

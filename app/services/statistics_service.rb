# 統計情報サービス

class StatisticsService
  def self.recent_popular_posts
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

  def self.user_statistics
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
end


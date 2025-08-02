class StatisticsService
  def self.recent_popular_posts
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

  def self.user_statistics
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
end


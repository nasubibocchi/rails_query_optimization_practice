class StatisticsService
  def self.recent_popular_posts
    # recent_posts = Post.where('created_at > ?', 30.days.ago)
    recent_posts_with_approved_comments = Post.eager_load(:user, :comments).merge(Comment.approved)

    result = []
    #recent_posts.each do |post|
    #  if post.user.status == 'active'
    #    approved_comments = post.comments.where(status: 'approved')
    #    if approved_comments.count >= 2
    #      result << {
    #        title: post.title,
    #        author_name: post.user.name,
    #        approved_comment_count: approved_comments.count
    #      }
    #    end
    #  end
    #end

    recent_posts_with_approved_comments.each do |post|
      if post.comments.count >= 2
        result << {
          title: post.title,
          author_name: post.user.name,
          approved_comment_count: post.comments.size
        }
      end
    end
    
    result
  end

  def self.user_statistics
    stats = {}

    users = User.preload(:posts, posts: :comments)
    
    # User.find_each do |user|
    #   stats[user.id] = {
    #     name: user.name,
    #     total_posts: user.posts.count,
    #     published_posts: user.posts.where(status: 'published').count,
    #     total_comments_received: user.posts.joins(:comments).count,
    #     avg_comments_per_post: user.posts.joins(:comments).count.to_f / [user.posts.count, 1].max
    #   }
    # end
    
    users.find_each do |user|
      total_comment_count = user.posts.flat_map(&:comments).count

      stats[user.id] = {
        name: user.name,
        total_posts: user.posts.count,
        published_post: user.posts.published.count,
        total_comments_received: total_comment_count,
        avg_comments_per_post: total_comment_count.to_f / [user.posts.count, 1].max
      }

    stats
  end
end


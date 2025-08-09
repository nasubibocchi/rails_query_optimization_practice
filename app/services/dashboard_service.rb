class DashboardService
  def self.blog_dashboard
    # posts = Post.where(status: 'published').limit(10)
    posts = Post.eager_load(:user, :category)
                .preload(:comments, :tags)
                .published
                .limit(10)

    dashboard_data = posts.map do |post|
      approved_comments = post.comments.select{ |c| c.status == "approved" }
      latest_comment = post.comments.max_by(&:created_at)
      
      {
        title: post.title,
        author: post.user.name,
        category: post.category.name,
        # comment_count: post.comments.where(status: 'approved').count,
        comment_count: approved_comments&.size,
        # tag_names: post.tags.pluck(:name),
        tag_names: post.tags.map(&:name),
        # latest_comment:post.comments.order(created_at: :desc).first&.content
        latest_comment: latest_comment&.content
      }
    end

    dashboard_data
  end
end


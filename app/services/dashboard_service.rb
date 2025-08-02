class DashboardService
  def self.blog_dashboard
    posts = Post.where(status: 'published').limit(10)

    dashboard_data = posts.map do |post|
      {
        title: post.title,
        author: post.user.name,
        category: post.category.name,
        comment_count: post.comments.where(status: 'approved').count,
        tag_names: post.tags.pluck(:name),
        latest_comment:post.comments.order(created_at: :desc).first&.content
      }
    end

    dashboard_data
  end
end


class PostsService
  # 問題5: 関連データの条件付き読み込み
  def self.posts_with_recent_comments
    # posts = Post.published.includes(:comments)
    posts = Post.published.eager_load(:user, :comments)
      .merge(User.active)
      .merge(Comment.approved)
      .distinct

    result = posts.map do |post|
      # recent_comments = post.comments
      #                      .joins(:user)
      #                      .where(status: 'approved', users: { status: 'active' })
      #                      .order(created_at: :desc)
      #                      .limit(3)
      #                      .includes(:user)

      recent_comments = post.comments.sort_by(&:created_at).first(3)

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
end


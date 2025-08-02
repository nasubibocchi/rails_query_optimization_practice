class PostsService
  # 問題5: 関連データの条件付き読み込み
  def self.posts_with_recent_comments
    # posts = Post.published.includes(:comments)
    #
    # こっちでもいい
    # posts = Post.published.preload(:comments, comments: :user)
    posts = Post.published.preload(:comments).eager_load(:user)

    result = posts.map do |post|
      # recent_comments = post.comments
      #                      .joins(:user)
      #                      .where(status: 'approved', users: { status: 'active' })
      #                      .order(created_at: :desc)
      #                      .limit(3)
      #                      .includes(:user)

      recent_comments = post.comments
                            .select { |comment| comment.status == 'active' && comment.user.status = 'active' }
                            .sort(&:created_at)
                            .first(3)

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


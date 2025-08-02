# 問題3のコード: メモリ効率の改善
# 大量のデータを扱う際のメモリ使用量を最適化してください。

class ExportService
  def self.export_user_activity
    # users = User.includes(:posts, :comments)
    posts = Post.eager_load(:user).preload(:comments)
    
    csv_data = []
    # users.each do |user|
    #   user.posts.each do |post|
    #     post.comments.each do |comment|
    #       csv_data << [
    #         user.name,
    #         user.email,
    #         post.title,
    #         comment.content,
    #         comment.created_at
    #       ]
    #     end
    #   end
    # end
    
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
end


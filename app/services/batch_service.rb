class BatchService
  # 問題7: バッチ処理の最適化
  def self.update_post_statistics
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
end


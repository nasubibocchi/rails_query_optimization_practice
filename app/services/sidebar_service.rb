# 問題6のコード: キャッシュ戦略
# 以下のコードに適切なキャッシュを実装してください。

class SidebarService
  def self.sidebar_data
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
end


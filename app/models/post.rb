class Post < ApplicationRecord
  belongs_to :user
  belongs_to :category
  has_many :comments, dependent: :destroy
  has_many :post_tags, dependent: :destroy
  has_many :tags, through: :post_tags

  scope :published, -> { where(published: true) }
  scope :draft, -> { where(status: 'draft') }
  scope :recent, -> { order(created_at: :desc) }

  class << self
    def titles_by_active_users
      joins(:user).merge(User.active).pluck(:title)
    end

    def active_posts_with_user_and_category_name
      eager_load(:user, :category)
    end
  end
end

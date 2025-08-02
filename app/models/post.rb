class Post < ApplicationRecord
  belongs_to :user
  belongs_to :category
  has_many :comments, dependent: :destroy
  has_many :post_tags, dependent: :destroy
  has_many :tags, through: :post_tags

  scope :published, -> { where(published: true) }
  scope :draft, -> { where(status: 'draft') }
  scope :recent, -> { order(created_at: :desc) }
end

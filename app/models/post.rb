class Post < ApplicationRecord
  belongs_to :user
  belongs_to :category
  has_many :comments, dependant: :destroy
  has_many :post_tags, dependant: :destroy
  has_many :tags, through: :post_tags

  scope :published, -> { where(published: true) }
  scope :draft, -> { where(status: 'draft') }
  scope :recent, -> { order(created_at: :desc) }
end

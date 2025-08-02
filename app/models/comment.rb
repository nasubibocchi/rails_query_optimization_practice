class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :post

  scope :approved, -> { where(status: 'approved') }
  scope :pending, -> { where(status: 'pending') }
end

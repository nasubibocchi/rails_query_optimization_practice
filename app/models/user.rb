class User < ApplicationRecord
  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy

  scope :active, -> { where(status: 'active') }
  scope :inactive, -> { where(status: 'inactive') }
end

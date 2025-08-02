class User < ApplicationRecord
  has_many :posts, dependant: :destroy
  has_many :comments, dependant: :destroy

  scope :active, -> { where(status: 'active') }
  scope :inactive, -> { where(status: 'inactive') }
end

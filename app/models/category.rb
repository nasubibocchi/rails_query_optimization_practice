class Category < ApplicationRecord
  has_may :posts, dependant: :destroy
end

class Checkin < ApplicationRecord
  belongs_to :user, touch: true
  belongs_to :unit, touch: true
end

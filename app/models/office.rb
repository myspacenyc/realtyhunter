class Office < ActiveRecord::Base
	belongs_to :company
	has_many :users
	
	validates :name, presence: true, length: {maximum: 100}, 
						uniqueness: { case_sensitive: false }

  #validates :street_address, presence: true, length: {maximum: 100},
  #          uniqueness: { case_sensitive: false }
            
	#validates :city, length: { maximum: 100 }, presence: true
	#validates :state, length: { minimum: 2, maximum:2 }, presence: true
	#validates :zipcode, length: { minimum: 5, maximum:10 }, presence: true

	# Google Maps location info
	validates :formatted_street_address, presence: true, length: {maximum: 200}, 
						uniqueness: { case_sensitive: false }
						
	validates :street_number, presence: true, length: {maximum: 20}
	validates :route, presence: true, length: {maximum: 100}
	# borough
	#:sublocality can be blank
	# city
	validates :administrative_area_level_2_short, presence: true, length: {maximum: 100}
	# state
	validates :administrative_area_level_1_short, presence: true, length: {maximum: 100}
	validates :postal_code, presence: true, length: {maximum: 15}
	validates :country_short, presence: true, length: {maximum: 100}
	validates :lat, presence: true, length: {maximum: 100}
	validates :lng, presence: true, length: {maximum: 100}
	validates :place_id, presence: true, length: {maximum: 100}


	# Other options: strip all formatting out and save as raw string of digits.
	# Format on the front end.
	VALID_TELEPHONE_REGEX = /(?:(?:\+?1\s*(?:[.-]\s*)?)?(?:\(\s*([2-9]1[02-9]|[2-9][02-8]1|[2-9][02-8][02-9])\s*\)|([2-9]1[02-9]|[2-9][02-8]1|[2-9][02-8][02-9]))\s*(?:[.-]\s*)?)?([2-9]1[02-9]|[2-9][02-9]1|[2-9][02-9]{2})\s*(?:[.-]\s*)?([0-9]{4})(?:\s*(?:#|x\.?|ext\.?|extension)\s*(\d+))?/
	validates :telephone, presence: true, length: {maximum: 20}, 
						format: { with: VALID_TELEPHONE_REGEX }

	def managers
		@managers = self.users.select{|u| u if u.is_manager?}
	end

	def agents
		@agents = self.users.select{|u| u if !u.is_manager?}
	end
end

class AddBonusDetailsToResidentialListings < ActiveRecord::Migration[5.0]
  def change
  	add_column :residential_listings, :bonus_details, :string
  end
end

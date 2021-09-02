class AddSePendingTextToResidentialListings < ActiveRecord::Migration[5.0]
  def change
  	add_column :residential_listings, :se_pending_text, :string
  end
end

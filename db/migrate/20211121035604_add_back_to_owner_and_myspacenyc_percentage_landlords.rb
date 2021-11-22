class AddBackToOwnerAndMyspacenycPercentageLandlords < ActiveRecord::Migration[5.0]
  def change
  	add_column :landlords, :back_to_owner, :integer
  	add_column :landlords, :myspacenyc_percentage, :integer
  end
end

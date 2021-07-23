class AddPromotionalPriceToUnits < ActiveRecord::Migration[5.0]
  def change
  	add_column :units, :promotional_price, :integer
  end
end

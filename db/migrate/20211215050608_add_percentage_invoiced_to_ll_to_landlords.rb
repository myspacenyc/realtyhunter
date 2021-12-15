class AddPercentageInvoicedToLlToLandlords < ActiveRecord::Migration[5.0]
  def change
  	add_column :landlords, :percentage_invoiced_to_ll, :integer
  end
end

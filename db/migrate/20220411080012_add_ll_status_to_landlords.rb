class AddLlStatusToLandlords < ActiveRecord::Migration[5.0]
  def change
  	add_column :landlords, :ll_status, :boolean, default: :true
  end
end

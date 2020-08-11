class AddApplicationsToUnits < ActiveRecord::Migration[5.0]
  def change
  	add_column :units, :applications, :integer
  end
end

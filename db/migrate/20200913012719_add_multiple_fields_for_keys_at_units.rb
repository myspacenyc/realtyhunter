class AddMultipleFieldsForKeysAtUnits < ActiveRecord::Migration[5.0]
  def change
  	add_column :units, :unit_tag_number, :integer
  	add_column :units, :unit_key_status, :string
  	add_column :units, :unit_office_location, :string
  	add_column :units, :unit_master, :boolean, default: false
  	add_column :units, :unit_commercial_property, :boolean, default: false
  	add_column :units, :unit_key_active, :boolean, default: false
  	add_column :units, :unit_signout_key, :boolean, default: false
  	add_column :units, :unit_case_name, :string
  end
end

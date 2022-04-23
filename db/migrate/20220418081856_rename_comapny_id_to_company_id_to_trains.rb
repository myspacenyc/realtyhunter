class RenameComapnyIdToCompanyIdToTrains < ActiveRecord::Migration[5.0]
  def change
  	rename_column :trains, :comapny_id, :company_id
  end
end

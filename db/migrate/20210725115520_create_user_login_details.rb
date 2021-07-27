class CreateUserLoginDetails < ActiveRecord::Migration[5.0]
  def change
    create_table :user_login_details do |t|
      t.string :login_address
      t.datetime :login_time
      t.integer :user_id

      t.timestamps
    end
  end
end

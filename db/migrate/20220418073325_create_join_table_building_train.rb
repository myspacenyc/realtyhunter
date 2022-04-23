class CreateJoinTableBuildingTrain < ActiveRecord::Migration[5.0]
  def change
    create_join_table :buildings, :trains do |t|
      t.index [:building_id, :train_id]
      # t.index [:train_id, :building_id]
    end
  end
end

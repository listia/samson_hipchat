class CreateHipchatRooms < ActiveRecord::Migration
  def change
    create_table :hipchat_rooms do |t|
      t.string :name, null: false
      t.string :token, null: false
      t.string :room_id, null: false
      t.integer :stage_id, null: false

      t.timestamps
    end

    add_index :hipchat_rooms, :stage_id

  end
end

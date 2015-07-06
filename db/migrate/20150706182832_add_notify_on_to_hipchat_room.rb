class AddNotifyOnToHipchatRoom < ActiveRecord::Migration
  def change
    change_table :hipchat_rooms do |t|
      # Always send notification
      t.integer :notify_on, default: 0
    end
  end
end

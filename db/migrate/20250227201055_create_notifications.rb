class CreateNotifications < ActiveRecord::Migration[7.1]
  def change
    create_table :notifications, id: :uuid do |t|
      t.references :user, polymorphic: true, null: false, type: :uuid
      t.text :message

      t.timestamps
    end
  end
end

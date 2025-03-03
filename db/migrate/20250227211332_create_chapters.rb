class CreateChapters < ActiveRecord::Migration[7.1]
  def change
    create_table :chapters, id: :uuid do |t|
      t.references :book, null: false, foreign_key: true, type: :uuid
      t.string :title
      t.text :content
      t.integer :duration

      t.timestamps
    end
  end
end

class CreateMangas < ActiveRecord::Migration
  def change
    create_table :mangas do |t|
      t.integer :alid
      t.integer :malid

      t.timestamps null: false
    end
  end
end

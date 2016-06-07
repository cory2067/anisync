class CreateAnimes < ActiveRecord::Migration
  def change
    create_table :animes do |t|
      t.integer :alid
      t.integer :malid

      t.timestamps null: false
    end
  end
end

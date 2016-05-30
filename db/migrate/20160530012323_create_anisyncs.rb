class CreateAnisyncs < ActiveRecord::Migration
  def change
    create_table :anisyncs do |t|
      t.text :username
      t.text :password
      t.text :token
      t.text :refresh

      t.timestamps null: false
    end
  end
end

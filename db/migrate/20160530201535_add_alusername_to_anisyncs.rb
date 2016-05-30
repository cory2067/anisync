class AddAlusernameToAnisyncs < ActiveRecord::Migration
  def change
    add_column :anisyncs, :alusername, :text
  end
end

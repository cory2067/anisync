class AddSyncToAnisyncs < ActiveRecord::Migration
  def change
    add_column :anisyncs, :sync, :datetime
  end
end

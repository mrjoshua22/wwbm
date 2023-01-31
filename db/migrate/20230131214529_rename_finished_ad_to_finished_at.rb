class RenameFinishedAdToFinishedAt < ActiveRecord::Migration[7.0]
  def change
    rename_column :games, :finished_ad, :finished_at
  end
end

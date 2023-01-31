class RenameAsnwer3ToAnswer3 < ActiveRecord::Migration[7.0]
  def change
    rename_column :questions, :asnwer3, :answer3
  end
end

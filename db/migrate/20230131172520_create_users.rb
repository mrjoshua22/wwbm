class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :email
      t.boolean :is_admin, default: false, null: false
      t.integer :balance, default: false, null: false

      t.timestamps
    end
  end
end

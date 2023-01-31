class CreateQuestions < ActiveRecord::Migration[7.0]
  def change
    create_table :questions do |t|
      t.integer :level, null: false
      t.text :text, null: false
      t.string :answer1, null: false
      t.string :answer2
      t.string :asnwer3
      t.string :answer4

      t.timestamps
    end

    add_index :questions, :level
  end
end

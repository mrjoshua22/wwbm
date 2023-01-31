class CreateGameQuestions < ActiveRecord::Migration[7.0]
  def change
    create_table :game_questions do |t|
      t.references :game, index: true, null: false, foreign_key: true
      t.references :question, null: false, foreign_key: true
      t.integer :a
      t.integer :b
      t.integer :c
      t.integer :d

      t.timestamps
    end
  end
end

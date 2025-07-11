class CreateVotes < ActiveRecord::Migration[7.2]
  def change
    create_table :votes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :budget_project, null: false, foreign_key: true
      t.references :budget_phase, null: false, foreign_key: true
      t.decimal :vote_weight

      t.timestamps
    end
  end
end

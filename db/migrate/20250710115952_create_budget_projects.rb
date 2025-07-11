class CreateBudgetProjects < ActiveRecord::Migration[7.2]
  def change
    create_table :budget_projects do |t|
      t.string :title
      t.text :description
      t.decimal :amount
      t.string :status
      t.references :budget_category, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end

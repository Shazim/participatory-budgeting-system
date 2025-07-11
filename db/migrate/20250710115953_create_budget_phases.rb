class CreateBudgetPhases < ActiveRecord::Migration[7.2]
  def change
    create_table :budget_phases do |t|
      t.string :name
      t.text :description
      t.string :phase_type
      t.date :start_date
      t.date :end_date
      t.string :status
      t.references :budget, null: false, foreign_key: true
      t.text :voting_rules
      t.text :participant_eligibility

      t.timestamps
    end
  end
end

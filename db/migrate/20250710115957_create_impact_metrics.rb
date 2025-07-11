class CreateImpactMetrics < ActiveRecord::Migration[7.2]
  def change
    create_table :impact_metrics do |t|
      t.integer :estimated_beneficiaries
      t.integer :timeline_months
      t.decimal :sustainability_score
      t.string :environmental_impact
      t.string :social_impact
      t.string :economic_impact
      t.references :budget_project, null: false, foreign_key: true

      t.timestamps
    end
  end
end

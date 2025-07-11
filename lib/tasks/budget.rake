namespace :budget do
  desc "Transition budget phases automatically based on dates"
  task transition_phases: :environment do
    puts "Running budget phase transition task..."

    # Transition pending phases to active if their start date has arrived
    BudgetPhase.pending.where("start_date <= ?", Date.current).find_each do |phase|
      puts "Activating phase '#{phase.name}' for budget '#{phase.budget.title}'..."
      phase.activate!
    end

    # Transition active phases to completed if their end date has passed
    BudgetPhase.active.where("end_date < ?", Date.current).find_each do |phase|
      puts "Completing phase '#{phase.name}' for budget '#{phase.budget.title}'..."
      phase.complete!
    end

    puts "Phase transition task completed."
  end
end

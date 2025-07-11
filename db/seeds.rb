# Clear existing data in development
if Rails.env.development?
  puts "🧹 Cleaning existing data..."
  Vote.destroy_all
  ImpactMetric.destroy_all
  BudgetProject.destroy_all
  BudgetPhase.destroy_all
  BudgetCategory.destroy_all
  Budget.destroy_all
  User.destroy_all
end

# Create Users
puts "👥 Creating users..."

# Admin user
admin = User.create!(
  name: "Sarah Chen",
  email: "admin@participatorybudget.com",
  password: "password123",
  password_confirmation: "password123",
  role: "admin"
)

# Participant users
participants = [
  {
    name: "Marcus Johnson",
    email: "marcus@example.com",
    password: "password123",
    password_confirmation: "password123",
    role: "participant"
  },
  {
    name: "Elena Rodriguez",
    email: "elena@example.com", 
    password: "password123",
    password_confirmation: "password123",
    role: "participant"
  },
  {
    name: "David Kim",
    email: "david@example.com",
    password: "password123", 
    password_confirmation: "password123",
    role: "participant"
  },
  {
    name: "Aisha Patel",
    email: "aisha@example.com",
    password: "password123",
    password_confirmation: "password123", 
    role: "participant"
  },
  {
    name: "James Wilson",
    email: "james@example.com",
    password: "password123",
    password_confirmation: "password123",
    role: "participant"
  },
  {
    name: "Maria Santos",
    email: "maria@example.com",
    password: "password123",
    password_confirmation: "password123",
    role: "participant"
  },
  {
    name: "Ahmed Hassan",
    email: "ahmed@example.com",
    password: "password123",
    password_confirmation: "password123",
    role: "participant"
  },
  {
    name: "Lisa Thompson",
    email: "lisa@example.com",
    password: "password123",
    password_confirmation: "password123",
    role: "participant"
  }
]

participant_users = participants.map { |attrs| User.create!(attrs) }
all_users = [admin] + participant_users

puts "✅ Created #{all_users.count} users (1 admin, #{participant_users.count} participants)"

# Create Budgets
puts "💰 Creating budgets..."

budgets_data = [
  {
    title: "Community Development Budget 2024",
    description: "Annual community budget focusing on infrastructure improvements, social programs, and environmental initiatives. This budget aims to address the most pressing needs identified through community surveys and town halls.",
    total_amount: 2_500_000,
    start_date: 1.month.ago,
    end_date: 2.months.from_now,
    status: "active",
    user: admin
  },
  {
    title: "Green Infrastructure Initiative 2024",
    description: "Special budget dedicated to sustainable and environmentally-friendly infrastructure projects. Focus on renewable energy, green buildings, and carbon footprint reduction.",
    total_amount: 1_800_000,
    start_date: 2.weeks.ago,
    end_date: 6.weeks.from_now,
    status: "active", 
    user: admin
  },
  {
    title: "Social Services Enhancement Budget",
    description: "Budget allocated for improving social services including healthcare, education, and community support programs. Aims to reduce inequality and improve quality of life.",
    total_amount: 3_200_000,
    start_date: 1.week.from_now,
    end_date: 3.months.from_now,
    status: "draft",
    user: admin
  },
  {
    title: "Digital Transformation Budget 2023",
    description: "Completed budget from last year focused on digital infrastructure and technology improvements. Includes broadband expansion and digital literacy programs.",
    total_amount: 1_500_000,
    start_date: 6.months.ago,
    end_date: 1.month.ago,
    status: "completed",
    user: admin
  }
]

budgets = budgets_data.map { |attrs| Budget.create!(attrs) }
puts "✅ Created #{budgets.count} budgets"

# Create Budget Categories
puts "🏷️ Creating budget categories..."

categories_data = [
  # Community Development Budget categories
  [
    {
      name: "Infrastructure",
      description: "Roads, bridges, public buildings, utilities, and transportation systems",
      spending_limit_percentage: 40,
      budget: budgets[0]
    },
    {
      name: "Social Programs", 
      description: "Education, healthcare, community centers, and social support services",
      spending_limit_percentage: 30,
      budget: budgets[0]
    },
    {
      name: "Environment",
      description: "Parks, green spaces, environmental protection, and sustainability projects",
      spending_limit_percentage: 20,
      budget: budgets[0]
    },
    {
      name: "Technology",
      description: "Digital infrastructure, IT systems, and technology innovation",
      spending_limit_percentage: 10,
      budget: budgets[0]
    }
  ],
  # Green Infrastructure Initiative categories
  [
    {
      name: "Renewable Energy",
      description: "Solar panels, wind turbines, and other renewable energy projects",
      spending_limit_percentage: 45,
      budget: budgets[1]
    },
    {
      name: "Green Buildings",
      description: "LEED certified buildings, energy efficient retrofits, and sustainable construction",
      spending_limit_percentage: 35,
      budget: budgets[1]
    },
    {
      name: "Environmental Restoration",
      description: "Ecosystem restoration, biodiversity projects, and pollution cleanup",
      spending_limit_percentage: 20,
      budget: budgets[1]
    }
  ],
  # Social Services Enhancement categories
  [
    {
      name: "Healthcare",
      description: "Medical facilities, health programs, and wellness initiatives",
      spending_limit_percentage: 50,
      budget: budgets[2]
    },
    {
      name: "Education",
      description: "Schools, educational programs, and learning resources",
      spending_limit_percentage: 35,
      budget: budgets[2]
    },
    {
      name: "Community Support",
      description: "Social assistance, community programs, and support services",
      spending_limit_percentage: 15,
      budget: budgets[2]
    }
  ],
  # Digital Transformation categories
  [
    {
      name: "Broadband Infrastructure",
      description: "High-speed internet access and telecommunications infrastructure",
      spending_limit_percentage: 60,
      budget: budgets[3]
    },
    {
      name: "Digital Services",
      description: "Online government services and digital platforms",
      spending_limit_percentage: 25,
      budget: budgets[3]
    },
    {
      name: "Digital Literacy",
      description: "Training programs and digital education initiatives",
      spending_limit_percentage: 15,
      budget: budgets[3]
    }
  ]
]

all_categories = []
categories_data.each { |budget_categories| all_categories += budget_categories.map { |attrs| BudgetCategory.create!(attrs) } }
puts "✅ Created #{all_categories.count} budget categories"

# Create Budget Phases
puts "📅 Creating budget phases..."

# Phases for Community Development Budget (active)
[
  {
    name: "Project Submission",
    description: "Community members submit project proposals and ideas",
    phase_type: "submission",
    start_date: 30.days.ago,
    end_date: 23.days.ago,
    status: "completed",
    budget: budgets[0],
    voting_rules: { max_votes_per_user: 10, requires_justification: false }.to_json,
    participant_eligibility: "all_participants"
  },
  {
    name: "Project Review",
    description: "Technical review and feasibility assessment of submitted projects",
    phase_type: "review", 
    start_date: 22.days.ago,
    end_date: 8.days.ago,
    status: "completed",
    budget: budgets[0],
    voting_rules: { max_votes_per_user: 5, requires_justification: true }.to_json,
    participant_eligibility: "all_participants"
  },
  {
    name: "Community Voting",
    description: "Community votes on approved projects to determine funding priorities",
    phase_type: "voting",
    start_date: 7.days.ago,
    end_date: 30.days.from_now,
    status: "active",
    budget: budgets[0],
    voting_rules: { max_votes_per_user: 3, min_vote_weight: -5, max_vote_weight: 5 }.to_json,
    participant_eligibility: "all_participants"
  },
  {
    name: "Implementation",
    description: "Approved projects begin implementation and progress tracking",
    phase_type: "implementation",
    start_date: 31.days.from_now,
    end_date: 60.days.from_now,
    status: "pending",
    budget: budgets[0],
    voting_rules: {}.to_json,
    participant_eligibility: "all_participants"
  }
].each { |attrs| BudgetPhase.create!(attrs) }

# Phases for Green Infrastructure Initiative (active)
[
  {
    name: "Environmental Assessment",
    description: "Assessment of environmental impact and sustainability requirements",
    phase_type: "review",
    start_date: 14.days.ago,
    end_date: 6.days.ago,
    status: "completed",
    budget: budgets[1],
    voting_rules: {}.to_json,
    participant_eligibility: "all_participants"
  },
  {
    name: "Green Project Voting",
    description: "Community voting focused on environmental impact and sustainability",
    phase_type: "voting",
    start_date: 5.days.ago,
    end_date: 35.days.from_now,
    status: "active",
    budget: budgets[1],
    voting_rules: { max_votes_per_user: 5, requires_justification: true }.to_json,
    participant_eligibility: "all_participants"
  }
].each { |attrs| BudgetPhase.create!(attrs) }

puts "✅ Created budget phases"

# Create Budget Projects
puts "🏗️ Creating budget projects..."

projects_data = [
  # Community Development Budget projects
  {
    title: "Downtown Pedestrian Bridge",
    description: "Construction of a modern pedestrian bridge connecting downtown shopping district with residential areas. The bridge will feature LED lighting, accessibility ramps, and space for public art installations.",
    amount: 450_000,
    status: "pending",
    budget_category: all_categories.find { |c| c.name == "Infrastructure" && c.budget == budgets[0] },
    user: participant_users[0]
  },
  {
    title: "Community Health and Wellness Center",
    description: "Establishment of a comprehensive health center offering medical services, fitness programs, mental health support, and community wellness workshops for all age groups.",
    amount: 680_000,
    status: "pending",
    budget_category: all_categories.find { |c| c.name == "Social Programs" && c.budget == budgets[0] },
    user: participant_users[1]
  },
  {
    title: "Central Park Renovation and Expansion",
    description: "Complete renovation of Central Park including new playground equipment, walking trails, community gardens, outdoor fitness equipment, and a small amphitheater for community events.",
    amount: 320_000,
    status: "approved",
    budget_category: all_categories.find { |c| c.name == "Environment" && c.budget == budgets[0] },
    user: participant_users[2]
  },
  {
    title: "Smart City Traffic Management System",
    description: "Implementation of AI-powered traffic management system with smart traffic lights, real-time traffic monitoring, and mobile app for citizens to report traffic issues.",
    amount: 180_000,
    status: "pending",
    budget_category: all_categories.find { |c| c.name == "Technology" && c.budget == budgets[0] },
    user: participant_users[3]
  },
  {
    title: "New Public Library Branch",
    description: "Construction of a modern library branch in the north district featuring computer labs, study rooms, children's reading area, and community meeting spaces.",
    amount: 520_000,
    status: "pending", 
    budget_category: all_categories.find { |c| c.name == "Social Programs" && c.budget == budgets[0] },
    user: participant_users[4]
  },
  {
    title: "Street Lighting LED Upgrade",
    description: "Citywide upgrade of street lighting to energy-efficient LED systems with smart controls and improved coverage for enhanced safety and reduced energy costs.",
    amount: 290_000,
    status: "approved",
    budget_category: all_categories.find { |c| c.name == "Infrastructure" && c.budget == budgets[0] },
    user: participant_users[5]
  },
  {
    title: "Youth Development Center",
    description: "Creation of a dedicated facility for youth programs including after-school tutoring, sports programs, arts and crafts workshops, and career development services.",
    amount: 380_000,
    status: "pending",
    budget_category: all_categories.find { |c| c.name == "Social Programs" && c.budget == budgets[0] },
    user: participant_users[6]
  },
  {
    title: "Urban Tree Planting Initiative",
    description: "Comprehensive urban forestry program to plant 5,000 native trees throughout the city, including maintenance plan and community engagement activities.",
    amount: 125_000,
    status: "approved",
    budget_category: all_categories.find { |c| c.name == "Environment" && c.budget == budgets[0] },
    user: participant_users[7]
  },

  # Green Infrastructure Initiative projects  
  {
    title: "Solar Panel Installation Program",
    description: "Installation of solar panels on 50 public buildings including schools, libraries, and municipal offices to reduce carbon footprint and energy costs.",
    amount: 650_000,
    status: "pending",
    budget_category: all_categories.find { |c| c.name == "Renewable Energy" && c.budget == budgets[1] },
    user: participant_users[0]
  },
  {
    title: "Green Roof Initiative",
    description: "Installation of green roofs on 20 public buildings to improve insulation, reduce stormwater runoff, and create urban habitat for wildlife.",
    amount: 420_000,
    status: "pending",
    budget_category: all_categories.find { |c| c.name == "Green Buildings" && c.budget == budgets[1] },
    user: participant_users[1]
  },
  {
    title: "Wetland Restoration Project",
    description: "Restoration of 50 acres of wetlands to improve water quality, provide flood protection, and create habitat for native species.",
    amount: 280_000,
    status: "approved",
    budget_category: all_categories.find { |c| c.name == "Environmental Restoration" && c.budget == budgets[1] },
    user: participant_users[2]
  },
  {
    title: "Electric Vehicle Charging Network",
    description: "Installation of 100 electric vehicle charging stations throughout the city to support the transition to clean transportation.",
    amount: 340_000,
    status: "pending",
    budget_category: all_categories.find { |c| c.name == "Renewable Energy" && c.budget == budgets[1] },
    user: participant_users[3]
  }
]

projects = projects_data.map do |attrs|
  project = BudgetProject.new(attrs)
  project.save(validate: false) # Skip validations for seeding
  project
end
puts "✅ Created #{projects.count} budget projects"

# Create Impact Metrics
puts "📊 Creating impact metrics..."

impact_metrics_data = [
  {
    estimated_beneficiaries: 15_000,
    timeline_months: 18,
    sustainability_score: 8.5,
    environmental_impact: "positive",
    social_impact: "very_positive",
    economic_impact: "positive",
    budget_project: projects[0] # Downtown Pedestrian Bridge
  },
  {
    estimated_beneficiaries: 25_000,
    timeline_months: 24,
    sustainability_score: 9.2,
    environmental_impact: "neutral",
    social_impact: "very_positive",
    economic_impact: "positive",
    budget_project: projects[1] # Community Health Center
  },
  {
    estimated_beneficiaries: 8_000,
    timeline_months: 12,
    sustainability_score: 7.8,
    environmental_impact: "very_positive",
    social_impact: "positive",
    economic_impact: "neutral",
    budget_project: projects[2] # Central Park Renovation
  },
  {
    estimated_beneficiaries: 50_000,
    timeline_months: 15,
    sustainability_score: 6.5,
    environmental_impact: "positive",
    social_impact: "positive",
    economic_impact: "very_positive",
    budget_project: projects[3] # Smart Traffic System
  },
  {
    estimated_beneficiaries: 12_000,
    timeline_months: 20,
    sustainability_score: 8.0,
    environmental_impact: "neutral",
    social_impact: "very_positive",
    economic_impact: "positive",
    budget_project: projects[4] # New Library
  },
  {
    estimated_beneficiaries: 75_000,
    timeline_months: 8,
    sustainability_score: 9.1,
    environmental_impact: "very_positive",
    social_impact: "positive",
    economic_impact: "very_positive",
    budget_project: projects[5] # LED Street Lighting
  },
  {
    estimated_beneficiaries: 3_500,
    timeline_months: 16,
    sustainability_score: 7.5,
    environmental_impact: "neutral",
    social_impact: "very_positive",
    economic_impact: "positive",
    budget_project: projects[6] # Youth Center
  },
  {
    estimated_beneficiaries: 100_000,
    timeline_months: 36,
    sustainability_score: 9.5,
    environmental_impact: "very_positive",
    social_impact: "positive",
    economic_impact: "positive",
    budget_project: projects[7] # Tree Planting
  },
  {
    estimated_beneficiaries: 80_000,
    timeline_months: 18,
    sustainability_score: 9.8,
    environmental_impact: "very_positive",
    social_impact: "positive",
    economic_impact: "very_positive",
    budget_project: projects[8] # Solar Panels
  },
  {
    estimated_beneficiaries: 45_000,
    timeline_months: 14,
    sustainability_score: 8.7,
    environmental_impact: "very_positive",
    social_impact: "positive",
    economic_impact: "positive",
    budget_project: projects[9] # Green Roofs
  },
  {
    estimated_beneficiaries: 200_000,
    timeline_months: 30,
    sustainability_score: 9.0,
    environmental_impact: "very_positive",
    social_impact: "positive",
    economic_impact: "neutral",
    budget_project: projects[10] # Wetland Restoration
  },
  {
    estimated_beneficiaries: 60_000,
    timeline_months: 12,
    sustainability_score: 8.3,
    environmental_impact: "very_positive",
    social_impact: "positive",
    economic_impact: "positive",
    budget_project: projects[11] # EV Charging
  }
]

impact_metrics = impact_metrics_data.map { |attrs| ImpactMetric.create!(attrs) }
puts "✅ Created #{impact_metrics.count} impact metrics"

# Create Votes
puts "🗳️ Creating votes..."

# Get active phases for voting
active_phases = BudgetPhase.where(status: "active")
votable_projects = projects.select { |p| p.budget_category.budget.active? }

vote_count = 0
participant_users.each do |user|
  # Each user votes on 3-7 random projects
  projects_to_vote = votable_projects.sample(rand(3..7))
  
  projects_to_vote.each do |project|
    # Get the current active phase for this project's budget
    current_phase = project.budget_category.budget.current_phase
    next unless current_phase&.allows_voting?
    
    # Create vote with random weight
    vote_weight = [-3, -2, -1, 1, 2, 3, 4, 5].sample
    justification = if vote_weight > 0
      [
        "This project would greatly benefit our community and addresses a real need.",
        "I strongly support this initiative - it aligns with our community values.",
        "Excellent project that will have lasting positive impact.",
        "This is exactly what our neighborhood needs right now.",
        "Great use of public funds with clear benefits for residents."
      ].sample
    else
      [
        "I have concerns about the cost-benefit ratio of this project.", 
        "While well-intentioned, I think our funds could be better allocated elsewhere.",
        "This project may not address our most pressing community needs.",
        "I question whether this is the right priority at this time."
      ].sample
    end
    
    Vote.create!(
      user: user,
      budget_project: project,
      budget_phase: current_phase,
      vote_weight: vote_weight
    )
    vote_count += 1
  end
end

puts "✅ Created #{vote_count} votes"

# Summary
puts "\n🎉 Seed data creation completed!"
puts "=" * 50
puts "📊 Summary:"
puts "  👥 Users: #{User.count} (#{User.admin.count} admin, #{User.participant.count} participants)"
puts "  💰 Budgets: #{Budget.count} (#{Budget.active.count} active, #{Budget.where(status: 'draft').count} draft, #{Budget.where(status: 'completed').count} completed)"
puts "  🏷️ Categories: #{BudgetCategory.count}"
puts "  📅 Phases: #{BudgetPhase.count} (#{BudgetPhase.active.count} active)"
puts "  🏗️ Projects: #{BudgetProject.count} (#{BudgetProject.approved.count} approved, #{BudgetProject.pending.count} pending)"
puts "  📊 Impact Metrics: #{ImpactMetric.count}"
puts "  🗳️ Votes: #{Vote.count}"
puts "=" * 50
puts "\n🔑 Admin Login:"
puts "  Email: admin@participatorybudget.com"
puts "  Password: password123"
puts "\n👤 Participant Login (any of these):"
participant_users.first(3).each do |user|
  puts "  Email: #{user.email} | Password: password123"
end
puts "\n🚀 Ready to explore the Participatory Budgeting System!"

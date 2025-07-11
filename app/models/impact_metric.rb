class ImpactMetric < ApplicationRecord
  belongs_to :budget_project

  # Validations
  validates :estimated_beneficiaries, presence: true, 
            numericality: { 
              greater_than: 0, 
              less_than: 1_000_000,
              message: "must be a positive number less than 1,000,000"
            }
  validates :timeline_months, presence: true,
            numericality: { 
              greater_than: 0, 
              less_than_or_equal_to: 120,
              message: "must be between 1 and 120 months"
            }
  validates :sustainability_score, presence: true,
            numericality: { 
              greater_than_or_equal_to: 0, 
              less_than_or_equal_to: 10,
              message: "must be between 0 and 10"
            }
  validates :environmental_impact, :social_impact, :economic_impact, 
            inclusion: { 
              in: %w[very_negative negative neutral positive very_positive],
              message: "%{value} is not a valid impact level"
            }

  # Enums
  enum environmental_impact: {
    very_negative: 'very_negative',
    negative: 'negative',
    neutral: 'neutral',
    positive: 'positive',
    very_positive: 'very_positive'
  }, _prefix: :environmental

  enum social_impact: {
    very_negative: 'very_negative',
    negative: 'negative', 
    neutral: 'neutral',
    positive: 'positive',
    very_positive: 'very_positive'
  }, _prefix: :social

  enum economic_impact: {
    very_negative: 'very_negative',
    negative: 'negative',
    neutral: 'neutral', 
    positive: 'positive',
    very_positive: 'very_positive'
  }, _prefix: :economic

  # Scopes
  scope :high_impact, -> { where('sustainability_score >= ?', 7) }
  scope :medium_impact, -> { where('sustainability_score >= ? AND sustainability_score < ?', 4, 7) }
  scope :low_impact, -> { where('sustainability_score < ?', 4) }
  scope :short_term, -> { where('timeline_months <= ?', 12) }
  scope :medium_term, -> { where('timeline_months > ? AND timeline_months <= ?', 12, 36) }
  scope :long_term, -> { where('timeline_months > ?', 36) }
  scope :positive_environmental, -> { environmental_positive.or(environmental_very_positive) }
  scope :positive_social, -> { social_positive.or(social_very_positive) }
  scope :positive_economic, -> { economic_positive.or(economic_very_positive) }

  # Instance methods
  def beneficiaries_per_dollar
    return 0 if budget_project.amount <= 0
    (estimated_beneficiaries.to_f / budget_project.amount).round(4)
  end

  def impact_efficiency_score
    # Composite score considering beneficiaries per dollar and sustainability
    efficiency = beneficiaries_per_dollar * 1000 # Scale for readability
    sustainability_weight = sustainability_score / 10.0
    timeline_weight = timeline_months > 0 ? [24.0 / timeline_months, 2].min : 0
    
    (efficiency * sustainability_weight * timeline_weight).round(2)
  end

  def overall_impact_score
    # Weighted composite score of all impact dimensions
    env_score = impact_level_to_score(environmental_impact)
    social_score = impact_level_to_score(social_impact)
    economic_score = impact_level_to_score(economic_impact)
    
    # Weights: social 40%, environmental 30%, economic 30%
    weighted_score = (social_score * 0.4 + env_score * 0.3 + economic_score * 0.3)
    
    # Factor in sustainability and timeline
    sustainability_factor = sustainability_score / 10.0
    timeline_factor = case timeline_months
                     when 0..6 then 0.8    # Very short term gets penalty
                     when 7..18 then 1.0   # Sweet spot
                     when 19..36 then 0.9  # Medium term slight penalty
                     else 0.7              # Long term bigger penalty
                     end
    
    (weighted_score * sustainability_factor * timeline_factor).round(2)
  end

  def impact_category
    score = overall_impact_score
    case score
    when 0...2
      'Low Impact'
    when 2...4
      'Medium Impact'
    when 4...6
      'High Impact'
    when 6..10
      'Exceptional Impact'
    else
      'Unrated'
    end
  end

  def impact_category_color
    case impact_category
    when 'Low Impact'
      'danger'
    when 'Medium Impact'
      'warning'
    when 'High Impact'
      'success'
    when 'Exceptional Impact'
      'primary'
    else
      'secondary'
    end
  end

  def environmental_impact_description
    case environmental_impact
    when 'very_negative'
      'Significant environmental harm'
    when 'negative'
      'Some environmental concerns'
    when 'neutral'
      'No significant environmental impact'
    when 'positive'
      'Positive environmental benefits'
    when 'very_positive'
      'Major environmental improvements'
    else
      'Not assessed'
    end
  end

  def social_impact_description
    case social_impact
    when 'very_negative'
      'Potential social harm or exclusion'
    when 'negative'
      'Some social concerns'
    when 'neutral'
      'No significant social impact'
    when 'positive'
      'Positive social benefits'
    when 'very_positive'
      'Major social improvements'
    else
      'Not assessed'
    end
  end

  def economic_impact_description
    case economic_impact
    when 'very_negative'
      'Significant economic burden'
    when 'negative'
      'Some economic concerns'
    when 'neutral'
      'No significant economic impact'
    when 'positive'
      'Positive economic benefits'
    when 'very_positive'
      'Major economic improvements'
    else
      'Not assessed'
    end
  end

  def timeline_description
    case timeline_months
    when 0..3
      'Immediate (0-3 months)'
    when 4..12
      'Short-term (4-12 months)'
    when 13..24
      'Medium-term (1-2 years)'
    when 25..60
      'Long-term (2-5 years)'
    else
      'Extended timeline (5+ years)'
    end
  end

  def sustainability_description
    case sustainability_score
    when 0...3
      'Low sustainability - requires ongoing support'
    when 3...6
      'Moderate sustainability - some ongoing needs'
    when 6...8
      'Good sustainability - mostly self-sustaining'
    when 8..10
      'Excellent sustainability - fully self-sustaining'
    else
      'Not assessed'
    end
  end

  def cost_per_beneficiary
    return 0 if estimated_beneficiaries <= 0
    (budget_project.amount / estimated_beneficiaries).round(2)
  end

  def quick_impact_summary
    {
      beneficiaries: estimated_beneficiaries,
      timeline: timeline_description,
      sustainability: sustainability_description,
      overall_score: overall_impact_score,
      category: impact_category,
      cost_per_beneficiary: cost_per_beneficiary
    }
  end

  # Class methods
  def self.average_scores_for_category(budget_category)
    metrics = joins(:budget_project).where(budget_projects: { budget_category: budget_category })
    
    {
      avg_beneficiaries: metrics.average(:estimated_beneficiaries)&.round(0) || 0,
      avg_timeline: metrics.average(:timeline_months)&.round(1) || 0,
      avg_sustainability: metrics.average(:sustainability_score)&.round(2) || 0,
      avg_overall_impact: metrics.average('overall_impact_score')&.round(2) || 0,
      total_beneficiaries: metrics.sum(:estimated_beneficiaries) || 0
    }
  end

  def self.impact_distribution
    all_metrics = all
    total = all_metrics.count
    return {} if total == 0
    
    {
      environmental: group(:environmental_impact).count.transform_values { |v| (v.to_f / total * 100).round(1) },
      social: group(:social_impact).count.transform_values { |v| (v.to_f / total * 100).round(1) },
      economic: group(:economic_impact).count.transform_values { |v| (v.to_f / total * 100).round(1) }
    }
  end

  private

  def impact_level_to_score(level)
    case level
    when 'very_negative'
      1
    when 'negative'
      2
    when 'neutral'
      3
    when 'positive'
      4
    when 'very_positive'
      5
    else
      3 # Default to neutral
    end
  end
end

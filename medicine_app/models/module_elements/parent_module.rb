class ParentModule < ModuleElement
    validates_uniqueness_of :name
    validate :no_parent, :no_question

    has_many :organization_parent_module_mappings
    has_many :condition_parent_module_mappings
    has_many :condition_groups, through: :condition_parent_module_mappings
    has_many :questions, through: :children

    scope :patient, -> (patient_id) {
      joins("INNER JOIN patient_module_mappings on module_elements.id = parent_module_id")
      .where("patient_id = ?", patient_id)
    }

    scope :disease_specific, ->{
      joins("INNER JOIN condition_parent_module_mappings
          on module_elements.id=condition_parent_module_mappings.parent_module_id")
    }

    scope :by_conditions, -> (conds) {
      disease_specific
      .joins("INNER JOIN condition_group_mappings
                on condition_parent_module_mappings.condition_group_id = condition_group_mappings.condition_group_id")
      .joins("INNER JOIN condition_categories
                on condition_group_mappings.condition_category_id = condition_categories.id")
      .joins("INNER JOIN conditions on condition_categories.id = conditions.condition_category_id")
      .merge(Condition.where(id: conds))
      .select("DISTINCT ON (module_elements.id) module_elements.*")}

    scope :by_patient_conditions, -> (patient) {by_conditions(patient.conditions)}

    ELEMENTS_ORDER = [
      'Health Update',
      'General Health Assessment',
      'Multimorbidity',
      'Diabetes',
      'Hypertension',
      'COPD',
      'Congestive Heart Failure',
      'Smoking Cessation',
      'HIV Adherence',
      'Disease Specific',
      'Follow Up',
      'Other',
      'Care Management Continuity',
      'Satisfaction Survey',
      'Depression Assessment'
    ].freeze

    def self.elements_order
      ELEMENTS_ORDER
    end

    def no_parent
        self.errors.add(:parent_id, "Must be nil") unless self.parent_id.nil?
    end

    def no_question
        self.errors.add(:question_id, "Must be nil") unless self.question_id.nil?
    end

end

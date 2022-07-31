class Document < ApplicationRecord
  include EventsRelation
  PATIENT_DOC_TYPES = %w(progress_note consult_note patient_education
                        patient_photo patient_consent lab_or_imaging
                        order other)
  ORG_DOC_TYPES = %w(invoice care_services report
                    training other patient_education)
  ENTITY_TYPES = %w(Patient Organization)
  PERMISSIONS = %w(private public global)
  has_paper_trail
  has_mappings
  has_events :document_delivery

  belongs_to :file, class_name: 'Filestore'
  belongs_to :entity, polymorphic: true

  validates_inclusion_of :entity_type, in: ENTITY_TYPES
  validates_inclusion_of :permissions, in: %w(private public global)
  validates_presence_of :entity_type, :entity_id
  validate :entity_must_exist

  before_validation :set_defaults, on: :create

  after_save :notify

  scope :patient_documents, -> {where(entity_type: "Patient")}
  scope :organization_documents, -> {where(entity_type: "Organization")}
  scope :public_permissions, -> {where(permissions: 'public')}
  scope :global, -> {where(permissions: :global)}
  scope :non_global, -> {where.not(permissions: :global)}
  scope :active, -> {where("archived IS NULL OR archived = false")}
  scope :pdf, -> {joins(:file).merge(Filestore.pdf)}
  scope :by_file_name, -> (file_name) {
    joins(:file)
    .where({filestores: {file_name: file_name}})
  }

  def set_file(filename, file=nil)
    if !self.file
     self.file = Filestore.create({file_type: 'patient_document', file_name: filename, file: file})
    end
  end

  def set_user(user)
    @user = user
  end

  def filename
    self.file.file_name if self.file
  end

  def delete_file
    self.file.destroy
  end

  def entity
    if self.entity_type == 'Patient'
      return Patient.find(self.entity_id)
    elsif self.entity_type == 'Organization'
      return Organization.find(self.entity_id)
    end
  end

  def entity_must_exist
    if (self.entity_type=="Patient" && !Patient.exists?(self.entity_id)) || (self.entity_type=="Organization" && !Organization.exists?(self.entity_id))
      errors.add(:entity_id, "#{self.entity_type} does not exist")
    end
  end

  def notify
    return unless organization?
    data = {
      organization_code: entity.code,
      event: "Events::Document::Upload",
      meta: {
        file_name: self.file.file_name,
        document_id: id
      },
      user_id: @user.try(:id)
    }
    NotificationJob.set(wait_until: 30.seconds.from_now).perform_later(data)
  end

  def organization?
    entity_type == 'Organization'
  end

  def read
    self.file && self.file.file.read
  end

  # Defining #{permission}? instance methods
  self.class_eval do
    PERMISSIONS.each do |permission|
      define_method :"#{permission}?" do
        self.send('permissions') == permission
      end
    end
  end

  private

    def set_defaults
      self.document_type ||= 'other'
      self.permissions ||= 'private'
    end
end

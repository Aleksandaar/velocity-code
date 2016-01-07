class GroupEvent < ActiveRecord::Base

  # Attributes
  enum status: { draft: 0, published: 1 }

  # Validations
  validates :name, :description, :location, :start_date, :end_date, :duration, presence: true, if: Proc.new{|e| e.published? }

  # Callbacks
  #before_save :update_dates

  # Scopes
  default_scope { where(deleted_at: nil) }

  def destroy
    run_callbacks :destroy do
      update! deleted_at: DateTime.now
    end
  end

  def duration=(value)
    super(value.present? ? value.to_i : value)
    self.start_date.present? ? update_end_date : update_start_date if self.duration != self.duration_was
  end

  def end_date=(value)
    super(value)
    self.start_date.present? ?  update_duration : update_start_date if self.end_date != self.end_date_was
  end

  def start_date=(value)
    super(value)
    self.duration.present? ? update_end_date : update_duration if self.start_date != self.start_date_was
  end

  def to_hash
    self.attributes.except('id').to_hash
  end

  private

  def update_end_date
    write_attribute(:end_date, self.start_date + self.duration) if self.start_date && self.duration
  end

  def update_start_date
    write_attribute(:start_date, self.end_date - self.duration) if self.end_date && self.duration
  end

  def update_duration
    write_attribute(:duration, (self.end_date - self.start_date).to_i) if self.end_date && self.start_date
  end
end
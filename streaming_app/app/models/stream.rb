class Stream < ActiveRecord::Base
  # Concerns
  include Destroyable
  include Tokenable
  include Sanitizable

  # Settings
  tokenable_by 6
  paginates_per 12
  sanitizable_by :title, :description

  # Attributes
  enum status: { ended: 0, live: 1, disconnected: 2, allocated: 3, user_started: 4, user_stopped: 5, in_process: 6 }

  # Associations
  belongs_to :creator, foreign_key: :user_id, class_name: User
  has_many :archive_videos, as: :source, dependent: :destroy
  has_one :archive_video, -> { order(created_at: :desc) }, as: :source
  has_one :promoted_archive_video, -> { ArchiveVideo.promoted }, class_name: ArchiveVideo, as: :source
  has_and_belongs_to_many :channels
  has_and_belongs_to_many :gps_locations, -> { order(created_at: :desc) }

  # Validations
  validates :creator, presence: true
  validates :title, allow_blank: true, length: { maximum: 255 }

  # Callbacks
  before_create :set_privacy
  before_destroy { gps_locations.each(&:destroy) }
  after_save :notify_followers, if: -> { !is_private? && live? && status_changed? }
  # after_save :set_channel, if: -> { live? && status_changed? }

  # Scopes
  scope :by_channel, ->(channel) { includes(:channels).where(channels: { id: channel }) }
  scope :unrestricted, -> { where is_private: false }
  scope :watchable, -> { where status: [statuses[:ended], statuses[:live]] }
  scope :include_related, -> { includes :archive_video, :channels, :creator, :gps_locations }
  scope :include_all_related, -> { includes :creator, :gps_locations, archive_videos: [:user, source: :creator] }
  scope :promoted, -> { unrestricted.where('is_promoted = ? OR status = ?', true, statuses[:live]) }
  scope :default_order, -> { order updated_at: :desc }

  def name
    creator.name
  end

  def rtmp_name
    "s-#{token}"
  end
  alias_method :rtmp_stream_id, :rtmp_name

  def stop!
    # Update status
    user_stopped!

    # Drop encoder
    drop
  end

  def drop
    Wowza.drop_encoder rtmp_name
  end

  def owner?(owner)
    creator == owner
  end

  def rtmp
    Wowza.generate_encoder_pool_rtmp_url rtmp_name
  end
  alias_method :rtmp_endpoint, :rtmp

  def rtmp_watch
    Wowza.generate_watch_pool_rtmp_url rtmp_name
  end

  def pool_server_ip
    Wowza.get_pool_stream_ip rtmp_name
  end

  def hds_url
    "#{ENV.fetch('WOWZA_LIVESTREAM_URL')}/stream/#{rtmp_name}/manifest.f4m"
  end

  def hls_url
    "#{ENV.fetch('WOWZA_LIVESTREAM_URL')}/stream/#{rtmp_name}/playlist.m3u8"
  end

  # Placeholder until real thumbnail generation is implemented
  def thumbnail
    ActionController::Base.helpers.asset_path('default_live_thumbnail.jpg')
  end

  def current_stream
    self
  end

  def chat_room
    "stream-#{token}"
  end

  def url
    Rails.application.routes.url_helpers.watch_user_url(creator.username, token: token, host: Rails.application.config.action_mailer.default_url_options[:host])
  end
  alias_method :webapp_url, :url

  def to_param
    token
  end

  def exists_on_wowza?
    Wowza.stream_exists? rtmp_name
  end

  def channel_names
    channels.present? ? channels.map(&:name).sort.join(', ') : I18n.t('stream.no_channels')
  end

  def notify_followers
    Resque.enqueue NotifyFollowers, token
  end

  def api_model_data(options = {})
    data = {
      type: self.class.name.downcase,
      token: token,
      status: status,
      title: title,
      description: description,
      views_counter: views_counter,
      date_time: updated_at,
      gps_location: gps_locations.limit(5).map(&:api_model_data),
      url: webapp_url,
      hls_url: hls_url,
      rtmp_stream_id: rtmp_name,
      is_private: is_private,
      creator: creator.api_model_data,
    }
    data[:live_views_counter] = live_views_counter if live?
    data[:archive_videos] = archive_videos.map(&:api_model_data) if options[:archive_videos] != false
    data.as_json
  end

  def api_model_data_create(options = {})
    api_model_data.merge({ rtmp_endpoint: rtmp_endpoint }).as_json
  end

  def title_description_matches?(pattern)
    regex_pattern = /#{pattern}/i
    title =~ regex_pattern || description =~ regex_pattern
  end

  def live_views_counter
    SourceWatcher.new(self).count
  end

  private
    def set_privacy
      self.is_private = creator.streaming_default_private
      nil
    end

    def set_channel
      Resque.enqueue SetChannel, token
    end
end

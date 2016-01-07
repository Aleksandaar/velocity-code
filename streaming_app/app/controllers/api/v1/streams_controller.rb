module Api
  module V1
    class StreamsController < BaseSessionController
      before_action :authenticate_user!, except: %i(create get get_live promoted start_create watching)
      before_action :ensure_current_user!, only: %i(create start_create)
      before_action :ensure_stream_found!, only: %i(get join renew start status stop update watching)
      before_action :ensure_stream_owner!, only: %i(join renew start status stop update)
      before_action :ensure_is_solo_flag!, only: %i(join start_create)
      before_action :ensure_channels_found!, only: %i(join start_create), unless: -> { @is_solo }
      before_action :ensure_user_subscribed!, only: %i(join start_create), unless: -> { @is_solo }
      before_action :set_pagination_params, only: %i(get_live promoted)

      # Create Stream
      def create
        begin
          stream = Stream.create! creator: current_user, status: :allocated
        rescue *RecoverableExceptions => e
          Bugsnag.notify(e)
          return error(E_INTERNAL, e.message)
        end

        success(streams: stream.api_model_data_create)
      end

      # Start stream
      def start
        begin
          @stream.user_started!
        rescue *RecoverableExceptions => e
          Bugsnag.notify(e)
          return error(E_INTERNAL, e.message)
        end

        success(streams: @stream.api_model_data)
      end

      # Stop Stream
      def stop
        begin
          @stream.user_stopped!
        rescue *RecoverableExceptions => e
          Bugsnag.notify(e)
          return error(E_INTERNAL, e.message)
        end

        success(streams: @stream.api_model_data)
      end

      # Create gps location for a given stream
      def status
        metadata = stream_params.fetch(:metadata)
        gps_data = metadata.fetch(:gps){ {} }

        begin
          @stream.update! metadata: metadata.to_json
          @stream.gps_locations << GpsLocation.new(gps_data.merge(session: @session, user: current_user)) if gps_data.present?
        rescue *RecoverableExceptions => e
          Bugsnag.notify(e)
          return error(E_INTERNAL, e.message)
        end

        success(streams: @stream.reload.api_model_data(archive_videos: false))
      end

      # Renew Wowza rtmp token
      def renew
        @stream.drop if params.fetch(:force_drop, false)
        success(streams: @stream.api_model_data_create)
      end

      # Join channels
      def join
        begin
          Array(@channels).each { |channel| @stream.channels << channel }
        rescue *RecoverableExceptions => e
          Bugsnag.notify(e)
          return error(E_INTERNAL, e.message)
        end

        Resque.enqueue(AcquireLiveStream, @stream.channels.pluck(:id), @stream.id)

        success(streams: @stream.api_model_data)
      end

      # Update Stream
      def update
        begin
          @stream.update! stream_update_params
        rescue *RecoverableExceptions => e
          Bugsnag.notify(e)
          return error(E_INTERNAL, e.message)
        end

        success(streams: @stream.api_model_data)
      end

      def get
        success(streams: @stream.api_model_data)
      end

      def get_live
        streams = Stream.unrestricted.live.order(created_at: :desc).offset(params[:offset]).limit(params[:limit])
        streams.to_a.keep_if(&:exists_on_wowza?)
        success(meta: { limit: params[:limit], offset: params[:offset] }, streams: streams.map(&:api_model_data))
      end

      def promoted
        @streams = Stream.promoted.include_all_related.default_order.offset(params[:offset]).limit(params[:limit]).select do |s|
          !s.live? || s.live? && s.exists_on_wowza?
        end
      end

      def watching
        source_watcher = SourceWatcher.new(@stream, @session.id, current_user)
        source_watcher.save
        @viewers = source_watcher.all
      end

      # Deprecated - create and start stream
      def start_create
        begin
          stream = Stream.create! creator: current_user, channels: Array(@channels), status: :user_started
        rescue *RecoverableExceptions => e
          Bugsnag.notify(e)
          return error(E_INTERNAL, e.message)
        end

        Resque.enqueue(AcquireLiveStream, @channels.map(&:id), stream.id) unless @is_solo

        success(streams: stream.api_model_data_create)
      end

      private
        def ensure_is_solo_flag!
          @is_solo = params.fetch(:channels){ nil }.blank?
        end

        def ensure_channels_found!
          @channels ||= Channel.where token: params[:channels]
          return error(E_RESOURCE_NOT_FOUND, I18n.t('api.errors.channel_not_found')) if @channels.blank?
        end

        def ensure_user_subscribed!
          @channels.each do |channel|
            return error(E_ACCESS_DENIED, I18n.t('api.errors.channel_not_subscribed')) unless channel.user_subscribed?(current_user)
          end
        end

        def ensure_stream_found!
          @stream ||= Stream.accessible_by(current_ability, :read).find_by token: params[:token]
          return error(E_RESOURCE_NOT_FOUND, I18n.t('api.errors.stream_not_found')) if @stream.blank?
        end

        def ensure_stream_owner!
          return error(E_ACCESS_DENIED, I18n.t('api.errors.stream_not_owner')) unless @stream.owner? current_user
        end

        def stream_params
          params.require(:streams).permit metadata: [ { gps: [:latitude, :longitude] }, :time, :orientation, :face_count ]
        end

        def stream_update_params
          params.require(:streams).permit :title, :description, :is_private
        end
    end
  end
end

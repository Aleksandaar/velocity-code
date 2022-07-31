module GoogleCalendar
  module Webhooks
    class EventHandler

      attr_accessor :channel_id, :resource_id

      # ===================================================== #
      #    Errors
      # ===================================================== #

      class RecordNotFound < StandardError
        def message
          "Calendar or resource not found"
        end
      end

      class ProcessingError < StandardError
        def message
          "Calendar syncing failed."
        end
      end

      class ChannelIsInactive < StandardError
        def message
          "Inactive channel. Calendar syncing ingnored."
        end
      end

      # ===================================================== #
      #    .handle
      # ===================================================== #

      def self.handle (channel_id, resource_id)
        new(channel_id, resource_id).call
      end

      # ===================================================== #
      #    Initialize
      # ===================================================== #

      def initialize (channel_id, resource_id)
        @channel_id = channel_id
        @resource_id = resource_id
      end

      def call
        notification_channel = Google::NotificationChannel.find_by(channel_id: channel_id)

        if notification_channel.present?
          if notification_channel.active?
            calendar = notification_channel.calendar

            begin
              syncer = GoogleCalendar::Sync::CalendarSyncer.new(calendar)
              syncer.execute(GoogleCalendar::Sync::Smart) if syncer.syncable?
            rescue StandardError => e
              raise ProcessingError
            end
          else
            raise ChannelIsInactive
          end
        else
          raise RecordNotFound
        end
      end
    end
  end
end
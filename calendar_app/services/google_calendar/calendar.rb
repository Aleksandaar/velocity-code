module GoogleCalendar
  class Calendar < Resource

    include Retryable

    attr_accessor :id, :title
    attr_reader :service

    def initialize (service = nil)
      @service = service
      yield self if block_given?
    end

    # ===========
    # = Exists? =
    # ===========

    def _exists?
      if id.present?
        with_error_response_handling(excluding: 404) do
          service.client.execute({
            :api_method => service.api.calendars.get,
            :parameters => {
              "calendarId" => id
            }
          })
        end.tap do |response|
          return response.status == 404 ? false : true
        end
      else
        false
      end
    end

    # ===========
    # = Create! =
    # ===========

    def _create!
      with_error_response_handling do
        service.client.execute!({
          :api_method => service.api.calendars.insert,
          :body_object => {
            "summary" => title
          },
          :headers => {
            "Content-Type" => "application/json"
          }
        })
      end.tap do |response|
        @id = response.data.id
      end
    end

    # ===========
    # = Update! =
    # ===========

    def _update!
      with_error_response_handling do
        service.client.execute!({
          :api_method => service.api.calendars.update,
          :parameters => {
            "calendarId" => id
          },
          :body_object => {
            "summary" => title
          },
          :headers => {
            "Content-Type" => "application/json"
          }
        })
      end
    end

    # ==========
    # = Delete =
    # ==========

    def _delete!
      with_error_response_handling(excluding: [404, 410]) do
        service.client.execute({
          :api_method => service.api.calendars.delete,
          :parameters => {
            "calendarId" => id,
          },
          :headers => {
            "Content-Type" => "application/json"
          }
        })
      end.tap do |response|
        @id = nil
      end
    end

  end
end

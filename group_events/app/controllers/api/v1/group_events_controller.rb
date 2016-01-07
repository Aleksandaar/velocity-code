module Api
  module V1
    class GroupEventsController < ActionController::Base

      before_action :find_group_event, only: [:edit, :destroy, :show]

      def show
        success(@group_event)
      end

      def edit
        @group_event.update_attributes(group_events_params) ? success(@group_event) : error(500)
      end

      def destroy
        @group_event.destroy ? success : error(500)
      end

      private

      def find_group_event
        @group_event = GroupEvent.find params[:id]
        return error unless @group_event.present?
      end

      def error(code = 404, message = "API Error")
        render json: { status: 'ERROR', error_no: code, message: message }, status: code
      end

      def success(group_event = nil)
        if group_event.present?
          render json: { status: 'OK' }.merge(group_event: group_event.to_hash), status: 200
        else
          render json: { status: 'OK' }, status: 200
        end
      end

      def group_events_params
        params.require(:group_event).permit :name, :description, :duration, :location, :start_date, :end_date, :status
      end
    end
  end
end
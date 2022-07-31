class VitalsController < ApplicationController
    load_and_authorize_resource except: [:create]

    def create
        name = VitalType.find(create_params[:vital_type_id])
        vital = Vital.create(
            patient_id: create_params[:patient_id],
            vital_type_id: create_params[:vital_type_id],
            value: create_params[:value],
            taken_on: create_params[:taken_on],
            notes: create_params[:notes]
        )
        if vital.valid? && can?(:create, vital)
            vital.save
        end
        render json: vital, status: 200, layout: nil
    end

    def show
        patient = Patient.find(params[:patient_id])
        raise CanCan::AccessDenied if patient.blank? ||
          (patient.organization_ids & current_user_accessible_organization_ids).length == 0
        pt_id = params[:patient_id]
        vitals = Vital.all_recent(pt_id)
        render json: vitals, status: 200, layout: nil
    end

    def get_all_from_type
        vitals = Vital.get_all_from_type(params[:patient_id], params[:type])
                      .order(taken_on: :asc)
        render json: vitals, status: 200, layout: nil
    end

    def destroy
        vital = Vital.find(params[:id])
        vital.destroy
        render json: nil, status: 200, layout: nil
    end

    def get_all_blood_pressure
        blood_pressure = Vital.get_all_blood_pressure(params[:patient_id])
        render json: blood_pressure, status: 200, layout: nil
    end

    private

    def create_params
        params.permit(:patient_id, :vital_type_id, :value, :taken_on, :notes)
    end

end

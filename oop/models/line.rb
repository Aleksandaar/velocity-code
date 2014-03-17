require 'active_utils/common/requires_parameters'

class Line::PClient::Variant
  include ActiveMerchant::RequiresParameters
  include InitializerWithAttributesHash

  attr_accessor :tail_number, :user_match, :price, :legs, :aircraft_type
  alias_method :aircraft_type_propose_flight_py_id, :aircraft_type

  def initialize(attributes)
    requires!(attributes, :tail_number, :user_match, :price, :legs, :aircraft_type)
    assign_attributes(attributes)
  end

  def tail_number
    @tail_number.upcase
  end
  alias_method :flight_number, :tail_number

  def legs=(legs_attributes)
    @legs = legs_attributes.map {|attrs| Leg.new(attrs)}
  end

  def one_way?
    legs.size == 1
  end

  def departs_at
    legs.first.departs_at
  end

  def arrives_at
    legs.first.arrives_at
  end


  class Leg
    include ActiveMerchant::RequiresParameters
    include InitializerWithAttributesHash

    attr_accessor :origin, :destination, :departs_at, :arrives_at

    def initialize(attributes)
      requires!(attributes, :origin, :destination, :departs_at, :arrives_at)
      assign_attributes(attributes)
    end

    def attributes
      { origin: origin, destination: destination,
        departs_at: departs_at, arrives_at: arrives_at }
    end
  end
end

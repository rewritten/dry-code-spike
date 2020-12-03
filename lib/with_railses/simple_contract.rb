# frozen_string_literal: true

require 'active_model'
require 'action_controller/metal/strong_parameters'

module WithRailses
  # A very simple contract
  class SimpleContract
    def call(params)
      params
        .then { strengthen(_1) }
        .then { schema(_1) }
        .then { Model.new(_1) }
        .tap(&:valid?)
    end

    # internal class for validation
    class Model
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :name, :string
      attribute :email, :string
      attribute :age, :integer
      attribute :fingers, :integer

      validates :name, presence: true, length: { minimum: 5 }
      validates :email, presence: true, format: /@/
      validates :age,
                numericality: { only_integer: true, greater_than: 10 },
                allow_nil: true, allow_blank: true
      validates :fingers,
                numericality: { only_integer: true },
                allow_nil: true

      validate :email_starts_with_name

      def to_h
        @attributes.to_h.symbolize_keys
      end

      private

      def email_starts_with_name
        return unless errors.empty?
        return if email[/.+(?=@)/] == name.downcase

        errors.add(:name, :invalid, message: 'seems not legit')
      end
    end

    private

    def strengthen(params)
      ::ActionController::Parameters.new(params)
    end

    def schema(params)
      params.require(:name)
      params.require(:email)
      params.permit(:name, :email, :age, :fingers)
    end
  end
end

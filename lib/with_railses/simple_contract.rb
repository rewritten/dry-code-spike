# frozen_string_literal: true

require 'active_model'
require 'action_controller/metal/strong_parameters'

module WithRailses
  # A very simple contract
  class SimpleContract
    def call(params)
      Model.new(strong(params)).tap(&:valid?)
    end

    # internal class for validation
    class Model
      include ActiveModel::Model
      include ActiveModel::Attributes
      include ActiveModel::Serialization

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
        serializable_hash.symbolize_keys
      end

      private

      def email_starts_with_name
        return unless errors.empty?
        return if email[/.+(?=@)/] == name.downcase

        errors.add(:name, :invalid, message: 'seems not legit')
      end
    end

    private

    def strong(params)
      params = ::ActionController::Parameters.new(params)
      params.require(:name)
      params.require(:email)
      params.permit(:name, :email, :age, :fingers)
    end
  end
end

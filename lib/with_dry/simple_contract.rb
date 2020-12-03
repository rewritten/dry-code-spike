# frozen_string_literal: true

require 'dry-validation'

module WithDry
  # A very simple contract
  class SimpleContract < Dry::Validation::Contract
    params do
      required(:name).value(:string, min_size?: 5)
      required(:email).value(:string, format?: /@/)
      optional(:age).maybe(:integer, gt?: 10)
      optional(:fingers).filled(:integer)
    end

    rule(:name, :email) do
      key.failure('seems not legit') unless values[:email][/.+(?=@)/] == values[:name].downcase
    end
  end
end

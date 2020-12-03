# frozen_string_literal: true

module WithRailses
  # A very simple contract
  class SimpleContract
    def call(params)
      params
        .then { strengthen(_1) }
        .then { schema(_1) }
    end

    # internal class for validation
    class Model < ActiveModel::Model
    end

    private

    def strengthen(params)
      ActionController::Parameters.new(params)
    end

    def schema(params)
      params.require(:name)
      params.require(:email)
      params.permit(:name, :email, :age, :fingers)
    end
  end
end

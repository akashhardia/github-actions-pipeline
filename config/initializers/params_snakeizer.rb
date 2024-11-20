# frozen_string_literal: true

# paramsをスネークケースに変換するやつ
module ParamsSnakeizer
  refine ActionController::Parameters do
    def deep_snakeize!
      @parameters.deep_transform_keys!(&:underscore)
      self
    end
  end
end

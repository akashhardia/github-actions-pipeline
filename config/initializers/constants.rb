# frozen_string_literal: true

module Constants
  ## Constants::AREASでアクセスできる
  AREAS = %w[A B C D].freeze

  # 表示優先度降順に並べたイベントコード
  PRIORITIZED_EVENT_CODE_LIST = %w[3 2 V U T W X Y R].freeze
  PRIORITIZED_AM_EVENT_CODE_LIST = %w[2 U R].freeze
  PRIORITIZED_PM_EVENT_CODE_LIST = %w[3 V T W X Y].freeze

  # 6gramリトライ回数
  SIXGRAM_RETRY_COUNT = 2
  # 6gram待機時間
  SIXGRAM_SLEEP_TIME = 0.5
end

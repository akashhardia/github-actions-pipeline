# frozen_string_literal: true

# JSON形式のログを作成するクラス
class JsonLogFormatter < Logger::Formatter
  def call(severity, time, progname, msg)
    log = {
      time: time.iso8601(6),
      level: severity,
      progname: progname,
      type: 'default'
    }

    unless current_tags.empty?
      tagged = Rails.application.config.log_tags.zip(current_tags).to_h
      log.merge!(tagged)
      msg = msg&.split(' ', current_tags.size + 1)&.last
    end
    begin
      parsed = JSON.parse(msg).symbolize_keys
      log.merge!(parsed)
    rescue JSON::ParserError
      log.merge!({ message: msg })
    end
    log.to_json + "\n"
  end
end

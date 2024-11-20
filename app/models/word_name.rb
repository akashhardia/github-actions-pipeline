# frozen_string_literal: true

# == Schema Information
#
# Table name: word_names
#
#  id           :bigint           not null, primary key
#  abbreviation :string(255)
#  lang         :string(255)      not null
#  name         :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  word_code_id :integer          not null
#
class WordName < ApplicationRecord
  belongs_to :word_code

  # Validations -----------------------------------------------------------------------------------
  validates :word_code_id, presence: true
  validates :lang, presence: true

  class << self
    def get_word_name(identifier, code, lang)
      joins(:word_code).where('word_codes.identifier = ? AND word_codes.code = ?', identifier, code).find_by(lang: lang)
    end
  end
end

# frozen_string_literal: true

require 'base64'

class Encoder
  def self.encode64(source)
    encoded_source = Base64.encode64(source)
    encoded_source = encoded_source.sub(/=+$/, '')
    encoded_source = encoded_source.tr('+', '-')
    encoded_source = encoded_source.tr('/', '_')
    encoded_source
  end
end

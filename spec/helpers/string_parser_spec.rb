# frozen_string_literal: true

require 'ruby_claim_evidence_api/helpers/string_parser'

describe StringParser do
  let(:dummy_class) { Class.new { include StringParser } }
  let(:dummy_class_instance) { dummy_class.new }

  describe '.parse_document_id' do
    it 'extracts string from curly braces' do
      expect(dummy_class_instance.parse_document_id('{123-ABC-$&^*&^}')).to eq('123-ABC-$&^*&^')
    end

    it 'extracts string itself from plain string' do
      expect(dummy_class_instance.parse_document_id('123-ABC-$&^*&^')).to eq('123-ABC-$&^*&^')
    end
  end
end

# frozen_string_literal: true

# Contains helper methods for parsing Strings
module StringParser
  # Document id's in Caseflow are wrapped in curly braces - CE API requires the id string with no wrapping
  def parse_document_id(id)
    id.to_s.gsub(/^\{(.*)\}$/, '\1')
  end
end

# frozen_string_literal: true

# Encapsulates all of the data required to perform a file update in the CE API
class FileUpdatePayload
  attr_accessor :date_va_received_document,
                :document_type_id,
                :file_content,
                :file_content_source

  def initialize(params = {})
    self.date_va_received_document = params[:date_va_received_document] || ''
    self.document_type_id = params[:document_type_id] || ''
    self.file_content = params[:file_content] || ''
    self.file_content_source = params[:file_content_source] || ''
  end
end

# frozen_string_literal: true

# Encapsulates all of the data required to perform a file update in the CE API
class ClaimEvidenceFileUpdatePayload
  attr_accessor :date_va_received_document,
                :document_type_id,
                :file_content_path,
                :file_content_source,
                :subject

  def initialize(params = {})
    self.date_va_received_document = params[:date_va_received_document] || ''
    self.document_type_id = params[:document_type_id] || ''
    self.file_content_path = params[:file_content_path] || ''
    self.file_content_source = params[:file_content_source] || ''
    self.subject = params[:subject] || ''
  end
end

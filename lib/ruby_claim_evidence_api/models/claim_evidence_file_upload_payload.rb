# frozen_string_literal: true

# Encapsulates all of the data required to perform a file upload in the CE API
class ClaimEvidenceFileUploadPayload
  attr_accessor :content_name,
                :content_source,
                :date_va_received_document,
                :document_type_id,
                :subject,
                :new_mail

  def initialize(params = {})
    self.content_name = params[:content_name] || ''
    self.content_source = params[:content_source] || ''
    self.date_va_received_document = params[:date_va_received_document] || ''
    self.document_type_id = params[:document_type_id] || ''
    self.subject = params[:subject] || ''
    self.new_mail = params[:new_mail] || ''
  end
end

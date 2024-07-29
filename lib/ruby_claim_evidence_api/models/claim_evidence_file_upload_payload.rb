# frozen_string_literal: true

class ClaimEvidenceFileUploadPayload
    attr_accessor :content_name,
                  :content_source,
                  :date_va_received_document,
                  :document_type_id
  
    def initialize(params = {})
      self.content_name = params[:content_name] || ''
      self.content_source = params[:content_source] || ''
      self.date_va_received_document = params[:date_va_received_document] || ''
      self.document_type_id = params[:document_type_id] || ''
    end
  end
  
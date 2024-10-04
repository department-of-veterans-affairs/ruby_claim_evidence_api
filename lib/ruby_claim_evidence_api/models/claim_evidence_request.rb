# frozen_string_literal: true

# Encapsulates all of the data required to perform a file upload in the CE API
class ClaimEvidenceRequest
  attr_accessor :user_css_id,
                :station_id

  def initialize(params = {})
    self.user_css_id = params[:user_css_id] || ''
    self.station_id = params[:station_id] || ''
  end
end

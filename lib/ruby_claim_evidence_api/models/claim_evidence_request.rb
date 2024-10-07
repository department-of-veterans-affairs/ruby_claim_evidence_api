# frozen_string_literal: true

# Encapsulates request-specific data (i.e., user credentials) for use in CE API requests
class ClaimEvidenceRequest
  attr_accessor :user_css_id,
                :station_id

  def initialize(params = {})
    self.user_css_id = params[:user_css_id] || ''
    self.station_id = params[:station_id] || ''
  end
end

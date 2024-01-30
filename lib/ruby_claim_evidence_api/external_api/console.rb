DOCUMENT_TYPES_ENDPOINT = '/documenttypes'
HEADERS = {
  "Content-Type": 'application/json',
  "Accept": '*/*'
}.freeze
TOKEN_SECRET = "DmaSxrwNCc5P9UFrCbRKKUC7ck3dX4Pd"
TOKEN_ISSUER = "Caseflow"
TOKEN_USER = "CASEFLOW1"
TOKEN_STATION_ID = "317"
BASE_URL="https://vefs-claimevidence-uat.stage.bip.va.gov"
CERT_FILE_LOCATION = ENV['BGS_CERT_LOCATION']
SERVER = '/api/v1/rest'

def generate_jwt_token
  header = {
    typ: 'JWT',
    alg: 'HS256'
  }
  current_timestamp = DateTime.now.strftime('%Q').to_i / 1000.floor
  data = {
    jti: SecureRandom.uuid,
    iat: current_timestamp,
    iss: TOKEN_ISSUER,
    applicationId: TOKEN_ISSUER,
    userID: TOKEN_USER,
    stationID: TOKEN_STATION_ID
  }
  stringified_header = header.to_json.encode('UTF-8')
  encoded_header = base64url(stringified_header)
  stringified_data = data.to_json.encode('UTF-8')
  encoded_data = base64url(stringified_data)
  token = "#{encoded_header}.#{encoded_data}"
  signature = OpenSSL::HMAC.digest('SHA256', TOKEN_SECRET, token)

  "#{token}.#{base64url(signature)}"
end

def base64url(source)
  encoded_source = Base64.encode64(source)
  encoded_source = encoded_source.sub(/=+$/, '')
  encoded_source = encoded_source.tr('+', '-')
  encoded_source.tr('/', '_')
end


def ocr_document_request(doc_uuid)
  {
    headers: HEADERS,
    endpoint: "/files/#{doc_uuid}/data/ocr",
    method: :get
  }
end

def get_ocr_document(doc_uuid)
  send_ce_api_request(ocr_document_request(doc_uuid)).body['currentVersion']['file']['text']
end

def send_ce_api_request(endpoint:, query: {}, headers: {}, method: :get, body: nil)
  jwt_token = generate_jwt_token()
  url = URI::DEFAULT_PARSER.escape(BASE_URL + SERVER + "/files/80bb475a-0000-cd15-9f93-ad634f8c7d6e/data/ocr")
  request = HTTPI::Request.new(url)
  request.query = {}
  request.open_timeout = 30
  request.read_timeout = 30
  request.body = nil
  request.auth.ssl.ssl_version  = :TLSv1_2
  request.auth.ssl.ca_cert_file = CERT_FILE_LOCATION
  request.auth.ssl.cert_file = ENV['BGS_CERT_LOCATION']
  request.auth.ssl.cert_key_file = ENV['BGS_KEY_LOCATION']
  request.headers = HEADERS.merge(Authorization: "Bearer #{jwt_token}")
  sleep 1
  # Check to see if MetricsService class exists. Required for Caseflow
  if Object.const_defined?('MetricsService')
    MetricsService.record("api.notifications.claim.evidence #{method.to_s.upcase} request to #{url}",
                          service: :claim_evidence,
                          name: endpoint) do
      case method
      when :get
        response = HTTPI.get(request)
        service_response = Response.new(response)
        # fail service_response.error if service_response.error.present
        service_response
      else
        fail NotImplementedError
      end
    end
  else
    case method
    when :get
      response = HTTPI.get(request)
      service_response = Response.new(response)
      # fail service_response.error if service_response.error.present
      service_response
    else
      fail NotImplementedError
    end
  end
end

class Response
  attr_reader :resp, :code

  def initialize(resp)
    @resp = resp
    @code = @resp.try(:code) || @resp.try(:status)
  end

  def data; end

  # Wrapper method to check for errors
  def error
    check_for_error
  end

  # Checks if there is no error
  def success?
    resp.try(:success?) || code == 200
  end

  # Parses response body to an object
  def body
    if resp.is_a?(Faraday::Response)
      resp.body
    else
      @body ||=
        begin
          JSON.parse(resp.body)
        rescue JSON::ParserError
          {}
        end
    end
  end

  private

  # Error codes and their associated error
  ERROR_LOOKUP = {
    401 => ClaimEvidenceApi::Error::ClaimEvidenceUnauthorizedError,
    403 => ClaimEvidenceApi::Error::ClaimEvidenceForbiddenError,
    404 => ClaimEvidenceApi::Error::ClaimEvidenceNotFoundError,
    429 => ClaimEvidenceApi::Error::ClaimEvidenceRateLimitError,
    500 => ClaimEvidenceApi::Error::ClaimEvidenceInternalServerError,
    503 => ClaimEvidenceApi::Error::ClaimEvidenceNotFoundError
  }.freeze

  # Checks for error and returns if found
  def check_for_error
    return if success?

    message = error_message
    if ERROR_LOOKUP.key? code
      ERROR_LOOKUP[code].new(code: code, message: message)
    else
      ClaimEvidenceApi::Error::ClaimEvidenceApiError.new(code: code, message: message)
    end
  end

  # Gets the error message from the response
  def error_message
    return 'No error message from ClaimEvidence' if body.empty?

    if code == 401
      body['message']['messages']['text'] if code == 401
    end

    body['message'] || body['errors'][0]['message']
  end
end

aws_client = Aws::Comprehend::Client.new(
  region: ENV['AWS_REGION']
)

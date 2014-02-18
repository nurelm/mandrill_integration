require 'spec_helper'

describe MandrillEndpoint do

  let(:payload) {
    '{"request_id": "12e12341523e449c3000001",
      "parameters": {
          "mandrill.api_key":"abc123"},
      "email": {
        "to": "spree@example.com",
        "from": "spree@example.com",
        "subject": "Order R123456 was shipped!",
        "template": "order_confirmation",
        "variables": {
          "customer.name": "John Smith",
          "order.total": "100.00",
          "order.tracking": "XYZ123"
        }
      }
    }'
 }

  it "should respond to POST send_email" do
    VCR.use_cassette('mail_chimp_send') do
      post '/send_email', payload, auth
      expect(last_response.status).to eql 200
      expect(json_response["request_id"]).to eql "12e12341523e449c3000001"
      expect(json_response["summary"]).to match /Sent 'Order R123456 was shipped!' email/
    end
  end

end


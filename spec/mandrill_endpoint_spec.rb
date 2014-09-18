require 'spec_helper'

describe MandrillEndpoint do
  let(:payload) do
    '{"request_id": "12e12341523e449c3000001",
      "parameters": {
          "mandrill_api_key": "abc123"},
      "email": {
        "to": "spree@example.com, wombat@example.com",
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
  end

  it "should respond to POST send_email" do
    VCR.use_cassette('mail_chimp_send') do
      post '/send_email', payload, auth
      expect(last_response.status).to eql 200
      expect(json_response["request_id"]).to eql "12e12341523e449c3000001"
      expect(json_response["summary"]).to match /Sent 'Order R123456 was shipped!' email/
    end
  end

  context 'when Mandrill returns an error response' do
    let(:error_response) do
      double(:error_response, parsed_response: { 'message' => 'something bad happened' })
    end

    it 'parses the error' do
      expect(HTTParty).to receive(:post).and_return(error_response)

      post '/send_email', payload, auth
      expect(last_response.status).to eql 500
      expect(json_response["request_id"]).to eql "12e12341523e449c3000001"
      expect(json_response["summary"]).to eq "Failed to send 'Order R123456 was shipped!' email to spree@example.com, wombat@example.com. something bad happened"
    end
  end

  context 'when Mandrill returns a response with a reject_reason' do
    let(:error_response) do
      double(:error_response, parsed_response: { 'reject_reason' => 'you are ugly' })
    end

    it 'parses the error' do
      expect(HTTParty).to receive(:post).and_return(error_response)

      post '/send_email', payload, auth
      expect(last_response.status).to eql 500
      expect(json_response["request_id"]).to eql "12e12341523e449c3000001"
      expect(json_response["summary"]).to eq "Failed to send 'Order R123456 was shipped!' email to spree@example.com, wombat@example.com. you are ugly"
    end
  end

  context 'when Mandrill returns something funky' do
    let(:error_response) do
      double(:error_response, parsed_response: { 'a' => '123' })
    end

    it 'inspects the returned json' do
      expect(HTTParty).to receive(:post).and_return(error_response)

      post '/send_email', payload, auth
      expect(last_response.status).to eql 500
      expect(json_response["request_id"]).to eql "12e12341523e449c3000001"
      expect(json_response["summary"]).to eq "Failed to send 'Order R123456 was shipped!' email to spree@example.com, wombat@example.com. {\"a\"=>\"123\"}"
    end
  end
end

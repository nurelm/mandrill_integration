require 'spec_helper'

describe MandrillEndpoint do

  def auth
    {'HTTP_X_AUGURY_TOKEN' => 'x123', "CONTENT_TYPE" => "application/json"}
  end

  def app
    described_class
  end

  let(:payload) { {} }
 

  #------------------ old functionality

  let(:order_payload) { {'store_id' => '123229227575e4645c000001', "payload" => {"order" => { 'actual' => Factories.order} }, "message_id" => 'abc' } }

  let(:shipment_payload) do
    {'store_id' => '123229227575e4645c000001',
     'payload' => {"parameters" => {},
                   "order" => 
                      {'actual' => Factories.order, "message_id" => 'abc', 'shipment_number' => 'H438105531460',
                                             'tracking_number' => '1234',
                                             'tracking_url' => 'http://usps.com?q=123',
                                             'carrier' => 'USPS','items' => [{
                                               'part_number' => 'LB-BIT-w10-INVERTER-v03',
                                               'quantity' => '2',
                                               'serial_numbers' => 'SN1,SN2'
                                             }]}}}
  end

  it "should respond to POST order confirmation" do
    order_payload['payload']['parameters'] = [ { 'name' => 'mandrill.api_key', 'value' => 'abc123' },
                                               { 'name' => 'mandrill.order_confirmation.from', 'value' => 'spree@example.com' },
                                               { 'name' => 'mandrill.order_confirmation.subject', 'value' => 'Test Store 1 Order Confirmation' },
                                               {'name' => 'mandrill.order_confirmation.template', 'value' => 'order_confirmation' } ]

    VCR.use_cassette('mail_chimp_confirmation') do
      post '/order_confirmation', order_payload.to_json, auth
      last_response.status.should == 200
      last_response.body.should match /Order Confirmation sent to/i
    end
  end

  it "should respond to POST order cancellation" do
    order_payload['payload']['parameters'] = [ { 'name' => 'mandrill.api_key', 'value' => 'abc123' },
                                               { 'name' => 'mandrill.order_cancellation.from', 'value' => 'spree@example.com' },
                                               { 'name' => 'mandrill.order_cancellation.subject', 'value' => 'Test Store 1 Order Cancellation' },
                                               { 'name' => 'mandrill.order_cancellation.template', 'value' => 'order_cancellation' } ]

    VCR.use_cassette('mail_chimp_cancellation') do
      post '/order_cancellation', order_payload.to_json, auth
      last_response.status.should == 200
      last_response.body.should match /order cancellation sent to/i
    end
  end

  it "should respond to POST shipment confirmation" do
    shipment_payload['payload']['parameters'] = [ { 'name' => 'mandrill.api_key', 'value' => 'abc123' },
                                                  { 'name' => 'mandrill.shipment_confirmation.from', 'value' => 'spree@example.com' },
                                                  { 'name' => 'mandrill.shipment_confirmation.subject', 'value' => 'Test Store 1 Shipment Confirmation' },
                                                  { 'name' => 'mandrill.shipment_confirmation.template', 'value' => 'shipment_confirmation' } ]

    VCR.use_cassette('shipment_confirmation') do
      post '/shipment_confirmation', shipment_payload.to_json, auth
      last_response.body.should match /shipment confirmation sent to/i
    end
  end

end


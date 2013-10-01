require 'spec_helper'

describe ShipmentConfirmation do

  subject { ShipmentConfirmation.new( Factories.shipment_confirm, 'Abc', {'mandrill.api_key' => '91619e65-5a04-436b-b744-cefdb1107fab',
                                                           'mandrill.shipment_confirmation.template' => 'shipment_confirmation',
                                                           'mandrill.shipment_confirmation.subject' => 'Test Store 1 Shipment Confirmation',
                                                           'mandrill.shipment_confirmation.from' => 'andrew@spreecommerce.com'}) }

  it { should be_kind_of MandrillSender }

  it 'uses the shipment confirmation template' do
    body = subject.request_body
    body.should match /"template_name":"shipment_confirmation"/
  end

  it 'posts to the mandrill send-template' do
    VCR.use_cassette('mail_chimp_shipment_confirmation') do
      response = subject.consume
      response.should be_an_instance_of(Array)
      response.first.should eq 200
      response.last['message_id'].should == 'Abc'
    end
  end

  it 'raise an exception on send error' do
    VCR.use_cassette('mail_chimp_shipment_confirmation_not_found') do
      subject.config['mandrill.shipment_confirmation.template'] = 'bad'
      response = subject.consume
      response.should be_an_instance_of(Array)
      response.first.should eq 500
      response.last['message_id'].should == 'Abc'
    end
  end
end

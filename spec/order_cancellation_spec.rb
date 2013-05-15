require 'spec_helper'

describe OrderCancellation do
  subject { OrderCancellation.new({'order' => {'actual' => Factories.order('email' => 'spree@example.com')} }, "Abc", {
                                  'mandrill.api_key' => '91619e65-5a04-436b-b744-cefdb1107fab', 'mandrill.order_cancellation.subject' => 'Test Store 1 Order Cancellation',
                                  'mandrill.order_cancellation.template' => 'template', 'mandrill.order_cancellation.from' => 'spree@example.com'}) }

  it { should be_kind_of MandrillSender }

  it 'uses store name in subject' do
    body = subject.request_body
    body.should match /"subject":"Test Store 1 Order Cancellation"/
  end

  it 'posts to the mandril send-template' do
    VCR.use_cassette('mail_chimp_order_cancellation') do
      response = subject.consume
      response.should be_an_instance_of(Array)
      response.first.should eq 200
      response.last['message_id'].should == 'Abc'
    end
  end
  it 'raise an exception on send error' do
    subject.config['mandrill.order_confirmation.template'] = 'bad'
    VCR.use_cassette('mail_chimp_order_cancellation_not_found') do
      response = subject.consume
      response.should be_an_instance_of(Array)
      response.first.should eq 500
      response.last['message_id'].should == 'Abc'
    end
  end
end

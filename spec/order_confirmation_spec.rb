require 'spec_helper'


describe "OrderConfirmation" do

  it "shouldn't instantiate without an API key" do
    expect {MandrillSender.new({'order' => {'actual' => Factories.order } }, "abc")}.to raise_error AuthenticationError
  end

  let(:order) { Factories.order }

  subject { OrderConfirmation.new({'order' => {'actual' => order} }, 'abc', {'mandrill.api_key' => '91619e65-5a04-436b-b744-cefdb1107fab',
                                                              'mandrill.order_confirmation.template' => 'template',
                                                              'mandrill.order_confirmation.subject' => 'Test Store 1 Order Confirmation',
                                                              'mandrill.order_confirmation.from' => 'andrew@spreecommerce.com'}) }

  it { should be_kind_of MandrillSender }

  it 'uses store name in subject' do
    body = subject.request_body
    body.should match /"subject":"Test Store 1 Order Confirmation"/
  end

  it 'posts to the mandril send-template' do
    VCR.use_cassette('mail_chimp_order_confirmation') do
      response = subject.consume
      response.should be_an_instance_of(Array)
      response.first.should eq 200
      response.last['message_id'].should == 'abc'
    end
  end

  it 'handles blacklisted email errors' do
    VCR.use_cassette('mail_chimp_black_list') do
      response = subject.consume
      response.should be_an_instance_of(Array)
      response.first.should eq 500
      response.last['message_id'].should == 'abc'
    end
  end

  it 'raise an exception on send error' do
    subject.config['mandrill.order_confirmation.template'] = 'bad'
    VCR.use_cassette('mail_chimp_order_confirmation_not_found') do
      response = subject.consume
      response.should be_an_instance_of(Array)
      response.first.should eq 500
      response.last['message_id'].should == 'abc'
    end
  end

end

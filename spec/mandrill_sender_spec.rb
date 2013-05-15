require 'spec_helper'

describe "MandrillSender" do

  it "should create with an API key" do
    MandrillSender.new({'order' => {'actual' => Factories.order }}, "abc", {'mandrill.api_key' => '91619e65-5a04-436b-b744-cefdb1107fab', 'mandrill.order_confirmation.template' => 'template', 'mandrill.order_confirmation.from' => 'andrew@spreecommerce.com'})
  end

  it "shouldn't instantiate without an API key" do
    expect {MandrillSender.new({'order' => {'actual' => Factories.order } }, "abc")}.to raise_error AuthenticationError
  end

end


require 'spec_helper'

describe MandrillEndpoint do

  def auth
    {'HTTP_X_AUGURY_TOKEN' => 'x123', "CONTENT_TYPE" => "application/json"}
  end

  def app
    described_class
  end

  let(:payload) { {} }
 
end


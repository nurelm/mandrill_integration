require File.expand_path(File.dirname(__FILE__) + '/lib/mandrill_sender')
Dir['./lib/**/*.rb'].each { |f| require f }

class AuguryEndpoint < EndpointBase

  set :logging, true

  post '/order_confirmation' do
    order = OrderConfirmation.new(@message[:payload], @message[:message_id], @config)
    process_result *order.consume
  end

  post '/order_cancellation' do
    order = OrderCancellation.new(@message[:payload], @message[:message_id], @config)
    process_result *order.consume
  end

  post '/shipment_confirmation' do
    order = ShipmentConfirmation.new(@message[:payload], @message[:message_id], @config)
    process_result *order.consume
  end
end

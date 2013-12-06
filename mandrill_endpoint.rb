require File.expand_path(File.dirname(__FILE__) + '/lib/mandrill_sender')
Dir['./lib/**/*.rb'].each { |f| require f }

class MandrillEndpoint < EndpointBase

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

  post '/send_mail' do
    # convert variables into Mandrill array / hash format.
    #
    global_merge_vars = @message[:payload]['email']['variables'].map do |name, value|
      { 'name' => name, 'content' => value }
    end

    # create Mandrill request
    #
    request_body = {
      key: @config['mandrill.api_key'],
      template_name: @message[:payload]['email']['template'],
      message: {
        from_email: @message[:payload]['email']['from'],
        to: [{ email: @message[:payload]['email']['to'] }],
        subject: @message[:payload]['email']['subject'],
        global_merge_vars: global_merge_vars
      },
      template_content: [
        name: 'User 1',
        content: 'Content 1'
      ]

    }.to_json

    # send request to Mandrill API
    #
    response = HTTParty.post('https://mandrillapp.com/api/1.0/messages/send-template.json',
                     body: request_body,
                     timeout: 240,
                     headers: { 'Content-Type'   => 'application/json' })

    #ugly because it could be a hash or an array
    #https://mandrillapp.com/api/docs/messages.html
    response = [response.parsed_response].flatten.first

    if response.key? 'reject_reason'
      response.delete('reject_reason') if response['reject_reason'].nil?
    end

    if %w{sent queued}.include?(response['status'])
        process_result 200, {
          'message_id' => @message[:message_id],
          'notifications' => [{
            'level' => 'info',
            'subject' => " Sent to #{}",
            'description' => "Email Sent to #{}",
            'mandrill' => response
          }]
        }
    else
        process_result 500, {
          'message_id' => @message[:message_id],
          'notifications' => [{
            'level' => 'error',
            'subject' => "#{} failed to send to #{'email'}",
            'description' => "#{} failed to send to #{'email'}",
            'mandrill' => response
          }]
        }
    end
  end

  private


end

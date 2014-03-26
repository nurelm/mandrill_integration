Dir['./lib/**/*.rb'].each { |f| require f }

class MandrillEndpoint < EndpointBase::Sinatra::Base

  set :logging, true

  post '/send_email' do
    # convert variables into Mandrill array / hash format.
    #

    global_merge_vars = @payload['email']['variables'].map do |name, value|
      { 'name' => name, 'content' => value }
    end

    template = @payload['email']['template']
    to_addr = @payload['email']['to']
    from_addr = @payload['email']['from']
    subject = @payload['email']['subject']

    # create Mandrill request
    #
    request_body = {
      key: @config['mandrill_api_key'],
      template_name: template,
      message: {
        from_email: from_addr,
        to: [{ email: to_addr }],
        subject: subject,
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
    reason = response['reject_reason'] || response.inspect

    if %w{sent queued}.include?(response['status'])
      set_summary "Sent '#{subject}' email to #{to_addr}"
      add_value :mandrill_message_id, response["_id"]
      process_result 200
    else
      set_summary "Failed to send '#{subject}' email to #{to_addr} - #{reason}"
      process_result 500
    end
  end

end

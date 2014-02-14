require File.expand_path(File.dirname(__FILE__) + '/lib/mandrill_sender')
Dir['./lib/**/*.rb'].each { |f| require f }

class MandrillEndpoint < EndpointBase

  set :logging, true

  post '/send_mail' do
    # convert variables into Mandrill array / hash format.
    #
    global_merge_vars = @message[:payload]['email']['variables'].map do |name, value|
      { 'name' => name, 'content' => value }
    end

    template = @message[:payload]['email']['template']
    to_addr = @message[:payload]['email']['to']
    from_addr = @message[:payload]['email']['from']
    subject = @message[:payload]['email']['subject']

    # create Mandrill request
    #
    request_body = {
      key: @config['mandrill.api_key'],
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

    if response.key? 'reject_reason'
      response.delete('reject_reason') if response['reject_reason'].nil?
    end

    if %w{sent queued}.include?(response['status'])
      process_result 200, {
        'message_id' => @message[:message_id],
        'notifications' => [{
          'level' => 'info',
          'subject' => "Sent '#{subject}' email to #{to_addr}",
          'description' => "Sent '#{subject}' email to #{to_addr}",
          'mandrill' => response
        }]
      }
    else
      process_result 200, {
        'message_id' => @message[:message_id],
        'notifications' => [{
          'level' => 'warning',
          'subject' => "Failed to send '#{subject}' email to #{to_addr}",
          'description' => "Failed to send '#{subject}' email to #{to_addr}",
          'mandrill' => response
        }]
      }
    end
  end

end

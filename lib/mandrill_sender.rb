class MandrillSender
  include HTTParty
  base_uri 'https://mandrillapp.com/api/1.0'
  format :json

  attr_accessor :order, :api_key, :config, :message_id

  def initialize(payload, message_id, config={})
    @order = payload['order'] || payload['shipment']
    @config = config
    @api_key = config['mandrill.api_key']
    @message_id = message_id
    raise AuthenticationError if @api_key.nil?
  end

  def consume
    options = {
      body: request_body
    }
    response = self.class.post('/messages/send-template.json', options)
    successful? response.parsed_response

    #ugly because it could be a hash or an array
    #https://mandrillapp.com/api/docs/messages.html
    response = [response.parsed_response].flatten.first

    if response.key? 'reject_reason'
      response.delete('reject_reason') if response['reject_reason'].nil?
    end

    if %w{sent queued}.include?(response['status'])
        return 200, { 'message_id' => message_id,
                 'order_number' => order['number'],
                 'messages' => [{ 'message' => 'email:sent', 'payload' => response }],
                 'notifications' => [{'level' => 'info','subject' => "Email Sent to #{order['email']}",'description' => "Email Sent to #{order['email']}"}]
        }
    else
        return 500, { 'message_id' => message_id,
                 'order_number' => order['number'],
                 'messages' => [{ 'message' => 'email:failure', 'payload' => response }],
		 'notifications' => [{'level' => 'error', 'subject' => "Email failed to send to #{order['email']}", 'description' => response}]
               }
    end

  end

  def successful?(response)
    response = response.first if response.kind_of? Array
  end

  def request_body
    { key: @api_key }.to_json
  end

  def merge_vars
    vars = Array.new

    vars.concat address_vars('shipping_address')
    vars.concat address_vars('billing_address')
    vars.concat adjustment_vars

    vars << { name: 'order_number', content: order['number'] }
   
    if order.has_key?('totals') 
      vars << { name: 'item_total', content: format_money(order['totals']['item']) }
      vars << { name: 'total', content: format_money(order['totals']['order']) }
      vars << { name: 'backordered', content: order['shipments'].any? {|s| s['status'] == "backorder"}.to_s }
      vars << { name: 'line_item_rows', content: line_item_rows }
    end

    vars
  end

  def address_vars(name)
    return [] if order[name].nil?
    vars = Array.new
    vars << { name: "#{name}_first_name", content: order[name]["firstname"] }
    vars << { name: "#{name}_last_name", content: order[name]["lastname"] }
    vars << { name: "#{name}_company", content: order[name]["company"] }
    vars << { name: "#{name}_address1", content: order[name]["address1"] }
    vars << { name: "#{name}_address2", content: order[name]["address2"] }
    vars << { name: "#{name}_city", content: order[name]["city"] }
    vars << { name: "#{name}_state", content: order[name]["state"] }
    vars << { name: "#{name}_country", content: order[name]["country"] }
    vars << { name: "#{name}_zipcode", content: order[name]["zipcode"] }
  end

  def adjustment_vars
    vars = Array.new
    return [] unless order.has_key?('adjustments')
    order['adjustments'].each do |adjustment|
      adjustment = adjustment['adjustment'] if adjustment.key? 'adjustment'
      vars << { name: "adjustment_#{adjustment['name'].downcase}",
                content: format_money(adjustment['amount']) }
    end
    vars
  end

  def line_item_rows
    line_item_html = ""
    order['line_items'].each do |line_item|
      line_item_html << %Q{
        <tr>
          <td>#{line_item['name']}</td>
          <td>#{line_item['quantity']}</td>
          <td>#{format_money line_item['price']}</td>
        </tr>
      }
    end
    line_item_html
  end

  def format_money(amount)
    "%.2f" % amount.to_f
  end

end

class AuthenticationError < StandardError

end

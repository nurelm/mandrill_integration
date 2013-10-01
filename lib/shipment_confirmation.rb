class ShipmentConfirmation < MandrillSender
  attr_accessor :shipment_number, :order_helper, :tracking_number,
                :carrier, :shipped_date, :items, :tracking_url

  def initialize(payload, message_id ,config)
    super
    #@order_helper = OrderHelper.new(order)
    @shipment_number = payload['shipment']['number']
    @tracking_number = payload['shipment']['tracking']
    @email = payload['shipment']['email']
    @shipped_date = payload['shipped_at']
    @items = payload['shipment']['items'] || []
  end

  def request_body
    { key: api_key,
      template_name: config['mandrill.shipment_confirmation.template'],
      message: {
        from_email: config['mandrill.shipment_confirmation.from'],
        to: [{ email: @email }],
        subject: config['mandrill.shipment_confirmation.subject'],
        global_merge_vars: merge_vars + tracking_vars,
      },
      template_content: [
        name: 'User 1',
        content: 'Content 1'
      ]
    }.to_json
  end

  private

  def tracking_vars
    vars = []
    vars << { name: 'tracking_number', content: tracking_number }
    vars << { name: 'shipped_date', content: shipped_date }
    vars << { name: 'items', content: shipped_items_html }
    vars
  end

  def shipped_items_html
    html = ""
    items.each do |item|
      html << %Q{
        <tr>
          <td>#{item['name']}</td>
          <td>#{item['quantity']}</td>
        </tr>
      }
    end
    html
  end
end

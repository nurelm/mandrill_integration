class ShipmentConfirmation < MandrillSender
  attr_accessor :shipment_number, :order_helper, :tracking_number,
                :carrier, :shipped_date, :items, :tracking_url

  def initialize(payload, message_id ,config)
    super
    @order_helper = OrderHelper.new(order)
    @shipment_number = payload['shipment_number']
    @tracking_number = payload['tracking_number']
    @shipped_date = payload['shipped_date']
    @items = payload['items'] || []
  end

  def request_body
    { key: api_key,
      template_name: config['mandrill.shipment_confirmation.template'],
      message: {
        from_email: config['mandrill.shipment_confirmation.from'],
        to: [{ email: order['email'] }],
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
      variant = order_helper.variant_by_ref(item['part_number'])
      html << %Q{
        <tr>
          <td>#{variant['name']}</td>
          <td>#{item['quantity']}</td>
          <td>#{item['serial_numbers']}</td>
        </tr>
      }
    end
    html
  end
end

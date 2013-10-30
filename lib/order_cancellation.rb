class OrderCancellation < MandrillSender
  def description
    "Order Cancellation"
  end

  def request_body
    { key: api_key,
      template_name: config['mandrill.order_cancellation.template'],
      message: {
        from_email: config['mandrill.order_cancellation.from'],
        to: [{ email: order['email'] }],
        subject: config['mandrill.order_cancellation.subject'],
        global_merge_vars: merge_vars,
      },
      template_content: [
        name: 'User 1',
        content: 'Content 1'
      ]
    }.to_json
  end

end

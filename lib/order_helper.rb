class OrderHelper
  attr_accessor :order

  def initialize(order)
    @order = order
  end

  def inventory_units(shipment_number)
    shipment = shipment_by_number(shipment_number)
    shipment['inventory_units'].map do |unit|
      inventory_unit = unit['inventory_unit'] if unit.key?('inventory_unit')
      inventory_unit
    end
  end

  def shipments
    @shipments ||= order['shipments'].map do |shipment|
      shipment = shipment['shipment'] if shipment.key?('shipment')
      shipment
    end
  end

  def shipment_by_number(number)
    shipments.find { |s| s['number'] == number }
  end

  def variants
    @variants ||= if order.key? 'variants'
      order['variants'].map do |variant|
        variant.key?('variant') ? variant['variant'] : variant
      end
    else
      order['line_items'].map do |line_item|
        line_item = line_item['line_item'] if line_item.key?('line_item')
        line_item['variant']
      end
    end
  end

  def variant_by_ref(ref)
    variant = variants.find { |v| v['sku'] == ref }
    variant ||= variants.find { |v| v['external_ref'] == ref }
  end

  def variant_by_id(id)
    variants.find { |v| v['id'] == id }
  end

end

module Quotes
  class Calculator
    def initialize(items_params)
      # items_params: array of { work_type_key:, quantity: }
      @items_params = items_params
    end

    def calculate
      items = @items_params.filter_map { |p| build_item(p) }

      {
        items: items,
        total_min: items.sum { |i| i[:total_min] },
        total_max: items.sum { |i| i[:total_max] },
        total_avg: items.sum { |i| i[:total_avg] },
        duration_min_days: items.sum { |i| i[:duration_min] },
        duration_max_days: items.sum { |i| i[:duration_max] },
        duration_avg_days: items.sum { |i| i[:duration_avg] }
      }
    end

    private

    def build_item(params)
      work_type = WorkType.find(params[:work_type_key])
      return nil unless work_type

      qty = params[:quantity].to_f
      return nil unless qty > 0

      total_min = (work_type.price_min * qty).round(2)
      total_max = (work_type.price_max * qty).round(2)
      total_avg = (work_type.price_avg * qty).round(2)

      {
        work_type_key: work_type.key,
        unit: work_type.unit,
        quantity: qty,
        unit_price_min: work_type.price_min,
        unit_price_max: work_type.price_max,
        unit_price_avg: work_type.price_avg,
        total_min: total_min,
        total_max: total_max,
        total_avg: total_avg,
        duration_min: work_type.duration_min,
        duration_max: work_type.duration_max,
        duration_avg: work_type.duration_avg
      }
    end
  end
end

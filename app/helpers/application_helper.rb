module ApplicationHelper

end


module Enumerable
  def each_with_last
    x = y = nil
    first = true
    each do |y|
      yield x, false if !first
      x = y
      first = false
    end
    yield x, true if !first
  end
end







module SimpleForm
  module Inputs
    class DatePickerInput < SimpleForm::Inputs::StringInput
      def input_html_options
        value = object.send(attribute_name).to_date rescue nil
        options = {
          value: value.nil?? nil : I18n.localize(value),
          data: { behaviour: 'datepicker' }  # for example
        }
        # add all html option you need...
        super.merge options
      end
    end
  end
end
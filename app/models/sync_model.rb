module SyncModel

  def syncronize!
    @sync_attrs.inspect
  end

  def syncs_with(model, attrs, options = {}, &extension)
    @sync_attrs ||= []
    case attrs.class
      when Array
        mapped_attributes = {}
        attrs.each do |name|
          mapped_attributes[name] = name
        end
        attrs = mapped_attributes
      when Symbol
        attrs = { attrs => attrs }
      when String
        attrs = { attrs => attrs }          
      else
    end
    attrs.each do |k,v|
      @sync_attrs << { type: :one, model: model, local: k, :remote => v, options: options}
    end
  end

end
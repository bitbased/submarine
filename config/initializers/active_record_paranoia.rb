ActiveRecord::Base.partial_writes = true
ActiveRecord::Base.logger.level = 1 # Logger::INFO

module Paranoia
  def self.included(klazz)
    klazz.extend Query
    klazz.extend Callbacks
  end

  module Query
    def paranoid? ; true ; end

    def with_deleted
      all.tap do |x|
        if x.default_scoped
          x.merge!(x.default_scopes.inject(x) do |default_scope, scope|
            if !scope.is_a?(ActiveRecord::Relation) && scope.respond_to?(:call)
              default_scope.merge(scope.call)
            else
              default_scope.merge(scope)
            end
          end)
          x.default_scoped = false
          x.where_values.delete_if { |query| (query.is_a?(String) && query.include?(".#{paranoia_column} IS NULL")) || (!query.is_a?(String) && query.to_sql.include?(".#{paranoia_column} IS NULL")) }
        end
      end
    end

    def only_deleted
      with_deleted.where.not(paranoia_column => nil)
    end
    alias :deleted :only_deleted

    def restore(id, opts = {})
      if id.is_a?(Array)
        id.map { |one_id| restore(one_id, opts) }
      else
        only_deleted.find(id).restore!(opts)
      end
    end
  end

  module Callbacks
    def self.extended(klazz)
      klazz.define_callbacks :restore

      klazz.define_singleton_method("before_restore") do |*args, &block|
        set_callback(:restore, :before, *args, &block)
      end

      klazz.define_singleton_method("around_restore") do |*args, &block|
        set_callback(:restore, :around, *args, &block)
      end

      klazz.define_singleton_method("after_restore") do |*args, &block|
        set_callback(:restore, :after, *args, &block)
      end
    end
  end

  def destroy
    run_callbacks(:destroy) { delete_or_soft_delete(true) }
  end

  def delete
    return if new_record?
    delete_or_soft_delete
  end

  def restore!(opts = {})
    ActiveRecord::Base.transaction do
      run_callbacks(:restore) do
        update_column paranoia_column, nil
        restore_associated_records if opts[:recursive]
      end
    end
  end
  alias :restore :restore!

  def destroyed?
    !!send(paranoia_column)
  end
  alias :deleted? :destroyed?

  private
  # select and exec delete or soft-delete.
  # @param with_transaction [Boolean] exec with ActiveRecord Transactions, when soft-delete.
  def delete_or_soft_delete(with_transaction=false)
    destroyed? ? destroy! : touch_paranoia_column(with_transaction)
  end

  # touch paranoia column.
  # insert time to paranoia column.
  # @param with_transaction [Boolean] exec with ActiveRecord Transactions.
  def touch_paranoia_column(with_transaction=false)
    if with_transaction
      with_transaction_returning_status { touch(paranoia_column) }
    else
      touch(paranoia_column)
    end
  end

  # restore associated records that have been soft deleted when
  # we called #destroy
  def restore_associated_records
    destroyed_associations = self.class.reflect_on_all_associations.select do |association|
      association.options[:dependent] == :destroy
    end

    destroyed_associations.each do |association|
      association = send(association.name)

      if association.paranoid?
        association.only_deleted.each { |record| record.restore(:recursive => true) }
      end
    end
  end
end

class ActiveRecord::Base
  def self.acts_as_paranoid(options={})
    alias :destroy! :destroy
    alias :delete!  :delete
    include Paranoia
    class_attribute :paranoia_column

    self.paranoia_column = options[:column] || :deleted_at
    default_scope -> { where(self.quoted_table_name + ".#{paranoia_column} IS NULL") }

    before_restore {
      self.class.notify_observers(:before_restore, self) if self.class.respond_to?(:notify_observers)
    }
    after_restore {
      self.class.notify_observers(:after_restore, self) if self.class.respond_to?(:notify_observers)
    }
  end

  def self.paranoid? ; false ; end
  def paranoid? ; self.class.paranoid? ; end

  # Override the persisted method to allow for the paranoia gem.
  # If a paranoid record is selected, then we only want to check
  # if it's a new record, not if it is "destroyed".
  def persisted?
    paranoid? ? !new_record? : super
  end

  private

  def paranoia_column
    self.class.paranoia_column
  end
end
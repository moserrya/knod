module HashWithPatchMerge
  refine Hash do
    def patch_merge(other_hash, &block)
      dup.patch_merge!(other_hash, &block)
    end

    def patch_merge!(other_hash, &block)
      other_hash.each_pair do |k, v|
        tv = self[k]
        if tv.is_a?(Hash) && v.is_a?(Hash)
          self[k] = tv.patch_merge(v, &block)
        else
          self[k] = block && tv ? block.call(k, tv, v) : v
          delete(k) if self[k].nil?
        end
      end
      self
    end
  end
end

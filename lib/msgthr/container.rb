# Copyright (C) 2016 all contributors <msgthr-public@80x24.org>
# License: GPL-2.0+ <https://www.gnu.org/licenses/gpl-2.0.txt>

# An internal container class, this is exposed for sorting APIs
# but should not be initialized in your own code.
class Msgthr::Container

  # Unique message identifier, typically the Message-Id header for mail
  # and news messages.  This may be any hashable object, Integer values
  # are allowed and will not be coerced to string values.
  attr_reader :mid

  # Opaque data pointer, may be used by the user for any purpose.
  # This may be +nil+ to denote missing (aka "ghost") messages.
  attr_accessor :msg

  attr_accessor :children # :nodoc:
  attr_accessor :parent # :nodoc:

  def initialize(mid) # :nodoc:
    @mid = mid
    @children = {} # becomes an Array after order!
    @parent = nil
    @msg = nil # opaque
  end

  # returns the topmost message container with an opaque message pointer
  # in it.  This may be +nil+ if none are available.
  def topmost
    q = [ self ]
    while cont = q.shift
      return cont if cont.msg
      q.concat(cont.children.values)
    end
    nil
  end

  def add_child(child) # :nodoc:
    raise 'cannot become child of self' if child == self
    cid = child.mid

    # reparenting:
    parent = child.parent and parent.children.delete(cid)

    @children[cid] = child
    child.parent = self
  end

  def has_descendent(child) # :nodoc:
    seen = Hash.new(0)
    while child
      return true if self == child || (seen[child] += 1) != 0
      child = child.parent
    end
    false
  end

  def order! # :nodoc:
    seen = { @mid => true }
    q = [ self ]
    while cur = q.shift
      c = []
      cur.children.each do |cmid, cont|
        next if seen[cmid]
        c << cont
        seen[cmid] = true
      end.clear
      yield(c) if c.size > 1
      cur.children = c
      q.concat(c)
    end
  end
end

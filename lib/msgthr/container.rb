# Copyright (C) 2016 all contributors <msgthr-public@80x24.org>
# License: GPL-2.0+ <https://www.gnu.org/licenses/gpl-2.0.txt>

# An internal container class, this is exposed for Msgthr#thread!
# Msgthr#order! and Msgthr#walk_thread APIs through block parameters.
# They should should not be initialized in your own code.
#
# One container object will exist for every message you call Msgthr#add! on,
# so there can potentially be many of these objects for large sets of
# messages.
class Msgthr::Container

  # Unique message identifier, typically the Message-Id header for mail
  # and news messages.  This may be any hashable object, Integer values
  # are allowed and will not be coerced to string values.
  attr_reader :mid

  # Opaque data pointer, may be used by the user for any purpose.
  # This is +nil+ to denote missing (aka "ghost") messages.
  attr_accessor :msg

  # You probably do not need to use this.
  # It is only safe to access this after Msgthr#order!
  # This contains an Array of Msgthr::Container objects which have the
  # +parent+ field pointing to us
  attr_accessor :children

  # You probably do not need to use this; and you should only use
  # this after Msgthr#order!  This points to the +parent+ of the
  # message if one exists, and +nil+ if a message has no parent.
  # This will only be accurate once all messages are added to
  # a Msgthr set via Msgthr#add
  attr_accessor :parent # :nodoc:

  def initialize(mid) # :nodoc:
    @mid = mid
    @children = {} # becomes an Array after order!
    @parent = nil
    @msg = nil # opaque pointer supplied by user
  end

  # Returns the topmost message container with an opaque message pointer
  # in it.  This may be +nil+ if no message is available.
  # This is preferable to using the container yielded by Msgthr#order!
  # directly when handling incomplete message sets.
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

  # only called by Msgthr#order!
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

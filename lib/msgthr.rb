# Copyright (C) 2016 all contributors <msgthr-public@80x24.org>
# License: GPL-2.0+ <https://www.gnu.org/licenses/gpl-2.0.txt>

# Non-recursive, container-agnostic message threading.
class Msgthr

  # an Array of root (parent-less) messages, only populated after
  # calling Msgthr#thread!
  attr_reader :rootset

  # Initialize a Msgthr object
  def initialize
    @id_table = {}
    @rootset = []
  end

  # Clear internal data structures to save memory and prepare for reuse
  def clear
    @rootset.clear
    @id_table.clear
  end

  # Threads the message
  # This does not sort
  def thread!
    ret = @rootset
    @id_table.each_value { |cont| ret << cont if cont.parent.nil? }.clear
    ret
  end

  def order!
    yield @rootset
    @rootset.each { |cont| cont.order! { |children| yield(children) } }
  end

  # non-recursively walk a thread
  def walk_thread
    i = -1
    q = @rootset.map { |cont| [ 0, cont, i += 1 ] }
    while tmp = q.shift
      level, cont, idx = tmp
      yield(level, cont, idx)
      level += 1
      i = -1
      q = cont.children.map { |cld| [ level, cld, i += 1 ] }.concat(q)
    end
  end

  # Adds a message to prepare a Msgthr object for threading.
  #
  # * +mid+ is a unique identifier for the message in a given thread.
  #
  # * +refs+ should be an Array of unique identifiers.  For mail and
  #   news messages, this is usually the parsed result of the
  #   "References:" header.  Order should be oldest to newest
  #   in terms of ancestry, with the last element being the
  #   immediate parent of the given message.
  #
  #   This is +nil+ for messages with no parent.
  #
  # * +msg+ is an opaque object which typically contains a
  #   Mail or Tmail object for handling mail.
  #
  # If +mid+ is a String, it is recommended to freeze the string before
  # calling this method to avoid wasting memory on hash keys.
  def add(mid, refs, msg)
    cur = @id_table[mid] ||= Msgthr::Container.new(mid)
    cur.msg = msg
    refs or return

    # n.b. centralized messaging systems (e.g. forums) do not need
    # multiple References:, only decentralized systems need it to
    # tolerate missing messages
    prev = nil
    refs.each do |ref|
      cont = @id_table[ref] ||= Msgthr::Container.new(ref)

      # link refs together in order implied,
      # but do not change existing links or loop
      if prev && !cont.parent && !cont.has_descendent(prev)
        prev.add_child(cont)
      end
      prev = cont
    end

    # set parent of this message to be the last element in refs
    prev.add_child(cur) if prev
  end
end

require_relative 'msgthr/container'

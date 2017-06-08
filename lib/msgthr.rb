# Copyright (C) 2016 all contributors <msgthr-public@80x24.org>
# License: GPL-2.0+ <https://www.gnu.org/licenses/gpl-2.0.txt>

# Non-recursive, container-agnostic message threading.
#
# Usage is typically:
#
# * use Msgthr.new to create a new object
# * use Msgthr#add! for every message you have
# * use Msgthr#thread! to perform threading operations
# * optionally, use Msgthr#order! to sort messages
# * use Msgthr#walk_thread to iterate through the threaded tree
#
# See https://80x24.org/msgthr/README for more info
# You may email us publically at mailto:msgthr-public@80x24.org
# Archives are at https://80x24.org/msgthr-public/
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

  # Performs threading on the messages and returns the rootset
  # (set of message containers without parents).
  #
  # Call this after all #add operations are complete.
  # This does not sort, use #order! if sorting is necessary.
  def thread!
    ret = @rootset
    @id_table.each_value { |cont| ret << cont if cont.parent.nil? }.clear
    ret
  end

  # Performs an in-place sort on messages after thread!
  # This is optional and intended to be called this only after #thread!
  #
  # This takes a block which yields an array of Msgthr::Container
  # objects for sorting.
  #
  # To sort by unique +mid+ identifiers for each container:
  #
  #   msgthr.order! { |ary| ary.sort_by!(&:mid) }
  #
  # If your opaque message pointer contains a +time+ accessor which gives
  # a Time object:
  #
  #   msgthr.order! do |ary|
  #     ary.sort_by! do |cont| # Msgthr::Container
  #       cur = cont.topmost
  #       cur ? cur.msg.time : Time.at(0)
  #     end
  #   end
  #
  # Note, using Msgthr::Container#topmost is NOT necessary when accessing
  # Msgthr::Container#mid, as any known missing messages (ghosts)
  # will still have a +mid+.  However, Msgthr::Container#topmost is
  # necessary if accessing Msgthr::Container#msg.
  def order!
    yield @rootset
    @rootset.each do |cont|
      # this calls Msgthr::Container#order!, which is non-recursive
      cont.order! { |children| yield(children) }
    end
  end

  # non-recursively walk a set of messages after #thread!
  # (and optionally, #order!)
  #
  # This takes a block and yields 3 elements to it: +|level, container, index|+
  # for each message container.
  #
  # * +level+ is the current depth within the walk (non-negative Integer)
  # * +container+ is the Msgthr::Container object
  # * +index+ is the offset of the container within its level (starting at 0)
  #
  # To display the subject of each message with indentation,
  # assuming your +msg+ pointer has a +subject+ field:
  #
  #   msgthr.walk_thread do |level, container, index|
  #     msg = container.msg
  #     subject = msg ? msg.subject : "[missing: <#{container.mid}>]"
  #     indent = '  ' * level
  #     printf("#{indent} % 3d. %s\n", index, subject)
  #   end
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
  #   It is typically a String or Integer, but may be anything usable
  #   as a Hash key in Ruby.
  #
  # * +refs+ should be an Array of unique identifiers belonging
  #   to ancestors of the current message.
  #   For mail and news messages, this is usually the parsed result
  #   of the "References:" header.  Order should be oldest to newest
  #   in terms of ancestry, with the last element being the
  #   immediate parent of the given message.
  #
  #   This is +nil+ for messages with no parent (root messages).
  #
  # * +msg+ is an opaque object which typically contains a
  #   Mail or Tmail object for handling mail.
  #
  # If +mid+ is a String, it is recommended to freeze the string before
  # calling this method to avoid wasting memory on hash keys.  Likewise
  # is true for any String objects in +refs+.
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

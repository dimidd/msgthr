# Copyright (C) 2016 all contributors <msgthr-public@80x24.org>
# License: GPL-2.0+ <https://www.gnu.org/licenses/gpl-2.0.txt>
require 'test/unit'
require 'msgthr'

class TestMsgthr < Test::Unit::TestCase
  def test_msgthr
    thr = Msgthr.new
    parent_child = ''
    # Note that C is added after B,
    # hence it's message will be empty after adding B
    expected_parent_child = '->B'
    thr.add('a', %w(c b), 'abc')
    thr.add('b', %w(c), 'B') do |parent, child|
      parent_child = "#{parent.msg}->#{child.msg}"
    end
    assert_equal parent_child, expected_parent_child
    thr.add('c', nil, 'c')
    thr.add('D', nil, 'D')
    thr.add('d', %w(missing), 'd')
    rset = thr.thread!
    rootset = thr.order! { |c| c.sort_by!(&:mid) }
    assert_same rset, rootset
    assert_equal %w(D c missing), rootset.map(&:mid)
    assert_equal 'D', rootset[0].msg
    assert_equal %w(b), rootset[1].children.map(&:mid)
    out = ''.b
    thr.walk_thread do |level, container, index|
      msg = container.msg
      summary = msg ? msg : "[missing: <#{container.mid}>]"
      indent = '  ' * level
      out << sprintf("#{indent} % 3d. %s\n", index, summary)
    end
    exp = <<EOF.b
   0. D
   1. c
     0. B
       0. abc
   2. [missing: <missing>]
     0. d
EOF
    assert_equal exp, out
  end

  def test_order_in_thread
    thr = Msgthr.new
    thr.add(1, nil, 'a')
    thr.add(2, [1], 'b')
    thr.thread! do |ary|
      ary.sort_by! do |cont|
        cur = cont.topmost
        cur ? cur : 0
      end
    end
    out = ''
    thr.walk_thread do |level, container, index|
      msg = container.msg
      out << "#{level} [#{index}] #{msg}\n"
    end
    exp = <<EOF.b
0 [0] a
1 [0] b
EOF
    assert_equal exp, out
  end

  def test_out_of_order
    thr = Msgthr.new
    thr.thread!
    assert_raise(Msgthr::StateError) { thr.add(1, nil, 'a') }
    thr.clear # make things good again, following should not raise:
    thr.add(1, nil, 'a')
    thr.thread!
    assert_raise(Msgthr::StateError) { thr.thread! }

    out = []
    thr.walk_thread do |level, container, index|
      msg = container.msg
      out << "#{level} [#{index}] #{msg}"
    end
    assert_equal [ '0 [0] a' ], out
    assert_raise(Msgthr::StateError) { thr.thread! { raise "DO NOT CALL" } }
    assert_raise(Msgthr::StateError) { thr.order! { |_| raise "DO NOT CALL" } }

    # this is legal, even if non-sensical
    thr.clear
    thr.walk_thread { |level, container, index| raise "DO NOT CALL" }
  end

  def test_short_add_to_walk
    thr = Msgthr.new
    thr.add(1, nil, 'a')
    thr.add(2, [1], 'b')
    out = ''
    thr.walk_thread do |level, container, index|
      msg = container.msg
      out << "#{level} [#{index}] #{msg}\n"
    end
    exp = <<EOF.b
0 [0] a
1 [0] b
EOF
    assert_equal exp, out
  end

  def test_add_child_callback
    thr = Msgthr.new
    threads = {}
    [1, 11, 12, 2, 21, 211].each{ |id| threads[id] = [id]}
    my_add = lambda do |id, refs, msg|
      thr.add(id, refs, msg) do |parent, child|
        threads[child.mid] = threads[parent.mid]
      end
    end
    # Create the following structure
    # 1
    #  \
    #  | 1.1
    #  \
    #    1.2
    # 2
    #   \
    #    2.1
    #       \
    #         2.1.1
    my_add.call(1, nil, '1')
    my_add.call(11, [1], '1.1')
    my_add.call(12, [1], '1.2')
    my_add.call(2, nil, '2')
    my_add.call(21, [2], '2.1')
    my_add.call(211, [21], '2.1.1')

    thr.thread!
    thr.rootset.each do |cnt|
      threads[cnt.mid][0] = cnt.msg
    end

    assert_equal threads[1], threads[11]
    assert_equal threads[1], threads[12]
    assert_equal threads[2], threads[21]
    assert_equal threads[2], threads[211]
    assert_equal threads[21], threads[211]
    assert_equal threads[1][0], '1'
    assert_equal threads[2][0], '2'
  end

end

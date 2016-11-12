# Copyright (C) 2016 all contributors <msgthr-public@80x24.org>
# License: GPL-2.0+ <https://www.gnu.org/licenses/gpl-2.0.txt>
require 'test/unit'
require 'msgthr'

class TestMsgthr < Test::Unit::TestCase
  def test_msgthr
    thr = Msgthr.new
    thr.add('a', %w(c b), 'abc')
    thr.add('b', %w(c), 'B')
    thr.add('c', nil, 'c')
    thr.add('D', nil, 'D')
    thr.add('d', nil, 'd')
    thr.thread!
    rootset = thr.order! { |c| c.sort! { |a, b| a.mid <=> b.mid } }
    assert_equal %w(D c d), rootset.map(&:mid)
    assert_equal 'D', rootset[0].msg
    assert_equal %w(b), rootset[1].children.map(&:mid)
  end
end

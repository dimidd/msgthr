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
    thr.add('d', %w(missing), 'd')
    thr.thread!
    rootset = thr.order! { |c| c.sort_by!(&:mid) }
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
end

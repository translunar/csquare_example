require "csquare"

g = CSquare::Generator.new("templates", "test.c") do |c|

  c.externs 'NM_MAX'       => :integer,
            'CblasNoTrans' => 'char',
            'stderr'       => :integer


  # This basic type should have its functions in the int directory
  c.blueprint(:integer, 'TYPE') do |t|
    t.type :i64, 'int64_t'
    t.type :i32, 'int32_t', :long => :i64
    t.type :i16, 'int16_t', :long => :i32

    # Generator will first look in templates/ and then look in templates/integer for each
    # of these functions.
    t.sources %w{gemm gcf}
  end


  # Do this to register abbreviations for basic types
  c.blueprint(:float, 'TYPE') do |t|
    t.type :f32, 'float'
    t.type :f64, 'double'
  end


  c.blueprint(:complex, 'TYPE', :r => 'FLOAT', :i => 'FLOAT') do |t|
    t.type :c64, 'complex64', :long => :c128, 'FLOAT' => :f32
    t.type :c128, 'complex128', 'FLOAT' => :f64

    t.sources %w{gemm downcast add2 add4 sub2 sub4 div2 div4 mul2 mul4}

    t.op :'==', 'TYPE' => '$0.r == $1.r && $0.i == $1.i', [:integer, :float] => '$0.r == $1 && $0.i == 0'
    t.op :'!=', 'TYPE' => '$0.r != $1.r || $0.i != $1.i', [:integer, :float] => '$0.r != $1 || $0.i != 0'

    t.op :'=', 'LONG_TYPE' => '$0 = downcast($1)', [:integer, :boolean, :float] => '$0 = (struct TYPE) { $1, 0 }'

    t.op :'*', 'TYPE' => 'mul2($0, $1)', :cast => 'mul4($0.r, $0.i, $1.r, $1.i)', [:integer, :float] => 'mul4($0.r, $0.i, $1, 0)'
    t.op :'/', 'TYPE' => 'div2($0, $1)', :cast => 'div4($0.r, $0.i, $1.r, $1.i)', [:integer, :float] => 'div4($0.r, $0.i, $1, 0)'
    t.op :'+', 'TYPE' => 'add2($0, $1)', :cast => 'add4($0.r, $0.i, $1.r, $1.i)'
    t.op :'-', 'TYPE' => 'sub2($0, $1)', :cast => 'sub4($0.r, $0.i, $1.r, $1.i)'

    # Don't specify patterns for these. Just including them will tell the blueprint to expand them.
    t.op :'*='
    t.op :'/='
    t.op :'+='
    t.op :'-='
  end


  # this basic type's operations should be in the rational directory.
  c.blueprint(:rational, 'TYPE', :n => 'INT', :d => 'INT') do |t|
    t.type :r32, 'rational32', :long => :r64, 'INT' => :i16
    t.type :r64, 'rational64', :long => :r128, 'INT' => :i32
    t.type :r128, 'rational128', 'INT' => :i64

    t.externs 'gcf' => 'INT'

    # Source files which should be templated for this type. Some of these may be needed for
    # the operations given by :op (below).
    t.sources %w{gemm downcast div2 div4 mul2 mul4 add2 add4 sub2 sub4}

    # Only use this form for simple operations that don't need temporary variables and don't call other functions.
    t.op :'==', 'TYPE' => '$0.n == $1.n && $0.d == $1.d', 1 => '$0.n == $0.d', 0 => '$0.n == 0'
    t.op :'!=', 'TYPE' => '$0.n != $1.n || $0.d != $1.d', 1 => '$0.n != $0.d', 0 => '$0.n != 0'

    t.op :'=', [:integer, :boolean] => '$0 = (struct TYPE) { $1, 1 }', 'LONG_TYPE' => '$0 = downcast($1)'

    t.op :'*', 'TYPE' => 'mul2($0, $1)', :cast => 'mul4($0.n, $0.d, $1.n, $1.d)', :integer => 'mul4($0.n, $0.d, $1, 1)'
    t.op :'/', 'TYPE' => 'div2($0, $1)', :cast => 'div4($0.n, $0.d, $1.n, $1.d)', :integer => 'div4($0.n, $0.d, $1, 1)'
    t.op :'+', 'TYPE' => 'add2($0, $1)', :cast => 'add4($0.n, $0.d, $1.n, $1.d)', :integer => 'add4($0.n, $0.d, $1, 1)'
    t.op :'-', 'TYPE' => 'sub2($0, $1)', :cast => 'sub4($0.n, $0.d, $1.n, $1.d)', :integer => 'sub4($0.n, $0.d, $1, 1)'

    t.op :'*='
    t.op :'/='
    t.op :'+='
    t.op :'-='

    t.op :'-@', 'TYPE' => '(struct $t) { -$0.n, $0.d }'
  end


=begin
  c.blueprint(:object, 'TYPE') do |t|
    t.type :v, 'VALUE'

    t.sources %w{gemm}
    # t.externs %w{INT2FIX rb_funcall rb_intern}

    t.op :'==', 'TYPE' => 'rb_funcall($0, rb_intern("=="), 1, $1)'

    t.op :'=', :integer => 'INT2FIX($0)'
    t.op :'+=', 'TYPE' => '$0 = rb_funcall($0, rb_intern("+"), 1, $1)'
    t.op :'-=', 'TYPE' => '$0 = rb_funcall($0, rb_intern("-"), 1, $1)'
    t.op :'*=', 'TYPE' => '$0 = rb_funcall($0, rb_intern("*"), 1, $1)'
    t.op :'/=', 'TYPE' => '$0 = rb_funcall($0, rb_intern("/"), 1, $1)'
    t.op :'%=', 'TYPE' => '$0 = rb_funcall($0, rb_intern("%"), 1, $1)'

    t.op :'+', 'TYPE' => 'rb_funcall($0, rb_intern("+"), 1, $1)'
    t.op :'-', 'TYPE' => 'rb_funcall($0, rb_intern("-"), 1, $1)'
    t.op :'*', 'TYPE' => 'rb_funcall($0, rb_intern("*"), 1, $1)'
    t.op :'/', 'TYPE' => 'rb_funcall($0, rb_intern("/"), 1, $1)'
    t.op :'%', 'TYPE' => 'rb_funcall($0, rb_intern("%"), 1, $1)'
  end
=end

end



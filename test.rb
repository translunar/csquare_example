require "csquare"

g = CSquare::Generator.new("templates", "test.c") do |c|

  c.externs 'NM_MAX' => :integer

  # This basic type should have its functions in the int directory
  c.template_type(:integer, 'TYPE') do |t|
    t.type :i64, 'int64_t'
    t.type :i32, 'int32_t', :long => :i64
    t.type :i16, 'int16_t', :long => :i32

    # Generator will first look in templates/ and then look in templates/integer for each
    # of these functions.
    t.sources %w{gemm gcf}
  end


  # Do this to register abbreviations for basic types
  c.template_type(:float, 'TYPE') do |t|
    t.type :f32, 'float'
    t.type :f64, 'double'
  end


  c.template_type(:complex, 'TYPE', :r => 'FLOAT', :i => 'FLOAT') do |t|

    t.type :c64, 'complex64', :long => :c128, 'FLOAT' => :f32
    t.type :c128, 'complex128', 'FLOAT' => :f64

    t.sources %w{gemm div2 div4 mul2 mul4}

    t.op :'==', 'TYPE' => '$0.r == $1.r && $0.i == $1.i', :integer => '$0.r == $1 && $0.i == 0', :float => '$0.r == $1 && $0.i == 0'

    assign_str = '$0 = (struct $t) { $1, 0 }'
    t.op :'=', :integer => assign_str, :boolean => assign_str, :float => assign_str

    t.op :'*', 'TYPE' => 'mul2($0, $1)', :integer => 'mul4($0.r, $0.i, $1, 0)', :float => 'mul4($0.r, $0.i, $1, 0)'
    t.op :'/', 'TYPE' => 'div2($0, $1)', :integer => 'div4($0.r, $0.i, $1, 0)', :float => 'div4($0.r, $0.i, $1, 0)'
    t.op :'+', 'TYPE' => 'add2($0, $1)'
    t.op :'-', 'TYPE' => 'sub2($0, $1)'
  end


  # this basic type's operations should be in the rational directory.
  c.template_type(:rational, 'TYPE', :n => 'INT', :d => 'INT') do |t|
    # 'INT' => :i16 tells it that any rational templates will also
    t.type :r32, 'rational32', :long => :r64, 'INT' => :i16
    t.type :r64, 'rational64', :long => :r128, 'INT' => :i32
    t.type :r128, 'rational128', 'INT' => :i64

    # Source files which should be templated for this type. Some of these may be needed for
    # the operations given by :op (below).
    t.sources %w{gemm div2 div4 mul2 mul4 add2 add4 sub2 sub4}

    t.externs 'gcf' => 'INT'

    # Only use this form for simple operations that don't need temporary variables and don't call other functions.
    t.op :'==', 'TYPE' => '$0.n == $1.n && $0.d == $1.d', 1 => '$0.n == $0.d', 0 => '$0.n == 0'

    t.op :'=', :integer => '$0 = (struct $t) { $1, 1 }', :boolean => '$0 = (struct $t) { $1, 1 }'

    t.op :'*', 'TYPE' => 'mul2($0, $1)', :integer => 'mul4($0.n, $0.d, $1, 1)'
    t.op :'/', 'TYPE' => 'div2($0, $1)', :integer => 'div4($0.n, $0.d, $1, 1)'
    t.op :'+', 'TYPE' => 'add2($0, $1)', :integer => 'add4($0.n, $0.d, $1, 1)'
    t.op :'-', 'TYPE' => 'sub2($0, $1)', :integer => 'sub4($0.n, $0.d, $1, 1)'

    t.op :'-@', 'TYPE' => '(struct $t) { -$0.n, $0.d }'
  end


  c.template_type(:object, 'TYPE') do |t|
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

end



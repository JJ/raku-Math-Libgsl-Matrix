use v6;

unit class Math::Libgsl::Vector::Complex64:ver<0.1.1>:auth<cpan:FRITH>;

use Math::Libgsl::Raw::Complex :ALL;
use Math::Libgsl::Raw::Matrix::Complex64 :ALL;
use Math::Libgsl::Exception;
use Math::Libgsl::Constants;
use Math::Libgsl::Vector;
use NativeCall;

class View {
  has gsl_vector_complex_view $.view;
  submethod BUILD { $!view = alloc_gsl_vector_complex_view }
  submethod DESTROY { free_gsl_vector_complex_view($!view) }
}

has gsl_vector_complex $.vector;
has Bool               $.view = False;

multi method new(Int $size!) { self.bless(:$size) }
multi method new(Int :$size!) { self.bless(:$size) }
multi method new(gsl_vector_complex :$vector!) { self.bless(:$vector) }

submethod BUILD(Int :$size?, gsl_vector_complex :$vector?) {
  $!vector = gsl_vector_complex_calloc($size) with $size;
  with $vector {
    $!vector = $vector;
    $!view   = True;
  }
}

submethod DESTROY {
  gsl_vector_complex_free($!vector) unless $!view;
}
# Accessors
method get(Int:D $index! where * < $!vector.size --> Complex) {
  my gsl_complex $c = alloc_gsl_complex;
  mgsl_vector_complex_get($!vector, $index, $c);
  my Complex $nc = $c.dat[0] + i * $c.dat[1];
  free_gsl_complex($c);
  $nc;
}
method AT-POS(Math::Libgsl::Vector::Complex64:D: Int:D $index! where * < $!vector.size --> Complex) {
  my $c = alloc_gsl_complex;
  mgsl_vector_complex_get($!vector, $index, $c);
  my Complex $nc = $c.dat[0] + i * $c.dat[1];
  free_gsl_complex($c);
  $nc;
}
method set(Int:D $index! where * < $!vector.size, Complex $x!) {
  my $c = alloc_gsl_complex;
  mgsl_complex_rect($x.re, $x.im, $c);
  mgsl_vector_complex_set($!vector, $index, $c);
  free_gsl_complex($c);
  self
}
method ASSIGN-POS(Math::Libgsl::Vector::Complex64:D: Int:D $index! where * < $!vector.size, Complex(Cool) $x!) {
  my $c = alloc_gsl_complex;
  mgsl_complex_rect($x.re, $x.im, $c);
  mgsl_vector_complex_set($!vector, $index, $c);
  free_gsl_complex($c);
}
method setall(Complex $x!) {
  my $c = alloc_gsl_complex;
  mgsl_complex_rect($x.re, $x.im, $c);
  mgsl_vector_complex_set_all($!vector, $c);
  free_gsl_complex($c);
  self
}
method zero() { gsl_vector_complex_set_zero($!vector); self }
method basis(Int:D $index! where * < $!vector.size) {
  my $ret = gsl_vector_complex_set_basis($!vector, $index);
  fail X::Libgsl.new: errno => $ret, error => "Can't make a basis vector" if $ret ≠ GSL_SUCCESS;
  self
}
# IO
method write(Str $filename!) {
  my $ret = mgsl_vector_complex_fwrite($filename, $!vector);
  fail X::Libgsl.new: errno => $ret, error => "Can't write the vector" if $ret ≠ GSL_SUCCESS;
  self
}
method read(Str $filename!) {
  my $ret = mgsl_vector_complex_fread($filename, $!vector);
  fail X::Libgsl.new: errno => $ret, error => "Can't read the vector" if $ret ≠ GSL_SUCCESS;
  self
}
method printf(Str $filename!, Str $format!) {
  my $ret = mgsl_vector_complex_fprintf($filename, $!vector, $format);
  fail X::Libgsl.new: errno => $ret, error => "Can't print the vector" if $ret ≠ GSL_SUCCESS;
  self
}
method scanf(Str $filename!) {
  my $ret = mgsl_vector_complex_fscanf($filename, $!vector);
  fail X::Libgsl.new: errno => $ret, error => "Can't scan the vector" if $ret ≠ GSL_SUCCESS;
  self
}
# View
method subvector(Math::Libgsl::Vector::Complex64::View $vv, size_t $offset where * < $!vector.size, size_t $n) {
fail X::Libgsl.new: errno => GSL_EDOM, error => "Subvector index out of bound" if $offset + $n > $!vector.size;
  Math::Libgsl::Vector::Complex64.new: vector => mgsl_vector_complex_subvector($vv.view, $!vector, $offset, $n);
}
method subvector-stride(Math::Libgsl::Vector::Complex64::View $vv, size_t $offset where * < $!vector.size, size_t $stride, size_t $n) {
fail X::Libgsl.new: errno => GSL_EDOM, error => "Subvector index out of bound" if $offset + $n > $!vector.size;
  Math::Libgsl::Vector::Complex64.new: vector => mgsl_vector_complex_subvector_with_stride($vv.view, $!vector, $offset, $stride, $n);
}
sub view-complex64-array(Math::Libgsl::Vector::Complex64::View $vv, @array) is export(:withsub) {
  my CArray[num64] $a .= new: @array».Num;
  Math::Libgsl::Vector::Complex64.new: vector => mgsl_vector_complex_view_array($vv.view, $a, @array.elems);
}
sub view-complex64-array-stride(Math::Libgsl::Vector::Complex64::View $vv, @array, size_t $stride) is export(:withsub) {
  my CArray[num64] $a .= new: @array».Num;
  Math::Libgsl::Vector::Complex64.new: vector => mgsl_vector_complex_view_array_with_stride($vv.view, $a, $stride, @array.elems);
}
method complex64-real(Math::Libgsl::Vector::View $vv) {
  Math::Libgsl::Vector.new: vector => mgsl_vector_complex_real($vv.view, $!vector);
}
method complex64-imag(Math::Libgsl::Vector::View $vv) {
  Math::Libgsl::Vector.new: vector => mgsl_vector_complex_imag($vv.view, $!vector);
}
# Copy
method copy(Math::Libgsl::Vector::Complex64 $src where $!vector.size == .vector.size) {
  my $ret = gsl_vector_complex_memcpy($!vector, $src.vector);
  fail X::Libgsl.new: errno => $ret, error => "Can't copy the vector" if $ret ≠ GSL_SUCCESS;
  self
}
method swap(Math::Libgsl::Vector::Complex64 $w where $!vector.size == .vector.size) {
  my $ret = gsl_vector_complex_swap($!vector, $w.vector);
  fail X::Libgsl.new: errno => $ret, error => "Can't swap vectors" if $ret ≠ GSL_SUCCESS;
  self
}
# Exchanging elements
method swap-elems(Int $i where * < $!vector.size, Int $j where * < $!vector.size) {
  my $ret = gsl_vector_complex_swap_elements($!vector, $i, $j);
  fail X::Libgsl.new: errno => $ret, error => "Can't swap elements" if $ret ≠ GSL_SUCCESS;
  self
}
method reverse() {
  my $ret = gsl_vector_complex_reverse($!vector);
  fail X::Libgsl.new: errno => $ret, error => "Can't reverse the vector" if $ret ≠ GSL_SUCCESS;
  self
}
# Vector operations
method add(Math::Libgsl::Vector::Complex64 $b where $!vector.size == .vector.size) {
  my $ret = gsl_vector_complex_add($!vector, $b.vector);
  fail X::Libgsl.new: errno => $ret, error => "Can't add two vectors" if $ret ≠ GSL_SUCCESS;
  self
}
method sub(Math::Libgsl::Vector::Complex64 $b where $!vector.size == .vector.size) {
  my $ret = gsl_vector_complex_sub($!vector, $b.vector);
  fail X::Libgsl.new: errno => $ret, error => "Can't sub two vectors" if $ret ≠ GSL_SUCCESS;
  self
}
method mul(Math::Libgsl::Vector::Complex64 $b where $!vector.size == .vector.size) {
  my $ret = gsl_vector_complex_mul($!vector, $b.vector);
  fail X::Libgsl.new: errno => $ret, error => "Can't mul two vectors" if $ret ≠ GSL_SUCCESS;
  self
}
method div(Math::Libgsl::Vector::Complex64 $b where $!vector.size == .vector.size) {
  my $ret = gsl_vector_complex_div($!vector, $b.vector);
  fail X::Libgsl.new: errno => $ret, error => "Can't div two vectors" if $ret ≠ GSL_SUCCESS;
  self
}
method scale(Complex() $x) {
  my $c = alloc_gsl_complex;
  mgsl_complex_rect($x.re, $x.im, $c);
  my $ret = mgsl_vector_complex_scale($!vector, $c);
  free_gsl_complex($c);
  fail X::Libgsl.new: errno => $ret, error => "Can't scale the vector" if $ret ≠ GSL_SUCCESS;
  self
}
method add-constant(Complex() $x) {
  my $c = alloc_gsl_complex;
  mgsl_complex_rect($x.re, $x.im, $c);
  my $ret = mgsl_vector_complex_add_constant($!vector, $c);
  free_gsl_complex($c);
  fail X::Libgsl.new: errno => $ret, error => "Can't add a constant to all elements" if $ret ≠ GSL_SUCCESS;
  self
}
# Vector properties
method is-null(--> Bool)   { gsl_vector_complex_isnull($!vector)   ?? True !! False }
method is-pos(--> Bool)    { gsl_vector_complex_ispos($!vector)    ?? True !! False }
method is-neg(--> Bool)    { gsl_vector_complex_isneg($!vector)    ?? True !! False }
method is-nonneg(--> Bool) { gsl_vector_complex_isnonneg($!vector) ?? True !! False }
method is-equal(Math::Libgsl::Vector::Complex64 $b --> Bool) { gsl_vector_complex_equal($!vector, $b.vector) ?? True !! False }

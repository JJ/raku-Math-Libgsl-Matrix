use v6;

unit class Math::Libgsl::Vector::UInt32:ver<0.1.2>:auth<cpan:FRITH>;

use Math::Libgsl::Raw::Matrix::UInt32 :ALL;
use Math::Libgsl::Exception;
use Math::Libgsl::Constants;
use NativeCall;

class View {
  has gsl_vector_uint_view $.view;
  submethod BUILD { $!view = alloc_gsl_vector_uint_view }
  submethod DESTROY { free_gsl_vector_uint_view($!view) }
}

has gsl_vector_uint $.vector;
has Bool            $.view = False;

multi method new(Int $size!) { self.bless(:$size) }
multi method new(Int :$size!) { self.bless(:$size) }
multi method new(gsl_vector_uint :$vector!) { self.bless(:$vector) }

submethod BUILD(Int :$size?, gsl_vector_uint :$vector?) {
  $!vector = gsl_vector_uint_calloc($size) with $size;
  with $vector {
    $!vector = $vector;
    $!view   = True;
  }
}

submethod DESTROY {
  gsl_vector_uint_free($!vector) unless $!view;
}
# Accessors
method get(Int:D $index! where * < $!vector.size --> Int) { gsl_vector_uint_get($!vector, $index) }
method AT-POS(Math::Libgsl::Vector::UInt32:D: Int:D $index! where * < $!vector.size --> Int) {
  gsl_vector_uint_get(self.vector, $index)
}
method set(Int:D $index! where * < $!vector.size, Int(Cool) $x!) { gsl_vector_uint_set($!vector, $index, $x); self }
method ASSIGN-POS(Math::Libgsl::Vector::UInt32:D: Int:D $index! where * < $!vector.size, Int(Cool) $x!) {
  gsl_vector_uint_set(self.vector, $index, $x)
}
method setall(Int(Cool) $x!) { gsl_vector_uint_set_all($!vector, $x); self }
method zero() { gsl_vector_uint_set_zero($!vector); self }
method basis(Int:D $index! where * < $!vector.size) {
  my $ret = gsl_vector_uint_set_basis($!vector, $index);
  fail X::Libgsl.new: errno => $ret, error => "Can't make a basis vector" if $ret ≠ GSL_SUCCESS;
  self
}
# IO
method write(Str $filename!) {
  my $ret = mgsl_vector_uint_fwrite($filename, $!vector);
  fail X::Libgsl.new: errno => $ret, error => "Can't write the vector" if $ret ≠ GSL_SUCCESS;
  self
}
method read(Str $filename!) {
  my $ret = mgsl_vector_uint_fread($filename, $!vector);
  fail X::Libgsl.new: errno => $ret, error => "Can't read the vector" if $ret ≠ GSL_SUCCESS;
  self
}
method printf(Str $filename!, Str $format!) {
  my $ret = mgsl_vector_uint_fprintf($filename, $!vector, $format);
  fail X::Libgsl.new: errno => $ret, error => "Can't print the vector" if $ret ≠ GSL_SUCCESS;
  self
}
method scanf(Str $filename!) {
  my $ret = mgsl_vector_uint_fscanf($filename, $!vector);
  fail X::Libgsl.new: errno => $ret, error => "Can't scan the vector" if $ret ≠ GSL_SUCCESS;
  self
}
# View
method subvector(Math::Libgsl::Vector::UInt32::View $vv, size_t $offset where * < $!vector.size, size_t $n) {
  fail X::Libgsl.new: errno => GSL_EDOM, error => "Subvector index out of bound" if $offset + $n > $!vector.size;
  Math::Libgsl::Vector::UInt32.new: vector => mgsl_vector_uint_subvector($vv.view, $!vector, $offset, $n);
}
method subvector-stride(Math::Libgsl::Vector::UInt32::View $vv, size_t $offset where * < $!vector.size, size_t $stride, size_t $n) {
  fail X::Libgsl.new: errno => GSL_EDOM, error => "Subvector index out of bound" if $offset + $n > $!vector.size;
  Math::Libgsl::Vector::UInt32.new: vector => mgsl_vector_uint_subvector_with_stride($vv.view, $!vector, $offset, $stride, $n);
}
sub view-uint32-array(Math::Libgsl::Vector::UInt32::View $vv, @array) is export(:withsub) {
  my CArray[uint32] $a .= new: @array».Int;
  Math::Libgsl::Vector::UInt32.new: vector => mgsl_vector_uint_view_array($vv.view, $a, @array.elems);
}
sub view-uint32-array-stride(Math::Libgsl::Vector::UInt32::View $vv, @array, size_t $stride) is export(:withsub) {
  my CArray[uint32] $a .= new: @array».Int;
  Math::Libgsl::Vector::UInt32.new: vector => mgsl_vector_uint_view_array_with_stride($vv.view, $a, $stride, @array.elems);
}
# Copy
method copy(Math::Libgsl::Vector::UInt32 $src where $!vector.size == .vector.size) {
  my $ret = gsl_vector_uint_memcpy($!vector, $src.vector);
  fail X::Libgsl.new: errno => $ret, error => "Can't copy the vector" if $ret ≠ GSL_SUCCESS;
  self
}
method swap(Math::Libgsl::Vector::UInt32 $w where $!vector.size == .vector.size) {
  my $ret = gsl_vector_uint_swap($!vector, $w.vector);
  fail X::Libgsl.new: errno => $ret, error => "Can't swap vectors" if $ret ≠ GSL_SUCCESS;
  self
}
# Exchanging elements
method swap-elems(Int $i where * < $!vector.size, Int $j where * < $!vector.size) {
  my $ret = gsl_vector_uint_swap_elements($!vector, $i, $j);
  fail X::Libgsl.new: errno => $ret, error => "Can't swap elements" if $ret ≠ GSL_SUCCESS;
  self
}
method reverse() {
  my $ret = gsl_vector_uint_reverse($!vector);
  fail X::Libgsl.new: errno => $ret, error => "Can't reverse the vector" if $ret ≠ GSL_SUCCESS;
  self
}
# Vector operations
method add(Math::Libgsl::Vector::UInt32 $b where $!vector.size == .vector.size) {
  my $ret = gsl_vector_uint_add($!vector, $b.vector);
  fail X::Libgsl.new: errno => $ret, error => "Can't add two vectors" if $ret ≠ GSL_SUCCESS;
  self
}
method sub(Math::Libgsl::Vector::UInt32 $b where $!vector.size == .vector.size) {
  my $ret = gsl_vector_uint_sub($!vector, $b.vector);
  fail X::Libgsl.new: errno => $ret, error => "Can't sub two vectors" if $ret ≠ GSL_SUCCESS;
  self
}
method mul(Math::Libgsl::Vector::UInt32 $b where $!vector.size == .vector.size) {
  my $ret = gsl_vector_uint_mul($!vector, $b.vector);
  fail X::Libgsl.new: errno => $ret, error => "Can't mul two vectors" if $ret ≠ GSL_SUCCESS;
  self
}
method div(Math::Libgsl::Vector::UInt32 $b where $!vector.size == .vector.size) {
  my $ret = gsl_vector_uint_div($!vector, $b.vector);
  fail X::Libgsl.new: errno => $ret, error => "Can't div two vectors" if $ret ≠ GSL_SUCCESS;
  self
}
method scale(Int(Cool) $x) {
  my $ret = gsl_vector_uint_scale($!vector, $x);
  fail X::Libgsl.new: errno => $ret, error => "Can't scale the vector" if $ret ≠ GSL_SUCCESS;
  self
}
method add-constant(Int(Cool) $x) {
  my $ret = gsl_vector_uint_add_constant($!vector, $x);
  fail X::Libgsl.new: errno => $ret, error => "Can't add a constant to the elements" if $ret ≠ GSL_SUCCESS;
  self
}
# Finding maximum and minimum elements of vectors
method max(--> UInt) { gsl_vector_uint_max($!vector) }
method min(--> UInt) { gsl_vector_uint_min($!vector) }
method minmax(--> List)
{
  my uint32 ($min, $max);
  gsl_vector_uint_minmax($!vector, $min, $max);
  return $min, $max;
}
method max-index(--> Int) { gsl_vector_uint_max_index($!vector) }
method min-index(--> Int) { gsl_vector_uint_min_index($!vector) }
method minmax-index(--> List)
{
  my size_t ($imin, $imax);
  gsl_vector_uint_minmax_index($!vector, $imin, $imax);
  return $imin, $imax;
}
# Vector properties
method is-null(--> Bool)   { gsl_vector_uint_isnull($!vector)   ?? True !! False }
method is-pos(--> Bool)    { gsl_vector_uint_ispos($!vector)    ?? True !! False }
method is-neg(--> Bool)    { gsl_vector_uint_isneg($!vector)    ?? True !! False }
method is-nonneg(--> Bool) { gsl_vector_uint_isnonneg($!vector) ?? True !! False }
method is-equal(Math::Libgsl::Vector::UInt32 $b --> Bool) { gsl_vector_uint_equal($!vector, $b.vector) ?? True !! False }

use v6;

unit class Math::Libgsl::Matrix::Complex64:ver<0.1.4>:auth<cpan:FRITH>;

use Math::Libgsl::Raw::Complex :ALL;
use Math::Libgsl::Raw::Matrix::Complex64 :ALL;
use Math::Libgsl::Exception;
use Math::Libgsl::Constants;
use Math::Libgsl::Vector::Complex64;
use NativeCall;

class View {
  has gsl_matrix_complex_view $.view;
  submethod BUILD { $!view = alloc_gsl_matrix_complex_view }
  submethod DESTROY { free_gsl_matrix_complex_view($!view) }
}

has gsl_matrix_complex $.matrix;
has Bool               $.view = False;

multi method new(Int $size1!, Int $size2!)   { self.bless(:$size1, :$size2) }
multi method new(Int :$size1!, Int :$size2!) { self.bless(:$size1, :$size2) }
multi method new(gsl_matrix_complex :$matrix!) { self.bless(:$matrix) }

submethod BUILD(Int :$size1?, Int :$size2?, gsl_matrix_complex :$matrix?) {
  $!matrix = gsl_matrix_complex_calloc($size1, $size2) if $size1.defined && $size2.defined;
  with $matrix {
    $!matrix = $matrix;
    $!view   = True;
  }
}

submethod DESTROY {
  gsl_matrix_complex_free($!matrix) unless $!view;
}
# Accessors
method get(Int:D $i! where * < $!matrix.size1, Int:D $j! where * < $!matrix.size2 --> Complex) {
  my $res = alloc_gsl_complex;
  mgsl_matrix_complex_get($!matrix, $i, $j, $res);
  my $c = $res.dat[0] + i * $res.dat[1];
  free_gsl_complex($res);
  $c
}
method AT-POS(Math::Libgsl::Matrix::Complex64:D: Int:D $i! where * < $!matrix.size1, Int:D $j! where * < $!matrix.size2 --> Complex) {
  my $res = alloc_gsl_complex;
  mgsl_matrix_complex_get(self.matrix, $i, $j, $res);
  my $c = $res.dat[0] + i * $res.dat[1];
  free_gsl_complex($res);
  $c
}
method set(Int:D $i! where * < $!matrix.size1, Int:D $j! where * < $!matrix.size2, Complex(Cool) $x!) {
  my $c = alloc_gsl_complex;
  mgsl_complex_rect($x.re, $x.im, $c);
  mgsl_matrix_complex_set($!matrix, $i, $j, $c);
  free_gsl_complex($c);
  self
}
method ASSIGN-POS(Math::Libgsl::Matrix::Complex64:D: Int:D $i! where * < $!matrix.size1, Int:D $j! where * < $!matrix.size2, Complex(Cool) $x!) {
  my $c = alloc_gsl_complex;
  mgsl_complex_rect($x.re, $x.im, $c);
  mgsl_matrix_complex_set(self.matrix, $i, $j, $c);
  free_gsl_complex($c)
}
method setall(Complex(Cool) $x!) {
  my $c = alloc_gsl_complex;
  mgsl_complex_rect($x.re, $x.im, $c);
  mgsl_matrix_complex_set_all($!matrix, $c);
  free_gsl_complex($c);
  self
}
method zero() { gsl_matrix_complex_set_zero($!matrix); self }
method identity() { gsl_matrix_complex_set_identity($!matrix); self }
# IO
method write(Str $filename!) {
  my $ret = mgsl_matrix_complex_fwrite($filename, $!matrix);
  fail X::Libgsl.new: errno => $ret, error => "Can't write the matrix" if $ret ≠ GSL_SUCCESS;
  self
}
method read(Str $filename!) {
  my $ret = mgsl_matrix_complex_fread($filename, $!matrix);
  fail X::Libgsl.new: errno => $ret, error => "Can't read the matrix" if $ret ≠ GSL_SUCCESS;
  self
}
method printf(Str $filename!, Str $format!) {
  my $ret = mgsl_matrix_complex_fprintf($filename, $!matrix, $format);
  fail X::Libgsl.new: errno => $ret, error => "Can't print the matrix" if $ret ≠ GSL_SUCCESS;
  self
}
method scanf(Str $filename!) {
  my $ret = mgsl_matrix_complex_fscanf($filename, $!matrix);
  fail X::Libgsl.new: errno => $ret, error => "Can't scan the matrix" if $ret ≠ GSL_SUCCESS;
  self
}
# View
method submatrix(Math::Libgsl::Matrix::Complex64::View $mv, size_t $k1 where * < $!matrix.size1, size_t $k2 where * < $!matrix.size2, size_t $n1, size_t $n2) {
  fail X::Libgsl.new: errno => GSL_EDOM, error => "Submatrix indices out of bound"
    if $k1 + $n1 > $!matrix.size1 || $k2 + $n2 > $!matrix.size2;
  Math::Libgsl::Matrix::Complex64.new: matrix => mgsl_matrix_complex_submatrix($mv.view, $!matrix, $k1, $k2, $n1, $n2);
}
sub mat-view-array(Math::Libgsl::Matrix::Complex64::View $mv, @array where { @array ~~ Array && @array.shape.elems == 2 }) is export(:withsub) {
  my CArray[num64] $a .= new: @array.Array».Num;
  Math::Libgsl::Matrix::Complex64.new: matrix => mgsl_matrix_complex_view_array($mv.view, $a, @array.shape[0], (@array.shape[1] / 2).Int);
}
sub mat-view-array-tda(Math::Libgsl::Matrix::Complex64::View $mv, @array where { @array ~~ Array && @array.shape.elems == 2 }, size_t $tda) is export(:withsub) {
  fail X::Libgsl.new: errno => GSL_EDOM, error => "tda out of bound" if $tda < @array.shape[1];
  my CArray[num64] $a .= new: @array.Array».Num;
  Math::Libgsl::Matrix::Complex64.new: matrix => mgsl_matrix_complex_view_array_with_tda($mv.view, $a, @array.shape[0], (@array.shape[1] / 2).Int, $tda);
}
sub mat-view-vector(Math::Libgsl::Matrix::Complex64::View $mv, Math::Libgsl::Vector::Complex64 $v, size_t $n1, size_t $n2) is export(:withsub) {
  Math::Libgsl::Matrix::Complex64.new: matrix => mgsl_matrix_complex_view_vector($mv.view, $v.vector, $n1, $n2);
}
sub mat-view-vector-tda(Math::Libgsl::Matrix::Complex64::View $mv, Math::Libgsl::Vector::Complex64 $v, size_t $n1, size_t $n2, size_t $tda) is export(:withsub) {
  fail X::Libgsl.new: errno => GSL_EDOM, error => "tda out of bound" if $n2 > $tda ;
  Math::Libgsl::Matrix::Complex64.new: matrix => mgsl_matrix_complex_view_vector_with_tda($mv.view, $v.vector, $n1, $n2, $tda);
}
method row-view(Math::Libgsl::Vector::Complex64::View $vv, size_t $i where * < $!matrix.size1) {
  Math::Libgsl::Vector::Complex64.new: vector => mgsl_matrix_complex_row($vv.view, $!matrix, $i);
}
method col-view(Math::Libgsl::Vector::Complex64::View $vv, size_t $j where * < $!matrix.size2) {
  Math::Libgsl::Vector::Complex64.new: vector => mgsl_matrix_complex_column($vv.view, $!matrix, $j);
}
method subrow-view(Math::Libgsl::Vector::Complex64::View $vv, size_t $i where * < $!matrix.size1, size_t $offset, size_t $n) {
  Math::Libgsl::Vector::Complex64.new: vector => mgsl_matrix_complex_subrow($vv.view, $!matrix, $i, $offset, $n);
}
method subcol-view(Math::Libgsl::Vector::Complex64::View $vv, size_t $j where * < $!matrix.size2, size_t $offset, size_t $n) {
  Math::Libgsl::Vector::Complex64.new: vector => mgsl_matrix_complex_subcolumn($vv.view, $!matrix, $j, $offset, $n);
}
method diagonal-view(Math::Libgsl::Vector::Complex64::View $vv) {
  Math::Libgsl::Vector::Complex64.new: vector => mgsl_matrix_complex_diagonal($vv.view, $!matrix);
}
method subdiagonal-view(Math::Libgsl::Vector::Complex64::View $vv, size_t $k where * < min($!matrix.size1, $!matrix.size2)) {
  Math::Libgsl::Vector::Complex64.new: vector => mgsl_matrix_complex_subdiagonal($vv.view, $!matrix, $k);
}
method superdiagonal-view(Math::Libgsl::Vector::Complex64::View $vv, size_t $k where * < min($!matrix.size1, $!matrix.size2)) {
  Math::Libgsl::Vector::Complex64.new: vector => mgsl_matrix_complex_superdiagonal($vv.view, $!matrix, $k);
}
# Copying matrices
method copy(Math::Libgsl::Matrix::Complex64 $src where $!matrix.size1 == .matrix.size1 && $!matrix.size2 == .matrix.size2) {
  my $ret = gsl_matrix_complex_memcpy($!matrix, $src.matrix);
  fail X::Libgsl.new: errno => $ret, error => "Can't copy the matrix" if $ret ≠ GSL_SUCCESS;
  self
}
method swap(Math::Libgsl::Matrix::Complex64 $src where $!matrix.size1 == .matrix.size1 && $!matrix.size2 == .matrix.size2) {
  my $ret = gsl_matrix_complex_swap($!matrix, $src.matrix);
  fail X::Libgsl.new: errno => $ret, error => "Can't swap the matrices" if $ret ≠ GSL_SUCCESS;
  self
}
method tricpy(Math::Libgsl::Matrix::Complex64 $src where $!matrix.size1 == .matrix.size1 && $!matrix.size2 == .matrix.size2, Int $Uplo, Int $Diag) {
  my $ret;
  if $gsl-version > 2.5 {
    $ret = gsl_matrix_complex_tricpy($Uplo, $Diag, $!matrix, $src.matrix);
  } else {
    $ret = gsl_matrix_complex_tricpy($Uplo == CblasUpper ?? 'U'.ord !! 'L'.ord, $Diag == CblasUnit ?? 1 !! 0, $!matrix, $src.matrix);
  }
  fail X::Libgsl.new: errno => $ret, error => "Can't triangular-copy the matrix" if $ret ≠ GSL_SUCCESS;
  self
}
# Rows and columns
method get-row(Int:D $i where * < $!matrix.size1) {
  my gsl_vector_complex $v = gsl_vector_complex_calloc($!matrix.size2);
  LEAVE { gsl_vector_complex_free($v) }
  my $ret = gsl_matrix_complex_get_row($v, $!matrix, $i);
  fail X::Libgsl.new: errno => $ret, error => "Can't get row" if $ret ≠ GSL_SUCCESS;
  my @row = gather take mgsl_vector_complex_get($v, $_) for ^$!matrix.size2;
}
method get-col(Int:D $j where * < $!matrix.size2) {
  my gsl_vector_complex $v = gsl_vector_complex_calloc($!matrix.size1);
  LEAVE { gsl_vector_complex_free($v) }
  my $ret = gsl_matrix_complex_get_col($v, $!matrix, $j);
  fail X::Libgsl.new: errno => $ret, error => "Can't get col" if $ret ≠ GSL_SUCCESS;
  my @col = gather take mgsl_vector_complex_get($v, $_) for ^$!matrix.size1;
}
multi method set-row(Int:D $i where * ≤ $!matrix.size1, @row where *.elems == $!matrix.size2) {
  my gsl_vector_complex $v = gsl_vector_complex_calloc($!matrix.size2);
  LEAVE { gsl_vector_complex_free($v) }
  mgsl_vector_complex_set($v, $_, @row[$_].Num) for ^$!matrix.size2;
  my $ret = gsl_matrix_complex_set_row($!matrix, $i, $v);
  fail X::Libgsl.new: errno => $ret, error => "Can't set row" if $ret ≠ GSL_SUCCESS;
  self
}
multi method set-row(Int:D $i where * ≤ $!matrix.size1, Math::Libgsl::Vector::Complex64 $v where .vector.size == $!matrix.size2) {
  my $ret = gsl_matrix_complex_set_row($!matrix, $i, $v.vector);
  fail X::Libgsl.new: errno => $ret, error => "Can't set row" if $ret ≠ GSL_SUCCESS;
  self
}
multi method set-col(Int:D $j where * ≤ $!matrix.size2, @col where *.elems == $!matrix.size1) {
  my gsl_vector_complex $v = gsl_vector_complex_calloc($!matrix.size1);
  LEAVE { gsl_vector_complex_free($v) }
  mgsl_vector_complex_set($v, $_, @col[$_].Num) for ^$!matrix.size1;
  my $ret = gsl_matrix_complex_set_col($!matrix, $j, $v);
  fail X::Libgsl.new: errno => $ret, error => "Can't set col" if $ret ≠ GSL_SUCCESS;
  self
}
multi method set-col(Int:D $j where * ≤ $!matrix.size2, Math::Libgsl::Vector::Complex64 $v where .vector.size == $!matrix.size1) {
  my $ret = gsl_matrix_complex_set_col($!matrix, $j, $v.vector);
  fail X::Libgsl.new: errno => $ret, error => "Can't set col" if $ret ≠ GSL_SUCCESS;
  self
}
# Exchanging rows and columns
method swap-rows(Int:D $i where * ≤ $!matrix.size1, Int:D $j where * ≤ $!matrix.size1) {
  my $ret = gsl_matrix_complex_swap_rows($!matrix, $i, $j);
  fail X::Libgsl.new: errno => $ret, error => "Can't swap rows" if $ret ≠ GSL_SUCCESS;
  self
}
method swap-cols(Int:D $i where * ≤ $!matrix.size2, Int:D $j where * ≤ $!matrix.size2) {
  my $ret = gsl_matrix_complex_swap_columns($!matrix, $i, $j);
  fail X::Libgsl.new: errno => $ret, error => "Can't swap columns" if $ret ≠ GSL_SUCCESS;
  self
}
method swap-rowcol(Int:D $i where * ≤ $!matrix.size1, Int:D $j where * ≤ $!matrix.size1) {
  fail X::Libgsl.new: errno => GSL_ENOTSQR, error => "Not a square matrix" if $!matrix.size1 ≠ $!matrix.size2;
  my $ret = gsl_matrix_complex_swap_rowcol($!matrix, $i, $j);
  fail X::Libgsl.new: errno => $ret, error => "Can't swap row & column" if $ret ≠ GSL_SUCCESS;
  self
}
method copy-transpose(Math::Libgsl::Matrix::Complex64 $src where $!matrix.size1 == .matrix.size2 && $!matrix.size2 == .matrix.size1) {
  my $ret = gsl_matrix_complex_transpose_memcpy($!matrix, $src.matrix);
  fail X::Libgsl.new: errno => $ret, error => "Can't copy and transpose" if $ret ≠ GSL_SUCCESS;
  self
}
method transpose() {
  fail X::Libgsl.new: errno => GSL_ENOTSQR, error => "Not a square matrix" if $!matrix.size1 ≠ $!matrix.size2;
  my $ret = gsl_matrix_complex_transpose($!matrix);
  fail X::Libgsl.new: errno => $ret, error => "Can't transpose" if $ret ≠ GSL_SUCCESS;
  self
}
method transpose-tricpy(Math::Libgsl::Matrix::Complex64 $src where $!matrix.size1 == .matrix.size2 && $!matrix.size2 == .matrix.size1, Int $Uplo, Int $Diag) {
  fail X::Libgsl.new: errno => GSL_ENOTSQR, error => "Not a square matrix" if $!matrix.size1 ≠ $!matrix.size2;
  my $ret;
  if $gsl-version > 2.5 {
    $ret = gsl_matrix_complex_transpose_tricpy($Uplo, $Diag, $!matrix, $src.matrix);
  } else {
    $ret = gsl_matrix_complex_transpose_tricpy($Uplo == CblasUpper ?? 'U'.ord !! 'L'.ord, $Diag == CblasUnit ?? 1 !! 0, $!matrix, $src.matrix);
  }
  fail X::Libgsl.new: errno => $ret, error => "Can't triangular-copy transpose" if $ret ≠ GSL_SUCCESS;
  self
}
# Matrix operations
method add(Math::Libgsl::Matrix::Complex64 $b where $!matrix.size1 == .matrix.size1 && $!matrix.size2 == .matrix.size2) {
  my $ret = gsl_matrix_complex_add($!matrix, $b.matrix);
  fail X::Libgsl.new: errno => $ret, error => "Can't add" if $ret ≠ GSL_SUCCESS;
  self
}
method sub(Math::Libgsl::Matrix::Complex64 $b where $!matrix.size1 == .matrix.size1 && $!matrix.size2 == .matrix.size2) {
  my $ret = gsl_matrix_complex_sub($!matrix, $b.matrix);
  fail X::Libgsl.new: errno => $ret, error => "Can't sub" if $ret ≠ GSL_SUCCESS;
  self
}
method mul(Math::Libgsl::Matrix::Complex64 $b where $!matrix.size1 == .matrix.size1 && $!matrix.size2 == .matrix.size2) {
  my $ret = gsl_matrix_complex_mul_elements($!matrix, $b.matrix);
  fail X::Libgsl.new: errno => $ret, error => "Can't mul" if $ret ≠ GSL_SUCCESS;
  self
}
method div(Math::Libgsl::Matrix::Complex64 $b where $!matrix.size1 == .matrix.size1 && $!matrix.size2 == .matrix.size2) {
  my $ret = gsl_matrix_complex_div_elements($!matrix, $b.matrix);
  fail X::Libgsl.new: errno => $ret, error => "Can't div" if $ret ≠ GSL_SUCCESS;
  self
}
method scale(Num(Cool) $x) {
  my $ret = gsl_matrix_complex_scale($!matrix, $x);
  fail X::Libgsl.new: errno => $ret, error => "Can't scale" if $ret ≠ GSL_SUCCESS;
  self
}
method add-constant(Num(Cool) $x) {
  my $ret = gsl_matrix_complex_add_constant($!matrix, $x);
  fail X::Libgsl.new: errno => $ret, error => "Can't add constant" if $ret ≠ GSL_SUCCESS;
  self
}
# Matrix properties
method is-null(--> Bool)   { gsl_matrix_complex_isnull($!matrix)   ?? True !! False }
method is-pos(--> Bool)    { gsl_matrix_complex_ispos($!matrix)    ?? True !! False }
method is-neg(--> Bool)    { gsl_matrix_complex_isneg($!matrix)    ?? True !! False }
method is-nonneg(--> Bool) { gsl_matrix_complex_isnonneg($!matrix) ?? True !! False }
method is-equal(Math::Libgsl::Matrix::Complex64 $b --> Bool) { gsl_matrix_complex_equal($!matrix, $b.matrix) ?? True !! False }

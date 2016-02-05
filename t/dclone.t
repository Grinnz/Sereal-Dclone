use strict;
use warnings;

{package Sereal::Dclone::Clonetest;
  sub new { bless {}, shift }
  sub foo { my $self = shift; return $self->{foo} unless @_; $self->{foo} = shift; $self }
}

{package Sereal::Dclone::Freezetest;
  sub new { bless {}, shift }
  sub foo { my $self = shift; return $self->{foo} unless @_; $self->{foo} = shift; $self }
  sub FREEZE { shift->foo }
  sub THAW { my $self = $_[0]->new; $self->foo($_[2] . 'foo'); $self }
}

use Test::More;
use Sereal::Dclone 'dclone';

is dclone(undef), undef, 'cloned undef';
is dclone('foo'), 'foo', 'cloned string';

my $ref = {foo => ['bar','2.0',\3], bar => undef, baz => qr/foo/i, ban => \{abc => [1,2,3]}};
my $cloned = dclone $ref;
isnt 0+$ref, 0+$cloned, 'different refaddrs';
isnt 0+$ref->{foo}, 0+$cloned->{foo}, 'different refaddrs';

is ref($cloned), 'HASH', 'cloned structure';
is_deeply [sort keys %$cloned], ['ban','bar','baz','foo'], 'right hash keys';
is ref($cloned->{foo}), 'ARRAY', 'cloned ARRAY ref';
is ref($cloned->{foo}[2]), 'SCALAR', 'cloned SCALAR ref';
is ref($cloned->{ban}), 'REF', 'cloned REF ref';
is ref(${$cloned->{ban}}), 'HASH', 'cloned HASH ref';
is ref($cloned->{baz}), 'Regexp', 'cloned Regexp ref';
like 'barFOObaz', $cloned->{baz}, 'regex matches';
is $cloned->{foo}[0], 'bar', 'cloned string';
is $cloned->{foo}[1], '2.0', 'cloned numbery string';
cmp_ok ${$cloned->{foo}[2]}, '==', 3, 'cloned number';
ok !defined($cloned->{bar}), 'cloned undef value';
is_deeply ${$cloned->{ban}}, {abc => [1,2,3]}, 'cloned nested structure';

$ref = {};
$ref->{foo} = $ref;
$cloned = dclone $ref;
isnt 0+$ref, 0+$cloned, 'different refaddrs';
is 0+$cloned, 0+$cloned->{foo}, 'recursive reference cloned';

$ref = {foo => sub {'bar'}};
ok !(eval { $cloned = dclone $ref; 1 }), 'exception cloning structure with coderef';

{
  open my $fh, '>', \my $dummy or die $!;
  $ref = {foo => $fh};
  ok !(eval { $cloned = dclone $ref; 1 }), 'exception cloning structure with globref'
    or diag ref $cloned;
}

my $obj = Sereal::Dclone::Clonetest->new;
$obj->foo('test string');
$ref = {foo => $obj};
ok +(eval { $cloned = dclone $ref; 1 }), 'cloned structure with object' or diag $@;
isnt 0+$ref, 0+$cloned, 'different refaddrs';
isnt 0+$ref->{foo}, 0+$cloned->{foo}, 'different refaddrs';
isa_ok $cloned->{foo}, 'Sereal::Dclone::Clonetest', 'cloned object';
is $cloned->{foo}->foo, $ref->{foo}->foo, 'cloned attribute set';

$obj = Sereal::Dclone::Freezetest->new;
$obj->foo('test string');
$ref = {foo => $obj};
ok +(eval { $cloned = dclone $ref; 1 }), 'cloned structure with object' or diag $@;
isnt 0+$ref, 0+$cloned, 'different refaddrs';
isnt 0+$ref->{foo}, 0+$cloned->{foo}, 'different refaddrs';
isa_ok $cloned->{foo}, 'Sereal::Dclone::Freezetest', 'cloned object';
is $cloned->{foo}->foo, $ref->{foo}->foo . 'foo', 'cloned attribute set';

done_testing;

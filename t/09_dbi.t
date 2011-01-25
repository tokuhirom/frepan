use strict;
use warnings;
use utf8;
use Test::More;
use FrePAN::DBI;

my $d = FrePAN::DBI->connect('dbi:SQLite:');
$d->do(q{create table foo (a primary key, b)});
isa_ok $d->sql_maker, 'SQL::Maker';
my $txn = $d->txn_scope;
isa_ok $txn, 'DBIx::TransactionManager::ScopeGuard';
$txn->rollback;
$d->insert(foo => {a => 1, b => 2});
is_deeply $d->selectall_arrayref(q{SELECT * FROM foo}, {Slice => {}}), [{a => 1, b => 2}];
is_deeply $d->single('foo', {a => 1}), +{ a => 1, b => 2 };
is_deeply $d->search('foo')->fetchall_arrayref({}), [{a => 1, b => 2}];
$d->do_i(q{INSERT INTO foo}, {a => 29, b => 39});
is_deeply $d->search('foo', {}, {order_by => 'a ASC'})->fetchall_arrayref({}), [{a => 1, b => 2}, {a => 29, b => 39}];

subtest 'exception from prepare' => sub {
    eval {
        $d->do_i(q{ERRRR foo}, {a => 24, b => 39});
    };
    note $@;
    unlike $@, qr{at lib/FrePAN/DBI.pm};
    like $@, qr/@{[ __FILE__ ]}/;
};

subtest 'exception from execute' => sub {
    eval {
        $d->do_i(q{INSERT INTO foo}, {a => 29, b => 39});
    };
    note $@;
    unlike $@, qr{at lib/FrePAN/DBI.pm};
    like $@, qr/@{[ __FILE__ ]}/;
};

done_testing;


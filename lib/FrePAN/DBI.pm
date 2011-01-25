use strict;
use warnings;
use utf8;

package FrePAN::DBI;
use parent qw/DBI/;
use SQL::Maker;

sub connect {
    my ($class, @dsn) = @_;
    $dsn[3]->{RaiseError} = 0; # force off the RaiseError
    $dsn[3]->{PrintError} = 0; # force off the PrintError
    my $dbh = $class->SUPER::connect(@dsn);
    return $dbh;
}

package FrePAN::DBI::db;
use parent -norequire, qw/DBI::db/;
use DBIx::TransactionManager;
use SQL::Interp ();
use Try::Tiny;
use Data::Dumper ();
use Carp::Clan qw{^(DBI::|FrePAN::DBI::)};

sub sql_maker { $_[0]->{private_sql_maker} // SQL::Maker->new(driver => $_[0]->{Driver}->{Name}) }

sub txn_manager {
    my $self = shift;
    $self->{private_txn_manager} //= DBIx::TransactionManager->new($self);
}

sub txn_scope { $_[0]->txn_manager->txn_scope }
sub txn_begin { $_[0]->txn_manager->txn_begin }
sub txn_end   { $_[0]->txn_manager->txn_end }

sub do_i {
    my $self = shift;
    my ($sql, @bind) = SQL::Interp::sql_interp(@_);
    my $sth = $self->prepare($sql);
    $sth->execute(@bind);
}

sub insert {
    my ($self, @args) = @_;
    my ($sql, @bind) = $self->sql_maker->insert(@args);
    $self->do($sql, {}, @bind);
}

sub single {
    my ($self, $table, $where, $opt) = @_;
    my ($sql, @bind) = $self->sql_maker->select($table, ['*'], $where, $opt);
    my $sth = $self->_execute($sql, \@bind);
    return $sth->fetchrow_hashref();
}

sub search {
    my ($self, $table, $where, $opt) = @_;
    my ($sql, @bind) = $self->sql_maker->select($table, ['*'], $where, $opt);
    my $sth = $self->_execute($sql, \@bind);
    return $sth;
}

sub prepare {
    my ($self, @args) = @_;
    $self->SUPER::prepare(@args) or do {
        $self->handle_error($_[1], [], $self->errstr);
    };
}

sub _execute {
    my ($self, $sql, $binds) = @_;

    my $sth = $self->prepare($sql);
    $sth->execute(@$binds);
    return $sth;
}

sub handle_error {
    my ( $self, $stmt, $bind, $reason ) = @_;

    $stmt =~ s/\n/\n          /gm;
    my $err = sprintf <<"TRACE", $reason, $stmt, Data::Dumper::Dumper($bind);

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@ FrePAN::DBI 's Exception @@@@@
Reason  : %s
SQL     : %s
BIND    : %s
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
TRACE
    $err =~ s/\n\Z//;
    Carp::Clan::croak $err;
}

package FrePAN::DBI::st;
use parent -norequire, qw/DBI::st/;

sub execute {
    my ($self, @args) = @_;
    $self->SUPER::execute(@args) or do {
        Carp::croak($self->errstr);
    };
}

1;

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

SQL::Maker->load_plugin('InsertMulti');

sub sql_maker { $_[0]->{private_sql_maker} // SQL::Maker->new(driver => $_[0]->{Driver}->{Name}, new_line => q{ }) }

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
    $self->do($sql, {}, @bind);
}

sub insert {
    my ($self, @args) = @_;
    my ($sql, @bind) = $self->sql_maker->insert(@args);
    $self->do($sql, {}, @bind);
}

sub single {
    my ($self, $table, $where, $opt) = @_;
    my $sth = $self->search($table, $where, $opt);
    return $sth->fetchrow_hashref();
}

sub search {
    my ($self, $table, $where, $opt) = @_;
    my ($sql, @bind) = $self->sql_maker->select($table, ['*'], $where, $opt);

    # inject file/line to help tuning
    my ($package, $file, $line);
    my $i = 0;
    while (($package, $file, $line) = caller($i++)) {
        unless ($package eq __PACKAGE__) {
            last;
        }
    }
    $sql =~ s! !/* at $file line $line */ !;

    my $sth = $self->prepare($sql);
    $sth->execute(@bind);
    return $sth;
}

sub prepare {
    my ($self, @args) = @_;
    my $sth = $self->SUPER::prepare(@args) or do {
        FrePAN::DBI::Util::handle_error($_[1], [], $self->errstr);
    };
    $sth->{private_sql} = $_[1];
    return $sth;
}

package FrePAN::DBI::st;
use parent -norequire, qw/DBI::st/;

sub execute {
    my ($self, @args) = @_;
    $self->SUPER::execute(@args) or do {
        FrePAN::DBI::Util::handle_error($self->{private_sql}, \@args, $self->errstr);
    };
}

sub sql { $_[0]->{private_sql} }

package FrePAN::DBI::Util;
use Carp::Clan qw{^(DBI::|FrePAN::DBI::|DBD::)};

sub handle_error {
    my ( $stmt, $bind, $reason ) = @_;

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
    croak $err;
}

1;


package FrePAN::Logger;
use strict;
use warnings;
use Log::Dispatch;
use Plack::Util qw//;
use Data::OptList qw//;

sub new {
    my ($class, $args) = @_;
    my $logger = Log::Dispatch->new();
    my $loggers = delete($args->{loggers}) or die "missing configuration 'loggers' for Logger";
    for my $elem (@{Data::OptList::mkopt($loggers)}) {
        my ($klass, $args) = @$elem;
        $klass = Plack::Util::load_class($klass, 'Log::Dispatch');
        my $obj = $klass->new(%{$args});
        $logger->add($obj);
    }
    return bless {logger=>$logger}, $class;
}

sub log {
    my ($self, $level, $msg) = @_;
    $self->{logger}->log(level => $level, message => "$msg\n");
}

BEGIN {
    no strict 'refs';
    my $pkg = __PACKAGE__;
    for my $meth (qw/debug info notice warning error critical alert emergency/) {
        *{"${pkg}::${meth}"} = sub {
            my ($self, $msg) = @_;
            $self->log($meth, $msg);
        };
    }
};

1;

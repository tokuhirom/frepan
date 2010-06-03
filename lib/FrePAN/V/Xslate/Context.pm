package FrePAN::V::Xslate::Context;
use strict;
use warnings;
use parent 'Exporter';
use Amon::Web::Declare;
use String::CamelCase qw/decamelize/;

sub import {
    my $class = shift;
    my $pkg = caller(0);
    no strict 'refs';
    for my $k (qw/email2gravatar_url uri_with decamelize/) {
        *{"$pkg\::$k"} = *{"$class\::$k"};
    }
    *{"$pkg\::amon_version"} = sub { $Amon::VERSION };

    *{"$pkg\::lc"} = sub { scalar lc($_[0]) };
    *{"$pkg\::uc"} = sub { scalar uc($_[0]) };
    *{"$pkg\::has_item"} = sub { defined $_[0]->{$_[1]} };
}

sub email2gravatar_url {
    model('CPAN')->email2gravatar_url(@_);
}

sub uri_with {
    c()->req->uri_with(@_)
}

1;

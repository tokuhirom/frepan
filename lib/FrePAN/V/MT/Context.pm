package FrePAN::V::MT::Context;
use Amon::V::MT::Context;

sub email2gravatar_url {
    model('CPAN')->email2gravatar_url(@_);
}

1;

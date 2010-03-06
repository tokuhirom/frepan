package FrePAN::Web::C::Webhook;
use Amon::Web::C;

sub friendfeed {
    warn req()->content();
}

1;

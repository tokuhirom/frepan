package FrePAN::DB::Row::File;
use strict;
use warnings;
use utf8;
use parent qw/DBIx::Skinny::Row/;
use Amon2::Declare;
use FrePAN::Util qw/html2text/;
use Log::Minimal;

# @args $text is optional
sub insert_to_fts {
    my ($self, $text) = @_;
    $text ||= html2text($self->html);

    infof("insert into groonga: %d, %s", $self->file_id, $self->package);
    c->fts->insert(file_id => $self->file_id, package => $self->package, description => $self->description, text => $text);
}

1;


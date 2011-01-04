package FrePAN::M::Diff;
use strict;
use warnings;
use utf8;
use Text::Diff ();
use Text::Diff::HTML;
use File::Find::Rule;
use Smart::Args;
use File::Spec;
use FrePAN::CwdSaver;
use Text::Xslate qw/mark_raw/;
use Amon2::Declare;

our ($NEW_AUTHOR, $OLD_AUTHOR);

{
    # a lot of code taken from Text::Diff::HTML.
    package FrePAN::M::Diff::HTML;
    use Text::Diff (); # Just to be safe.
    use parent -norequire, qw(Text::Diff::Unified);
    use HTML::Entities;

    use constant OPCODE    => 2; # "-", " ", "+"
    use constant SEQ_A_IDX => 0;
    use constant SEQ_B_IDX => 1;

    my %code_map = (
        '+' => [ 'ins'              => 'ins' ],
        '-' => [ 'del'              => 'del' ],
        ' ' => [ 'span class="ctx"' => 'span' ]
    );

    sub file_header {
    use Data::Dumper; warn Dumper(@_);
        my ($self, $x, $y, $options) = @_;
     #  $VAR4 = {
     #      'OFFSET_A' => 1,
     #      'MTIME_B'  => 1294109424,
     #      'FILENAME_A' => 'Geo-Coordinates-Converter-0.08/lib/Geo/Coordinates/Converter/Point.pm',
     #      'OFFSET_B' => 1,
     #      'STYLE'    => 'FrePAN::M::Diff::HTML',
     #      'FILENAME_B' => 'Geo-Coordinates-Converter-0.09/lib/Geo/Coordinates/Converter/Point.pm',
     #      'MTIME_A' => 1293821249
     #  };
        return sprintf(
            '<pre class="file"><span class="fileheader"><a class="old" href="%s">--- %s</a><br /><a class="new" href="%s">+++ %s</a></span>',
            encode_entities( "/src/$OLD_AUTHOR/$options->{FILENAME_A}" ),
            encode_entities( $options->{FILENAME_A} ),
            encode_entities( "/src/$NEW_AUTHOR/$options->{FILENAME_B}" ),
            encode_entities( $options->{FILENAME_B} )
        );
    }

    sub hunk_header {
        return '<div class="hunk"><span class="hunkheader">'
            . encode_entities(shift->SUPER::hunk_header(@_))
            . '</span>';
    }

    sub hunk_footer {
        return '<span class="hunkfooter">'
            . encode_entities(shift->SUPER::hunk_footer(@_))
            . '</span></div>';
    }

    sub file_footer {
        return '<span class="filefooter">'
            . encode_entities(shift->SUPER::file_footer(@_))
            . '</span></pre>';
    }

    sub hunk {
        shift;
        my $seqs = [ shift, shift ];
        my $ops  = shift;
        return unless @$ops;

        # Start the span element for the first opcode.
        my $last = $ops->[0][ OPCODE ];
        my $hunk = qq{<$code_map{ $last }->[0]>};

        # Output each line of the hunk.
        while (my $op = shift @$ops) {
            my $opcode = $op->[OPCODE];
            my $elem   = $code_map{ $opcode } or next;

            # Close the last span and start a new one for a new opcode.
            if ($opcode ne $last) {
                $hunk .= "</$code_map{ $last }->[1]><$elem->[0]>";
                $last  = $opcode;
            }

            # Output the appropriate line.
            my $idx = $opcode ne '+' ? SEQ_A_IDX : SEQ_B_IDX;
            $hunk  .= encode_entities("$opcode $seqs->[$idx][$op->[$idx]]");
        }

        return $hunk . "</$code_map{ $last }->[1]>";
    }
}

sub diff {
    args_pos my $class, my $new_dist => { isa => 'FrePAN::DB::Row::Dist'}, my $old_dist => { isa => 'FrePAN::DB::Row::Dist'};

    my $k = c->is_devel ? rand() : 3;
    my $ret = c()->memcached->get_or_set_cb(
        "diff$k:@{[ $new_dist->dist_id ]}:@{[ $old_dist->dist_id ]}" => 24*60*60,
        sub {
            [$class->_diff($new_dist, $old_dist)];
        }
    );
    return wantarray ? @$ret : $ret;
}

sub _diff {
    args_pos my $class, my $new_dist => { isa => 'FrePAN::DB::Row::Dist'}, my $old_dist => { isa => 'FrePAN::DB::Row::Dist'};

    my $new_dir = $new_dist->extracted_dir();
    my $old_dir = $old_dist->extracted_dir();

    my @new_files = $class->files($new_dir);
    my @old_files = $class->files($old_dir);

    my @added;
    my @removed;
    my @diffs;

    # gen @added
    {
        my %old = map { $_ => 1 } @old_files;
        for my $new_file (@new_files) {
            next if $old{$new_file};

            push @added, $new_file;
        }
    }

    # gen @removed
    {
        my %new = map { $_ => 1 } @new_files;
        for my $old_file (@old_files) {
            next if $new{$old_file};

            push @removed, $old_file;
        }
    }

    # gen @diffs
    {
        my %new = map { $_ => 1 } @new_files;
        my $base = $new_dist->author_dir();

        my $guard = FrePAN::CwdSaver->new($base);

        for my $old_file (@old_files) {
            next unless $new{$old_file};

            my $new_name = File::Spec->abs2rel( "$new_dir/$old_file", $base );
            my $old_name = File::Spec->abs2rel( "$old_dir/$old_file", $base ),;
            local $NEW_AUTHOR = $new_dist->author;
            local $OLD_AUTHOR = $old_dist->author;
            my $diff = Text::Diff::diff(
                $old_name, $new_name,
                { STYLE => 'FrePAN::M::Diff::HTML' }
            );
            push @diffs, +{ new_file => $new_name, old_name => $old_name, html => mark_raw($diff) };
        }
    }

    return (\@added, \@removed, \@diffs);
}

sub files {
    args_pos my $class, my $dir;

    File::Find::Rule->new()->file->relative->in($dir);
}

1;


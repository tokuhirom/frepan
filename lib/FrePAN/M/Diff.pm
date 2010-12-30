package FrePAN::M::Diff;
use strict;
use warnings;
use utf8;
use Text::Diff;
use Text::Diff::HTML;
use File::Find::Rule;
use Smart::Args;
use File::Spec;
use FrePAN::CwdSaver;
use Text::Xslate qw/mark_raw/;

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
        return '<pre class="file"><span class="fileheader">'
            . encode_entities(shift->SUPER::file_header(@_))
            . '</span>';
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

            push @added, $old_file;
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


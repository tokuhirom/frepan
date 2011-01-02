package FrePAN::Pod;
use strict;
use warnings;
use utf8;
use Pod::POM;
use Pod::Simple::XHTML;
use Class::Accessor::Lite (
	rw => [qw/pom package description html/],
	ro => [qw/parser/],
);
use Log::Minimal;
use Pod::POM;
use Pod::POM::View::Text;
use FrePAN::Pod::POM::View::Text;

sub new {
	my $class = shift;
	my %args = @_==1 ? %{$_[0]} : @_;
	my $parser = Pod::POM->new();
	return bless { parser => $parser, %args }, $class;
}

sub error { shift->parser->error }

# @return true if succeded, undef if failed to parse.
sub parse_file {
	my ($self, $file) = @_;
	my $pom = $self->parser->parse_file($file) or return undef;

	my ($pkg, $desc);
	my ($name_section) = map { $_->content } grep { $_->title eq 'NAME' } $pom->head1();
	if ($name_section) {
		$name_section = FrePAN::Pod::POM::View::Text->print($name_section);
		$name_section =~ s/\n//g;
		debugf "name: $name_section";
		($pkg, $desc) = ($name_section =~ /^(\S+)\s+-\s*(.+)$/);
		if ($pkg) {
			# workaround for Graph::Centrality::Pagerank
			$pkg =~ s/[CBL]<(.+)>/$1/;
		}
	}
	unless ($pkg) {
		open my $fh, '<:utf8', $file or return;
		SCAN: while (my $line = <$fh>) {
			if ($line =~ /^package\s+([a-zA-Z0-9:_]+)/) {
				$pkg = $1;
				last SCAN;
			}
		}
	}
	unless ($pkg) {
		$pkg = $file;
		if ($pkg =~ /\.pm$/) {
			$pkg =~ s!^lib/!!g;
			$pkg =~ s!/!::!g;
			$pkg =~ s!\.pm$!!g;
		}
	}

	$self->package($pkg);
	$self->description($desc);
	
	{
        my $parser = Pod::Simple::XHTML->new(
            html_header        => '',
            html_footer        => '',
        );
		$parser->perldoc_url_prefix('/perldoc?');
		$parser->output_string(\my $out);
		$parser->parse_file($file);
		$self->html($out);
	}

	return $self;
}

1;
__END__

=head1 NAME

FrePAN::Pod - pod parser


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
    # Note: 'm' option is required for pod/perlfunc.pod
    # perlfunc.pod contains following format:
    #
    #     =head1 NAME
    #     X<function>
    #     
    #     perlfunc - Perl builtin functions
    my ($name_section) = map { $_->content }
      grep { $_->title =~ /^NAME$/m }
      $pom->head1();
    if ($name_section) {
		$name_section = FrePAN::Pod::POM::View::Text->print($name_section);
		$name_section =~ s/\n//g;
		debugf "name: $name_section";
		# some modules contains
		#      "Package::Name -- description here"
		# e.g. http://frepan.64p.org/~vti/Bootylicious-0.910102/bootylicious
		($pkg, $desc) = ($name_section =~ /^(\S+)\s+-+\s*(.+)$/);
		if ($pkg) {
			# workaround for Graph::Centrality::Pagerank
			$pkg =~ s/[CBL]<(.+)>/$1/;
			$pkg =~ s/'(.+)'/$1/;
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
		$pkg =~ s!^\./!!g;
		if ($pkg =~ /\.pm$/) {
			$pkg =~ s!^lib/!!g;
			$pkg =~ s!/!::!g;
			$pkg =~ s!\.pm$!!g;
		}
	}

	$self->package($pkg);
	$self->description($desc);
	
	{
        my $parser = FrePAN::Pod::Parser->new();
        $parser->html_header('');
        $parser->html_footer('');
		$parser->perldoc_url_prefix('/perldoc?');
		$parser->output_string(\my $out);
		$parser->parse_file($file);
		$self->html($out);
	}

	return $self;
}

{
	package FrePAN::Pod::Parser;
	use parent qw/Pod::Simple::XHTML/;
	# for google source code prettifier
	sub start_Verbatim { $_[0]{'scratch'} = '<pre class="prettyprint lang-perl"><code>' }
}

1;
__END__

=head1 NAME

FrePAN::Pod - pod parser


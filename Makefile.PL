use ExtUtils::MakeMaker;

which('cronlog') or do {
	use File::Temp;
	my $tmp = File::Temp->new(UNLINK => 1);
	system "curl -L --output $tmp http://github.com/kazuho/kaztools/tarball/master";
	system "cpanm -nv $tmp";
};

WriteMakefile(
    NAME         => 'FrePAN',
    AUTHOR       => 'tokuhirom <person@example.com>',
    VERSION_FROM => 'lib/FrePAN2.pm',
    PREREQ_PM    => {
        map { $_ => 0 } (
			qw(
				JSON
				LWP::UserAgent
				HTTP::Request
				Data::Dumper
				Text::Xslate
				version
				File::Spec
				File::HomeDir
				Algorithm::Diff
				XML::Feed
				FindBin::libs
				Cache::FileCache
			),
        )
    },
    MIN_PERL_VERSION => '5.008001',
    ( -d 'xt' and $ENV{AUTOMATED_TESTING} || $ENV{RELEASE_TESTING} )
    ? ( test => { TESTS => 't/*.t xt/*.t', }, )
    : (),
);

use File::Spec;
sub which {
	my $basename = shift;
	for $dir (split /:/, $ENV{PATH}) {
		my $path = File::Spec->catfile($dir, $basename);
		return $path if -x $path;
	}
	return;
}


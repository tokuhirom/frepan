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
    VERSION_FROM => 'lib/FrePAN.pm',
    PREREQ_PM    => {
        'Amon2'                           => '2.35',
        'Text::Xslate'                    => '1.1005',
        'Text::Xslate::Bridge::TT2Like'   => '0.00008',
        'Plack::Middleware::ReverseProxy' => '0.09',
        'HTML::FillInForm::Lite'          => '1.09',
        'Time::Piece'                     => '1.20',
        map { $_ => 0 } (
			qw(
			SQL::Maker
			Carp::Clan
			File::Find::Rule
			Getopt::Long::Descriptive
			Web::Query
			CPAN::Mini
			DBD::SQLite
			),
            'HTML::Zoom',
            'AnyEvent::FriendFeed::Realtime',
            'Amon2',
            'JSON::XS',
            'URI',
            'LWP::UserAgent',
            'Archive::Extract',
            'Guard',
            'Path::Class',
            'autodie',
            'Pod::POM',
            'Pod::Simple::XHTML',
            'parent',
            'XML::Feed',
            'Algorithm::Diff',
            'Class::Accessor::Fast',
            'CPAN::DistnameInfo',    # parse path name
            'Archive::Zip',
            'Cache::Memcached::Fast',
            'RPC::XML',
            'Log::Minimal',
            'Smart::Args',
            'Time::Duration',
            'Text::Diff',
            'SQL::Interp',
            'Data::Page',
            'String::CamelCase',
            'HTML::FillInForm::Lite',
            'HTML::FormatText',
            'DBIx::Skinny',
            'Furl',
            'DBIx::Inspector',
            'DBD::mysql',
            'YAML::Tiny',
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


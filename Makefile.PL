use ExtUtils::MakeMaker;

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
            'OAuth::Lite2',
            'HTTP::Session::Store::Memcached',
            'SQL::Interp',
            'Jonk',
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


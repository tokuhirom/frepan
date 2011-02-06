use strict;
use Test::More;
eval q{
    use Test::Perl::Critic 1.02 -exclude => [
        'Subroutines::ProhibitSubroutinePrototypes',
        'Subroutines::ProhibitExplicitReturnUndef',
        'TestingAndDebugging::ProhibitNoStrict',
        'ControlStructures::ProhibitMutatingListFunctions',
    ]
};
plan skip_all => "Test::Perl::Critic is not installed." if $@;
all_critic_ok('lib');

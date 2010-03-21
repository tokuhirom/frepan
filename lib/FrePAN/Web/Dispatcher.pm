package FrePAN::Web::Dispatcher;
use Amon::Web::Dispatcher::RouterSimple -base;
use 5.008001;

connect '/',      {controller => 'Root', action => 'index'};
connect '/about', {controller => 'Root', action => 'about'};
submapper('/~{author}', {}, {on_match => sub { $_[1]->{author} = uc($_[1]->{author}); 1}})
    ->connect('/',                     {controller => 'Author', action => 'show'})
    ->connect('/{dist_ver}/',          {controller => 'Dist', action => 'show'})
    ->connect('/{dist_ver}/{path:.+}', {controller => 'Dist', action => 'show_file'});
connect '/webhook/friendfeed-cpan', {controller => 'Webhook', action => 'friendfeed'};

1;

package FrePAN::Web::Dispatcher;
use Amon2::Web::Dispatcher::RouterSimple;
use 5.008001;

connect '/',      'Root#index';
connect '/about', 'Root#about';
submapper('/~{author}', {}, {on_match => sub { $_[1]->{author} = uc($_[1]->{author}); 1}})
    ->connect('/',                     {controller => 'Author', action => 'show'})
    ->connect('/{dist_ver}/',          {controller => 'Dist', action => 'show'})
    ->connect('/{dist_ver}/{path:.+}', {controller => 'Dist', action => 'show_file'});

1;

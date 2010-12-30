use strict;
use warnings;

package FrePAN::Web::Dispatcher;
use Amon2::Web::Dispatcher::RouterSimple;

connect '/',      'Root#index';
connect '/about', 'Root#about';
submapper('/~{author}', {}, {on_match => sub { $_[1]->{author} = uc($_[1]->{author}); 1}})
    ->connect('/',                     {controller => 'Author', action => 'show'})
    ->connect('/{dist_ver}/',          {controller => 'Dist', action => 'show'})
    ->connect('/{dist_ver}/{path:.+}', {controller => 'Dist', action => 'show_file'});
connect '/search' => 'Search#result';
connect '/perldoc' => 'Perldoc#redirect';

1;

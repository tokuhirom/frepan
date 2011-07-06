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
connect '/perldoc'       => 'Perldoc#redirect';
connect '/other_version' => 'Dist#other_version';
connect '/dist/{dist_name}{p:/?}'=> 'Dist#permalink';
connect '/cpanstats/{dist_vname}'=> 'CPANStats#list';
connect '/admin/regen'=> 'Admin#regen';
connect '/src/*'=> 'Src#show';
connect '/feed/index.rss'=> 'Feed#index';

1;

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
connect '/search'        => 'Search#result';
connect '/perldoc'       => 'Perldoc#redirect';
connect '/other_version' => 'Dist#other_version';
connect '/diff'          => 'Diff#show';
connect '/login'         => 'User#login';
connect '/oauth_callback'         => 'User#oauth_callback';
connect '/logout'         => 'User#logout';
connect '/i_use_this/ranking'=> 'IUseThis#ranking';
connect '/i_use_this/post'=> 'IUseThis#post';
connect '/i_use_this/list'=> 'IUseThis#list';
connect '/user/{user_login}'=> 'User#show';
connect '/user/{user_login}/i_use_this.txt'=> 'User#show_i_use_this_txt';
connect '/dist/{dist_name}'=> 'Dist#permalink';
connect '/cpanstats/{dist_vname}'=> 'CPANStats#list';
connect '/admin/regen'=> 'Admin#regen';
connect '/src/*'=> 'Src#show';

1;

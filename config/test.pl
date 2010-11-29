use Cwd 'abs_path';
+{
    'DB'        => {
        'dsn' => 'dbi:mysql:database=test_FrePAN',
        username => 'test',
        password => '',
        connect_options => +{
            'mysql_enable_utf8' => 1,
            'mysql_read_default_file' => '/etc/mysql/my.cnf',
        },
    },
    'Cache::Memcached::Fast' => {
    },
};

use Cwd 'abs_path';
+{
    'DB'        => [
        'dbi:mysql:database=test_FrePAN',
        'test',
        '',
        +{
            'mysql_enable_utf8' => 1,
            'mysql_read_default_file' => '/etc/mysql/my.cnf',
        },
    ],
    'Cache::Memcached::Fast' => {
    },
};

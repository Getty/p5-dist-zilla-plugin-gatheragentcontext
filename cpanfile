requires 'Dist::Zilla', '6.037';
requires 'Dist::Zilla::File::InMemory';
requires 'Dist::Zilla::Role::FileGatherer';
requires 'Moose';
requires 'Path::Tiny';

on test => sub {
    requires 'Dist::Zilla::Tester';
    requires 'Path::Tiny';
    requires 'Test::More';
};

on develop => sub {
    requires 'Dist::Zilla';
};

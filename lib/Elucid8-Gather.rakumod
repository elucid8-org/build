use v6.d;
use RakuConfig;
use File::Directory::Tree;
use Git::Blame::File;

proto sub MAIN ( |c ) is export {*}

multi sub MAIN (
        Bool :version(:$v)! #= provides the version of the distribution
) {
    say 'Using version ', $?DISTRIBUTION.meta<version>, ' of elucid8-build distribution.' if $v;
    say 'Rakudoc::Processor version: ', RakuDoc::Processor.^ver
}
multi sub MAIN (
        :$config = 'config',      #= localised config file
) {
    my %config;
    if $config.IO ~~ :e & :d {
        %config = get-config(:path( $config ))
    }
    else {
        if $config eq 'config' {
            exit note "Has another config directory been created? \
            If so run ｢{ $*PROGRAM.basename } --config=«installed config directory»｣\
            Or to install run ｢{ $*PROGRAM.basename } --install｣"
        }
        else { exit note "Cannot proceed without directory ｢$config｣. Try runing ｢{ $*PROGRAM.basename } --config=$config --install｣." }
    }
    my %file-data;
    my $file-data-url = "{%config<misc>}/{%config<file-data-name>}";
    %file-data = EVALFILE $file-data-url if $file-data-url.IO ~~ :e & :f;
    my $repo-dir = %config<repository-store>;
    mktree $repo-dir unless $repo-dir.IO ~~ :e & :d;
    my $proc;
    my $repo-full;
    # This assumes git & a default to github. If other, then 'clone-statement' needs to be provided
    # First clone / pull repositories
    for %config<repositories>.kv -> $local-repo-name, %info {
        # if %info<repo-name> is self, then the current repo is meant
        next if $local-repo-name eq 'self';
        $repo-full = "$repo-dir/$local-repo-name";
        if $repo-full.IO ~~ :e & :d {
            say "Pulling $local-repo-name";
            $proc = run <<git -C $repo-full pull>>, :merge;
            exit note ( "Could not 'pull' on $local-repo-name (cloned from {%info<repo-name>}). " ~ $proc.out.slurp(:close) )
                if $proc.exitcode;
        }
        else {
            say "Cloning $local-repo-name";
            my $clone-st = %info<clone-statement> // "git clone -q -- https://github.com/{ %info<repo-name> }.git $repo-full";
            $proc = run $clone-st.split(/' '/), :merge;
            exit note ( "Could not clone $local-repo-name from {%info<repo-name>}. Using:\n$clone-st\nGot error\n", $proc.out.slurp(:close) )
                if $proc.exitcode;
        }
    }
    # Now make available to sources, which should only occur after git operations
    # Linux - sources contains links, Windows TODO (may be empty sources & copy)
    # Respect main 'with-only' list (can be set in config or on command line)
    # Only transfer with format .rakumod
    # Only transfer ones in repo/lang select list, if exists
    # Do not transfer any in repo/lang ignore list, if exists
    # Do not transfer if file-name (link) already exists in source
    my @withs = %config<with-only>.list;
    my Git::Blame::File $blame-info;
    my $to-stem = %config<publication>;
    for %config<repositories>.kv -> $local-repo-name, %repo-info {
        my $repo-stem = "$repo-dir/$local-repo-name";
        $repo-stem = '.' if $local-repo-name eq 'self';
        for %repo-info<languages>.kv -> $lang, %lang-info {
            my %d := %file-data{ $lang };
            my $from-stem = $repo-stem ~ %lang-info<source-entry>;
            my $to = $to-stem ~ '/' ~ $lang ~ '/';
            $to ~= "$_/" with %lang-info<destination>;
            # only transfer selected, if exists
            my @transfers;
            if %lang-info<select>:exists {
                @transfers = %lang-info<select>.list
            }
            else {
                @transfers = $from-stem.IO.dir
            }
            my @ignores = ( %lang-info<ignore> // () ).list;
            # @transfers may contain directories too
            while @transfers {
                my $next = @transfers.shift;
                if $next ~~ :d {
                    @transfers.append: $next.dir;
                    next
                }
                next unless $next.Str.ends-with('.rakudoc');
                if @withs.elems and $next.relative($from-stem).IO.extension('') eq @withs.none {
                    next
                }
                elsif @ignores.elems and $next.relative($from-stem).IO.extension('') eq @ignores.any {
                    next
                }
                else  {
                    my $link-name = $to ~ $next.relative($from-stem);
                    mktree $link-name.IO.dirname;
                    $next.symlink($link-name) unless $link-name.IO ~~ :e;
                    $blame-info .= new($next.Str);
                    %d{$next.Str}<modified> = $blame-info.modified;
                    %d{$next.Str}<home-path> =
                            ( %info<path-edit-prefix> // "htps://github.com/{%repo-info<repo-name>}/edit/main/" )
                            ~ $next.relative($from-stem);
                }
            }
        }
    }
    dictionary-store(%file-data, $file-data-url );
}

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
    my $repo-dir = %config<repository-store>;
    mktree $repo-dir unless $repo-dir.IO ~~ :e & :d;
    my $proc;
    my $repo-full;
    my %repo-data;
    # This assumes git & a default to github. If other, then 'clone-statement' needs to be provided
    # First clone / pull repositories
    for %config<repositories>.kv -> $local-repo-name, %info {
        # if %info<repo-name> is blank, then the current repo is meant
        next unless %info<repo-name>;
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
    # Raku documentation quirk: first level (only) directories need to be lc in
    # rendered variant, but are upper case in repository source
    # Only transfer sources in with-only
    # Only transfer if source has changed
    # Do not transfer any in the ignore field
    # Only transfer with format .rakumod
    my @withs = %config<with-only>.list;
#    my Git::Blame::File $blame-info;
    for %config<repositories>.kv -> $repo-name, %info {
        # if repo-name is blank, then already in sources
        my %d := %repo-data{ $repo-name } = {};
        unless %info<repo-name> {
            for "{ %config<sources> }/%config<canonical>".IO.dir(test => *.ends-with('.rakudoc'))
            {
#                indir %config<repository-store>, { $blame-info .= new( $_ )};
#                %d{$_}<modified> = $blame-info.modified;
                %d{$_}<home-path> = 'https://github.com/Elucid8/Sandpit/edit/main/' ~ $_;
            }
            next
        }
        $repo-full = "$repo-dir/$repo-name/" ~ %info<source-entry>;
        my @ignores = ( %info<ignore> // () ).list;
        my @transfers = $repo-full.IO.dir;
        while @transfers {
            my $next = @transfers.shift;
            if $next ~~ :d {
                @transfers.append: $next.dir
            }
            elsif @ignores.elems and $next.relative($repo-full).IO.extension('') eq @ignores.any {
                next
            }
            elsif $next.Str.ends-with('.rakudoc') {
                my $link-name = $next.relative($repo-full);
                next if @withs.elems and not( $link-name.IO.extension('').Str eq @withs.any );
                $link-name .= subst( / ^ \w /, *.lc ); # really only for Raku documentation
                $link-name = "{%config<sources>}/{%info<destination>}/$link-name";
                mktree $link-name.IO.dirname;
                $next.symlink($link-name) unless $link-name.IO ~~ :e;
#                indir %config<repository-store>, { $blame-info .= new($next.Str) };
#                %d{$next.Str}<modified> = $blame-info.modified;
                %d{$next.Str}<home-path> = ( %info<path-edit-prefix> // 'https://github.com/Raku/doc/edit/main/' )
                    ~ $next.relative($repo-full);
            }
        }
    }
    "{%config<Misc>}/{%config<repo-data-file>}".IO.spurt: %repo-data.raku;
}

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
        :$skip-git = False,       #= skip git pull if offline
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
    my %repo-info;
    my $repo-info-url = "{%config<misc>}/{%config<repository-info-file>}";
    # Is there a need for %repo-info to be accessed by Gather?
#    %repo-info = EVALFILE $repo-info-url if $repo-info-url.IO ~~ :e & :f;
    my $repo-dir = %config<repository-store>;
    mktree $repo-dir unless $repo-dir.IO ~~ :e & :d;
    my $proc;
    my $repo-full;
    unless $skip-git {
        # This assumes git & a default to github. If other, then 'clone-statement' needs to be provided
        # First clone / pull repositories
        for %config<repositories>.kv -> $local-repo-name, %info {
            # if %info<repo-name> is self, then the current repo is meant
            next if $local-repo-name eq 'self';
            $repo-full = "$repo-dir/$local-repo-name";
            if $repo-full.IO ~~ :e & :d {
                say "Pulling $local-repo-name";
                $proc = run <<git -C $repo-full pull>>, :merge;
                exit note ( "Could not 'pull' on $local-repo-name (cloned from { %info<repo-name> }). Try with '--skip-git'." ~ $proc
                .out.slurp(:close))
                if $proc.exitcode;
            }
            else {
                say "Cloning $local-repo-name";
                my $clone-st = %info<clone-statement> //
                "git clone -q -- https://github.com/{ %info<repo-name> }.git $repo-full";
                $proc = run $clone-st.split(/' '/), :merge;
                exit note (
                "Could not clone $local-repo-name from { %info<repo-name> }. Using:\n$clone-st\nGot error\n", $proc.out
                .slurp(:close))
                if $proc.exitcode;
            }
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
    # Add in all the glue files, if withs has elements
    if @withs.elems {
        @withs.append: %config<glues>.keys
    }
    my Git::Blame::File $blame-info;
    my $to-stem = %config<publication>;
    for %config<repositories>.kv -> $local-repo-name, %repo-config {
        my $repo-stem = "$repo-dir/$local-repo-name/";
        $repo-stem = '' if $local-repo-name eq 'self';
        for %repo-config<languages>.kv -> $lang, %lang-info {
            # @transfers may contain directories too
            %repo-info{$lang} = %() unless %repo-info{ $lang }:exists;
            my %update := %repo-info{ $lang }.hash;
            my $rep-entry = %lang-info<source-entry>:exists ?? ( %lang-info<source-entry> ~ '/' )!! '';
            my $from-stem = $repo-stem ~ $rep-entry;
            my $to = "$to-stem/$lang";
            $to ~= "/$_" with %lang-info<destination>;
            # only transfer selected, if exists
            my @transfers;
            if %lang-info<select>:exists {
                @transfers = %lang-info<select>.map({ "$from-stem/$_.rakudoc".IO })
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
                my $short = $next.relative($from-stem).IO.extension('').Str;
                next if @withs.elems and $short eq @withs.none;
                next if @ignores.elems and $short eq @ignores.any;
                # operate on filtered files
                $blame-info .= new($next.Str);
                # in Raku documentation key and short may differ
                my $path = $short;
                if %lang-info<destination-modify>:exists {
                    use MONKEY;
                    $path = EVAL( %lang-info<destination-modify> ).($short);
                    no MONKEY
                }
                %update{$short}{ .key } = .value for %(
                    modified => $blame-info.modified,
                    from-path => $next.relative,
                    to-path => "$to/$path",
                    route => "/$path",
                    repo-name => %repo-config<repo-name>,
                    repo-path => $rep-entry ~ $next.relative($from-stem),
                ).pairs;
            }
        }
    }
    dictionary-store(%repo-info, $repo-info-url );
}

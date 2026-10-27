use Version::Raku;

module Elucid8-Utilities {

    #| given a list of plugin definitions, determine if
    #| 1) they can be used, 2) the version corresponds to the description
    sub verify-plugins(@plugins) is export {
        my %p-versions;
        my $nots;
        my $bads;
        my @installs;
        for @plugins -> $p {
            $p ~~ / (.+?) ':ver<'  (.+)  '>' | (.+) $ /;
            my $p-base = ~$/[0];
            %p-versions{$p-base} = ($/[1] // '*').Str;
            require ::($p-base);
            CATCH {
                %p-versions{$p-base}:delete;
                $nots ~= "$p-base\n\t";
                @installs.push: $p-base;
                next
            }
        }
        for %p-versions.kv -> $p-base, $required-v {
            # so  plugin is installed, verify is high enough
            require ::($p-base);
            my $installed-v = ::($p-base).new.config<version>;
            if  Version::Raku.new($installed-v)."<"(Version::Raku.new($required-v)) {
                $bads ~= "$p-base is ｢$installed-v｣ needs ｢$required-v｣\n\t";
                @installs.push: $p-base;
            }
        }
        return unless $bads or $nots;
        note "Plugin problems detected and will need to be reinstalled";
        note "The following plugins are not yet installed: \n\t$nots" if $nots;
        note "The following plugins are installed but are not up to date: \n\t$bads" if $bads;
        exit note "try: zef install -/precompile-install --force-install . "
    }

    #| given a label, output the label and the time since the last label, and program start
    #| further output is omitted if :quiet flag is set
    sub stage($label, Bool :$quiet = False) is export {
        state $time;
        state $last-label;
        state $keep-quiet = $quiet;
        state $base = INIT now;
        return if $keep-quiet;
        # do not emit any stage information
        my $now = now;
        if $last-label {
            say sprintf('To %s: +%.3f s =  %.3f s', $label, ($now - $time),($now - $base)) ~ "\r";
            $*OUT.flush;
            $time = $now;
            $last-label = $label
        }
        else {
            # happens when stage first called
            $time = $now;
            $last-label = $label;
            say sprintf('Start to %s: %.3f s',$label,($time - $base)) ~ "\r";
            $*OUT.flush;
        }
    }
}
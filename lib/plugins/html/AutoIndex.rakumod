use v6.d;
use RakuDoc::Render;

unit class Elucid8::Plugin::HTML::AutoIndex;

has %.config =
    :name-space<AutoIndex>,
	:version<0.1.0>,
	:license<Artistic-2.0>,
	:credit<finanalyst>,
	:authors<finanalyst>,
    :scss([self.add-scss,1],),
;
method enable( RakuDoc::Processor:D $rdp ) {
    $rdp.add-data( %!config<name-space>, %!config );
    $rdp.add-template( self.templates, :source<AutoIndex plugin>);
}
method templates {
    AutoIndex => -> %prm, $tmpl {
        return q:to/ERROR/ unless $tmpl.globals.data<AutoIndex><meta>:exists;
            <div class="autof-error">No Elucid8 glue files rendered
            </div>
            ERROR
        my $rv;
        my %autof := $tmpl.globals.data<AutoIndex>;
        for %autof<meta>.Slip {
            my $lang = .key;
            my @glues = .value;
            # data is config, title, desc
            $rv = qq:to/FIRST/;
                <div class="autof-container">
                <p class="autof-caption">{ %autof<language-list>{ $lang } } ($lang)</p>
                FIRST
            for  @glues {
                $rv ~= qq:to/NOFL/;
                    <div class="autof-file">
                    <a class="autof-link" href="{.<short>}">{.<title>}\</a>
                    {.<subtitle>}</div>
                NOFL
            }
            $rv ~= '</div>'
        }
        $rv
    }
}

method add-scss {
    q:to/SCSS/;
    .autof-container {
      display: flex;
      flex-direction: column;
      margin-bottom: 1.25rem;
      font-size: 1rem;
      font-weight: 500;
      line-height: 1.5;
      border: 1px solid #cccccc;
      border-bottom: 5px solid #d9d9d9;
      box-shadow: 0 2px 3px 0 rgba(0, 0, 0, 0.07);
      .autof-caption {
          display: flex;
          justify-content: center;
          background: #f2f2f2;
          border-bottom: 1px solid #cccccc;
          color: #83858D;
      }
      .autof-file {
          display: inline-block;
          border-top: 1px solid #cccccc;
          border-bottom: 1px solid #cccccc;
          break-inside: avoid;
          .autof-link {
              display: inline-block;
              width: 100%;
              text-align: center;
              padding-top: 0.25rem;
          }
          p {
              padding-left: 0.5rem;
              padding-right: 0.5rem;
              margin-bottom: 0.25rem;
          }
      }
    }
    .autof-error {
      color: red;
      font-size: xlarge;
    }
    SCSS
}
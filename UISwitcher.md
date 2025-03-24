
# Plugin to switch UI language

	How navigation language switching works

----

## Table of Contents

<a href="#Introduction">Introduction</a>   


<div id="Introduction"></div>

## Introduction
<span class="para" id="79857c5"></span>This is a plugin for the Elucid8 framework and is intended to be called from the Elucid8-build component. 

<span class="para" id="90d0fcb"></span>All Elucid8 plugins that provide templates which have user facing text should replace any such user-facing that text with a `ui-token`. These tokens are replaced in the browser by a JS script from a dictionary that is itself generated at render time from the `ui-tokens`. 

<span class="para" id="4f14ad4"></span>At install time, the dictionary is created from the `ui-tokens` in each plugin, then stored in the `Misc` directory. 

<span class="para" id="0e95a1a"></span>The dictionary is then added to by translating the keys in the canonical language. 

<span class="para" id="58a993c"></span>Since the UI language is independent of the content languages, the canonical language only has meaning when defining User Interface template. By default the canonical lanugage for the `ui-tokens` is `en`. It is important to add the key `langName`. 

<span class="para" id="8ed2c51"></span>A long example is: 


```
    {
        ｢en｣ => {
            ｢langName｣    => "English",
            ｢UI_Switch｣   => "Switch UI",
            ｢Time｣        => "eval\{ sprintf( \"Rendered at \%02d:\%02d UTC on \%s\", .hour, .minute, .yyyy-mm-dd) with now.DateTime }",
            ｢Index｣       => "Index",
            ｢NoIndex｣     => "No Index for this page",
            ｢TOC｣         => "Table of Contents",
            ｢NoTOC｣       => "No Table of contents for this page",
            ｢ChangeTheme｣ => "Change Theme"
        },
        ｢fr｣ => {
            ｢langName｣    => "Français",
            ｢UI_Switch｣   => "Changer d'IU",
            ｢Time｣        => "eval\{ sprintf( \"Rendu à\%02d:\%02d UTC à \%s\", .hour, .minute, .yyyy-mm-dd) with now.DateTime }",
            ｢Index｣       => "Index",
            ｢NoIndex｣     => "Aucun index pour cette page",
            ｢TOC｣         => "Table des matières",
            ｢NoTOC｣       => "Aucune table des matières pour cette page",
            ｢ChangeTheme｣ => "Changer de thème"
        },
        ｢ua｣ => {
            ｢langName｣    => "Українська",
            ｢UI_Switch｣   => "Інтерфейс користувача",
            ｢Time｣        => "eval\{ sprintf( \"Виведено о \%02d:\%02d UTC на \%s\", .hour, .minute, .yyyy-mm-dd) with now.DateTime }",
            ｢Index｣       => "Індекс",
            ｢NoIndex｣     => "Немає індексу для цієї сторінки",
            ｢TOC｣         => "Зміст",
            ｢NoTOC｣       => "Немає змісту цієї сторінки",
            ｢ChangeTheme｣ => "Змінити тему"
        },
        ｢nl｣ => {
            ｢langName｣    => "Nederlands",
            ｢UI_Switch｣   => "Switch UI",
            ｢Time｣        => "eval\{ sprintf( \"Gerenderd at \%02d:\%02d UTC on \%s\", .hour, .minute, .yyyy-mm-dd) with now.DateTime }",
            ｢Index｣       => "Index",
            ｢NoIndex｣     => "Geen index voor deze pagina",
            ｢TOC｣         => "Inhoudsopgave",
            ｢NoTOC｣       => "Geen inhoudsopgave voor deze pagina",
            ｢ChangeTheme｣ => "Thema wijzigen"
        },
    }
```
<span class="para" id="e194b64"></span>A `ui-token` is a unique string of unicode chars. In a template the place where a ui-token is to be placed is shown as a `span` tag with class `Elucid8-ui`, an attribute `data-UIToken` and the content of the tag is the ui-token, eg., 


```
    <span class="Elucid8-ui" data-UIToken="Some_UIToken">Some_UIToken</span>
```
<span class="para" id="8002198"></span>This gives the span a default content. 

<span class="para" id="a1ccd73"></span>A plugin with templates containing *ui-tokens* must provide a field in the `config` section of the form: 


```
    ui-tokens: %(
        token-1 => expansion in canonical language,
        token-2 => expansion2
        )
```
<span class="para" id="ed68051"></span>An expansion may be 



&nbsp;&nbsp;• A string  
&nbsp;&nbsp;• A Raku closure, which is evaluated when the file is rendered. It may contain variables that known at run time. The primary use is for time and date information. Data available about a file can only be used on a per-file basis.  
<span class="para" id="edd17b2"></span>After all the *Elucid8* plugins have been enabled, and hence all the templates with UI content are attached to the RakuDoc-processor (rdp) object, the closure in the UISwitcher's dataspace key `gather-ui-tokens` is run with the rdp and the config as the parameters. 

<span class="para" id="f798ce6"></span>A dictionary is created which is placed in a JS file that is added to each website page. The JS file is responsible for setting the UI content, getting a signal to change the content, and changing content. 

<span class="para" id="7c0c055"></span>The dictionary is created in the following steps:

1. <span class="para" id="3b2f84a"></span>the `ui-tokens` and their canonical values are collected from each plugin  

2. <span class="para" id="c43ac1d"></span>The **__Misc__** directory is checked for the existence of a file called **dictionary.rakuon**.  

2.1. If the dictionary file exists, then the dictionary object is created from the file  

2.2. If the dictionary file does not exist, then a blank dictionary object.  

3. All the collected keys are compared with the keys of the dictionary object  

4. If there are new keys, they are added to the dictionary object.  

5. If the dictionary object has been changed by the addition of new keys, then a new dictionary file is written.  





----

----

Rendered from docs/UISwitcher.rakudoc/UISwitcher at 20:19 UTC on 2025-03-24

Source last modified at 09:24 UTC on 2025-03-16


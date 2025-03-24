
# Build and Gather

	The two main processes in the Elucid8 framework

----

## Table of Contents

<a href="#Overview">Overview</a>   
<a href="#Relation_between_repository-info-file_and_file-data-name">Relation between repository-info-file and file-data-name</a>   
<a href="#License">License</a>   
<a href="#Credits">Credits</a>   


<div id="Overview"></div>

## Overview
<span class="para" id="a5d3b87"></span>In general, RakuDoc sources are held in git repositories. 

<span class="para" id="1145b01"></span>However, if the *sources*<a id="Using_the_config_file_it_is_possible_to_rename_nearly_every_directory_and_file_name,_so_the_key_name_in_the_config_file_is_used_here." href="#fn_target_Using_the_config_file_it_is_possible_to_rename_nearly_every_directory_and_file_name,_so_the_key_name_in_the_config_file_is_used_here."><sup>[ 1 ]</sup></a> already contains all the sources, and no sources are kept in repositories, then the `gather-sources` utility need not be used. 

<span class="para" id="dc19fff"></span>The following steps are then followed for each build sequence: 



1. <span class="para" id="aadfa8a"></span>The `gather-sources` utility is used to:  



&nbsp;&nbsp;&nbsp;&nbsp;▹ <span class="para" id="fc50e1f"></span>clone the RakuDoc sources in the website build are under the `repository-store` directory using `gather-sources`.  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;‣ <span class="para" id="28aeb27"></span>Each repository is specified in the *04.repositories* config file.  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;‣ A repository may contain files for multiple languages.  
&nbsp;&nbsp;&nbsp;&nbsp;▹ <span class="para" id="f3c4f2d"></span>create entries in `repo-info` hash to the desired *.rakudoc* files.  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;‣ <span class="para" id="8861867"></span>Files may be selected on a global basis by setting the [with-only](With only filter).  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;‣ <span class="para" id="0617e58"></span>Files may be filtered out at the language/repo using `ignore`, files not listed in *ignore* have entries created.  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;‣ <span class="para" id="0d34539"></span>Files may be selected at the language/repo using `select`, no other files are let through.  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;‣ <span class="para" id="0542ac4"></span>*ignore* is applied after *select*, so files in both *select* and *ignore* will be ignored.  
&nbsp;&nbsp;&nbsp;&nbsp;▹ <span class="para" id="b917e9d"></span>generate from `repo-info` a file called `repository-info-file`, which is stored in `misc`.  


1. <span class="para" id="1b2639c"></span>The `elucid8-build` utility is then called to:  



&nbsp;&nbsp;&nbsp;&nbsp;▹ <span class="para" id="70b5bd8"></span>update the `file-data-name` file.  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;‣ <span class="para" id="be074f1"></span>If the *repository-info-file* file exists, it is the basis for *file-data-name*.  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;‣ <span class="para" id="0088f83"></span>If the *repository-info-file* file does not exist, *file-data-name* is built from the files in the *sources* directory.  
&nbsp;&nbsp;&nbsp;&nbsp;▹ <span class="para" id="691df6f"></span>render the files in the *sources* directory into the `publication` directory  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;‣ Existing rendered files are updated if  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;⁃ the rendered date is older than the last modification date of the source  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;⁃ <span class="para" id="1f53669"></span>the force `-f` flag is set  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;‣ <span class="para" id="d6bd925"></span>if a *:with-only* list is present in the config file, or *elucid8-build* is called with a *--with-only* argument on the CLI, then only those sources are rendered  
<span class="para" id="7d70087"></span>The build process may be controlled using the following options with *elucid8-build*: 



&nbsp;&nbsp;• <span class="para" id="347b29e"></span>`--regenerate-from-scratch` = delete the *publication* directory and the *file-data-name* file.  
&nbsp;&nbsp;• <span class="para" id="a6afa68"></span>`--with-only`&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; = only operate on these files (others in *publication* directory will be untouched).  
&nbsp;&nbsp;• <span class="para" id="5b0bd13"></span>`--f`&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; = ignore the modified attribute.  
&nbsp;&nbsp;• <span class="para" id="d92bff4"></span>`-v`&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;= get the versions of the *Elucid8-build* and *Rakuast-RakuDoc-Render* distributions.  

<div id="Relation between repository-info-file and file-data-name"></div><div id="Relation_between_repository-info-file_and_file-data-name"></div>

## Relation between repository-info-file and file-data-name
<span class="para" id="18972af"></span>The `repository-info-file` is generated by *gather-sources* and contains information that can be obtained from the repositories and the config. 

<span class="para" id="746549a"></span>`file-data-name` file can be generated from the files in `sources` or from `repository-info-file`. 

<span class="para" id="988a17c"></span>Either there are files in sources, and `repository-info-file` is absent, or vice versa. 

<span class="para" id="bf24e42"></span>However, `file-data-name` contains information about the rendered files as well. 

<span class="para" id="01d0dc4"></span>When `gather-sources` is run, it updates the local repositories, and stores the modified attribute for each file. So, `elucid8-build` needs to update `file-data-name`. 

<div id="License"></div>

## License
Artistic-2.0



<div id="Credits"></div>

## Credits
Richard Hainsworth



----

## Footnotes
1<a id=".<fnTarget>" href="#Using_the_config_file_it_is_possible_to_rename_nearly_every_directory_and_file_name,_so_the_key_name_in_the_config_file_is_used_here."> |^| </a>Using the `config` file it is possible to rename nearly every directory and file name, so the key name in the config file is used here.



----

----

Rendered from docs/Build-Gather.rakudoc/Build-Gather at 20:19 UTC on 2025-03-24

Source last modified at 21:57 UTC on 2025-03-23


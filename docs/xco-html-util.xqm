(:
 : xco-html - utility functions supporting the creation of HTML reports
 :)
module namespace hu="http://www.parsqube.de/ns/xco/html-util";

declare namespace z="http://www.parsqube.de/ns/xco/structure";
declare boundary-space preserve;

(:~
 : Returns the standard colgroup element defining 6 columns.
 :)
declare function hu:standardColGroup6() as element(colgroup) {
    <colgroup span="1">
        <col span="1" style="width:11.9047619047619%"/>
        <col span="1" style="width:1.19047619047619%"/>
        <col span="1" style="width:11.9047619047619%"/>
        <col span="1" style="width:1.19047619047619%"/>
        <col span="1" style="width:23.8095238095238%"/>
        <col span="1" style="width:35.7142857142857%"/>
    </colgroup>            
};

declare function hu:classTable() as attribute(class) {
    'tableblock frame-all grid-all spread' ! attribute class {.}
};

declare function hu:classTd() as attribute(class) {
    'tableblock halign-left valign-top' ! attribute class {.}
};

declare function hu:classTd($addClasses as xs:string?) as attribute(class) {
    string-join(('tableblock halign-left valign-top', $addClasses), ' ') 
    ! attribute class {.}
};

declare function hu:classP() as attribute(class) {
    'tableblock' ! attribute class {.}
};

declare function hu:classP($addClasses as xs:string?) as attribute(class) {
    string-join(('tableblock', $addClasses), ' ') ! attribute class {.}
};

(: Returns a table text line. The text can be provided as a string 
 : or as a sequence of nodes and/or strings.
 :)
declare function hu:tableTextLine($items as item()*)
        as element(tr) {
    hu:tableTextLine($items, (), ())        
};        

(:~
 : Returns a td element containing text rendered as code.
 :)
declare function hu:tdWithCode($code as xs:string, 
                               $colspan as xs:integer, 
                               $rowspan as xs:integer)
        as element(td) {
    <td colspan="{$colspan}" rowspan="{$rowspan}">{        
        hu:classTd(),
        <p>{
            hu:classP(),
            <code>{$code}</code>
        }</p>
    }</td>
};

(:~
 : Returns a td element containing text rendered as code.
 :)
declare function hu:tdWithContent(
                               $content as item()*, 
                               $colspan as xs:integer, 
                               $rowspan as xs:integer)
        as element(td) {
    hu:tdWithContent($content, $colspan, $rowspan, ())        
};

(:~
 : Returns a td element containing text rendered as code.
 :)
declare function hu:tdWithContent(
                               $content as item()*, 
                               $colspan as xs:integer, 
                               $rowspan as xs:integer,
                               $addClasses as xs:string?)
        as element(td) {
    <td colspan="{$colspan}" rowspan="{$rowspan}">{        
        hu:classTd(),
        <p>{
            hu:classP($addClasses),
            $content
        }</p>
    }</td>
};

(: Returns a table text line. The text can be provided as a string 
 : or as a sequence of nodes and/or strings.
 :)
declare function hu:tableTextLine($items as item()*, 
                                  $addClassesTd as xs:string?,
                                  $addClassesP as xs:string?)
        as element(tr) {
    let $nodes := $items ! (if (. instance of node()) then . else text {.}) return         
    <tr>{
        <td colspan="6" rowspan="1">{
            hu:classTd($addClassesTd),
            <p>{
                hu:classP($addClassesP),
                $nodes
            }</p>
        }</td>
    }</tr>
};   

(:~
 : Returns a multiline HTML representation of a local type label.
 :)
declare function hu:getLocalTypeLabelLines($typeLabel as xs:string)
        as element()* {
    let $id := replace($typeLabel, '.*(\(.*)', '$1')        
    let $locator := replace($typeLabel, '(.*\]).*', '$1')
    let $steps := substring($typeLabel, 1 + string-length($locator)) ! replace(., '\s*\(.*', '')
                  [string()]
                  ! replace(., '(\S)#', '$1&#160;#')
    return (
            <code>{$locator}</code>, <br/>,
            $steps ! (<code>{'&#160;&#160;'||.}</code>, <br/>),
            <code>{'&#160;&#160;'||$id}</code>
    )
};



(:
 : xco-debug - functions providing debug functionality
 :)
module namespace dg="http://www.parsqube.de/ns/xco/debug";

import module namespace u="http://www.parsqube.de/ns/xco/util"
at "xco-util.xqm";

declare namespace z="http://www.parsqube.de/ns/xco/structure";

declare variable $dg:DIR_DEBUG := '/projects/sbb/work';

(:~
 : Inserts into the options map a 'debug' entry, which is a map
 : containing two keys:
 : 'dir' - the output folder into which debug files are written
 : 'filter' - a map associating debug ids with filter strings
 :
 : The 'debug' entry is evaluated by function db:WRITE_FILE. The
 : entry controls where and if a file is written.
 :
 : Example: 
 :    debugFilter: 5=PriceType, 7, 8=OrderElem
 :    debugDir: /projects/tmp
 :
 : 'debug' entry of options:
 :   debug:
 :       dir: /projects/tmp
 :       filter:
 :           5: 'PriceType'
 :           7: '*'
 :           8: 'OrderElem
 :)
declare function dg:SET_DEBUG_OPTIONS($debugDir as xs:string?,
                                      $debugFilter as xs:string?,
                                      $options as map(xs:string, item()*))
        as map(xs:string, item()*) {
    if (not($debugFilter) and not($debugFilter)) then $options else
    
    let $filterItems := $debugFilter ! tokenize(., ',\s*')
    let $filterMap := map:merge(
        for $item in $filterItems
        return
            if (not(contains($item, '='))) then map:entry($item, '*')
            else
                let $id := replace($item, '\s*=.*', '')
                let $cond := replace($item, '^.*?=\s*', '')
                return map:entry($id, $cond))
    let $outputDir := ($debugDir, '.')[1]   
    let $debugMap := map{'dir': $outputDir, 'filter': $filterMap}
    (: let $_DEBUG := trace($debugMap, '___DEBUG_MAP: ') :)
    return map:put($options, 'debug', $debugMap)                
};

declare function dg:WRITE_FILE($item as item()*,
                               $fname as xs:string,
                               $debugId as xs:string,
                               $debugCond as xs:string?,
                               $options as map(xs:string, item()*))
        as empty-sequence() {
    if (empty($item) or empty($options?debug)) then () else        
    let $debugPass := $options?debug?filter($debugId)
    return
        if (not($debugPass = ('*', $debugCond))) then () else

        let $debugDir := ($options?debug?dir, '.')[1]
        let $path := $debugDir||'/'||$fname
        return
            if ($item[1] instance of node()) then
                file:write($path, $item ! u:prettyNode(.), map{'indent': 'yes'})
            else file:write($path, string-join($item, '&#xA;'))
};

declare function dg:writeNode($fname as xs:string, 
                              $node as node(),
                              $options as map(xs:string, item()*)) 
        as empty-sequence() {
    let $path := $dg:DIR_DEBUG||'/'||$fname
    return
        file:write($path, $node, $options)
};

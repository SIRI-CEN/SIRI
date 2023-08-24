(:
 : xco-file-util.xqm - utility functions dealing with the file system
 :)
module namespace fu="http://www.parsqube.de/ns/xco/file-util";

import module namespace u="http://www.parsqube.de/ns/xco/util"
    at "xco-util.xqm";
    
declare namespace z="http://www.parsqube.de/ns/xco/structure";

(:
 :
 :    P u b l i c    f u n c t i o n s
 :
 :)

(:~
 : Applies a relative path to a context path. A relative context path is  
 : resolved against the current working directory. The result is an
 : absolute path.
 :
 : @param contextPath the relative path starts at this location
 : @param relPath a relative path
 : @return a relative path
 :)
declare function fu:applyRelPath($contextPath as xs:string, $relPath as xs:string)
        as xs:string {
    let $cpath := $contextPath ! u:normalizeUri(., ())
    return 
        if ($relPath = ('', '.')) then $cpath else 
            fu:applyRelPathREC($cpath, tokenize($relPath, '/')) 
};

(:~
 : Returns the parent path of a given path.
 :
 : @param path a path
 : @return the parent path
 :)
declare function fu:getParentPath($path as xs:string)
        as xs:string {
    if (not($path)) then '..'
    else $path ! u:normalizeUri(., ()) ! replace(., '/[^/]*$', '')
};

(:~
 : Returns the parent path of a given path. If the path is a
 : relative path, the returned path is also relative.
 :
 : @param path a path
 : @return the parent path
 :)
declare function fu:getRelParentPath($path as xs:string)
        as xs:string {
    if (not($path)) then '..'
    else if (not(contains($path, '/'))) then ''
    else $path ! replace(., '/[^/]*$', '')
};

(:~
 : Returns the relative path leading from a context path to a target location.
 : A relative context path or target location is resolved against the current
 : working directory.
 :
 : @param contextPath the relative path starts at this location
 : @param targetPath the relative path leads to this location
 : @return a relative path
 :)
declare function fu:getRelPath($contextPath as xs:string, $targetPath as xs:string)
        as xs:string {
    let $cpath := $contextPath ! u:normalizeUri(., ())        
    let $tpath := $targetPath ! u:normalizeUri(., ())         
    return 
        if ($cpath eq $tpath) then '' else fu:getRelPathREC($cpath, $tpath, ())
};

(:~
 : Applies the relative path leading from a context path to a target location to
 : a different context path.
 :)
declare function fu:shiftRelPath($contextPath as xs:string, 
                                 $targetPath as xs:string, 
                                 $newContextPath as xs:string*)
        as xs:string {
    fu:getRelPath($contextPath, $targetPath) ! fu:applyRelPath($newContextPath, .)        
};

(:~
 : Returns the file name extension.
 :)
declare function fu:getFileExtension($path as xs:string)
        as xs:string? {
    let $fname := file:name($path)        
    return $fname !  replace($path, '.*(\.[^.]+$)', '$1')[not(. eq $fname)]
};

(:~ 
 : Removes the file name extension.
 :)
declare function fu:removeFileExtension($path as xs:string)
        as xs:string {
    let $fext := fu:getFileExtension($path)
    return substring($path, 1, string-length($path) - string-length($fext))
};

(:~
 : Inserts a label string immediately before the file name extension.
 : The label is inserted before the dot.
 :)
declare function fu:insertLabelBeforeFileNameExtension($path as xs:string, 
                                                       $label as xs:string)
        as xs:string {
    let $fext := fu:getFileExtension($path)        
    let $suffix := $label||$fext
    return fu:removeFileExtension($path)||$suffix
};        

(:~ 
 : Replaces the file name extension with a different extension.
 :)
declare function fu:changeFileNameExtension($path as xs:string, 
                                            $newExtension as xs:string)
        as xs:string {
    fu:removeFileExtension($path)||'.'||$newExtension
};        

(:~
 : Copies the standard css file into the report folder, if appropriate.
 :)
declare function fu:copyCssFile($options as map(xs:string, item()*))
        as empty-sequence() {
    let $odir := $options?odir
    return if (not($odir)) then () else
    
    let $reportType := $options?reportType
    return
        if ($reportType ne 'contab') then () else
        
    let $fname := 'asciidoc.css'
    let $fpathTarget := $odir||'/'||$fname
    return
        if (file:exists($fpathTarget)) then () 
        else
            let $sourceDir := static-base-uri() ! fu:getParentPath(.)
            let $fpathSource := $sourceDir||'/'||$fname            
            return file:copy($fpathSource, $fpathTarget)
};

(:
 :    f t r e e    c o n s t r u c t o r
 :
 :)
(:~
 : Maps a sequence of file paths to a tree representation of folders
 : and files (<fo> and <fi> elements).
 :
 : @param filePaths a sequence of file paths
 : @param context context folder
 : @return a tree of <fo> and <fi> elements
 :)
declare function fu:ftree($filePaths as xs:string*, $context as xs:string?)
        as element(fo) {
    let $paths := $filePaths ! replace(., '^'||$context||'/', '') 
                  => sort((), lower-case#1)
    return <fo context="{$context}">{fu:ftreeREC($paths)}</fo>        
};

declare function fu:ftreeREC($paths as xs:string*)
        as element()* {
    let $files := $paths[not(contains(., '/'))]
    let $folders := $paths[not(. = $files)]
    let $folderTrees :=
        for $fo in $folders
        let $step1 := replace($fo, '/.*', '')
        group by $step1
        return
            <fo name="{$step1}">{
                $fo ! replace(., '^'||$step1||'/', '') => fu:ftreeREC()  
            }</fo>
    return (
        $folderTrees,
        $files ! <fi name="{.}"/>
    )
};
 
(:
 :
 :    P r i v a t e    f u n c t i o n s
 :
 :)

(:~
 : Recursive helper function of `getRelPath`.
 :)
declare %private function fu:getRelPathREC($contextPath as xs:string, 
                                           $targetPath as xs:string, 
                                           $prefix as xs:string*)
        as xs:string {
    let $suffix := replace($targetPath, '^'||$contextPath||'/', '')
        [. ne $targetPath]
    return
        if ($suffix) then string-join(($prefix, $suffix), '/') 
        else 
            fu:getRelPathREC($contextPath ! fu:getParentPath(.), $targetPath, 
                ($prefix, '..'))
};

(:~
 : Recursive helper function of `applyRelPath`.
 :)
declare function fu:applyRelPathREC($contextPath as xs:string, $pathSteps as xs:string*)
        as xs:string {
    let $step := head($pathSteps)
    let $tail := tail($pathSteps)
    let $newContextPath :=
        if ($step eq '..') then $contextPath ! fu:getParentPath(.)
        else $contextPath||'/'||$step
    return 
        if (empty($tail)) then $newContextPath 
        else fu:applyRelPathREC($newContextPath, $tail)
};


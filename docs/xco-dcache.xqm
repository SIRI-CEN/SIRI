(:
 : xco-dcache - functions reading and updating the descriptor cache
 :)
module namespace dc="http://www.parsqube.de/ns/xco/dcache";

import module namespace dg="http://www.parsqube.de/ns/xco/debug"
  at "xco-debug.xqm";
import module namespace ns="http://www.parsqube.de/ns/xco/namespace"
  at "xco-namespace.xqm";

(:
import module namespace rd="http://www.parsqube.de/ns/xco/rdesc"
  at "xco-rdesc.xqm";
import module namespace cd="http://www.parsqube.de/ns/xco/desc"
  at "xco-desc.xqm";
import module namespace cn="http://www.parsqube.de/ns/xco/comp-names"
  at "xco-comp-names.xqm";
import module namespace co="http://www.parsqube.de/ns/xco/constants"
  at "xco-constants.xqm";
import module namespace eu="http://www.parsqube.de/ns/xco/edesc-util"
  at "xco-edesc-util.xqm";
import module namespace sd="http://www.parsqube.de/ns/xco/simple-type-description"
  at "xco-stype-description.xqm";
:)

declare namespace z="http://www.parsqube.de/ns/xco/structure";

(:~
 : Returns an expanded component descriptor retrieved from the dcache.
 :
 : @param a schema component
 : @return the expanded component descriptor, or the empty sequence
 :)
declare function dc:edescForComp($comp as element(), 
                                 $options as map(xs:string, item()*))
        as element()? {
    let $edesc := $options?dcache?edesc?($comp/local-name())?(ns:componentQName($comp))    
    (:
    let $_DEBUG := if (not($edesc)) then () 
        else trace('_DCACHE: EDESC FOUND; KIND='||$comp/local-name()||', NAME='||$edesc/@z:name)
     :)      
    return $edesc        
};

(:~
 : Returns an expanded component descriptor retrieved from the dcache.
 :
 : @param a schema component
 : @return the expanded component descriptor, or the empty sequence
 :)
declare function dc:edescForQName($qname as xs:QName,
                                  $kind as xs:string,
                                  $options as map(xs:string, item()*))
        as element()? {
    let $edesc := 
        if ($kind eq 'type') then
            let $edescStype := $options?dcache?edesc?simpleType?($qname)
            return
                if ($edescStype) then $edescStype
                else $options?dcache?edesc?complexType?($qname)
        else $options?dcache?edesc?($kind)?($qname) 
    (:        
    let $_DEBUG := if (not($edesc)) then () 
        else trace('_DCACHE: EDESC FOUND; KIND='||$kind||', NAME='||$edesc/@z:name)
     :)
    return $edesc        
};

declare function dc:storeEdesc($edesc as element(), 
                               $options as map(xs:string, item()*))
        as map(xs:string, item()*) {
    let $qname := $edesc/@z:name/resolve-QName(., ..)
    let $kind := $edesc/local-name()
    return if ($options?dcache?edesc?($kind)?($qname)) then $options else
    
    let $countEdescs0 := $options?dcache?edesc?($kind) ! map:keys(.) => count()
    let $dcache := ($options?dcache, map{})[1]
    let $edescCache := ($dcache?edesc, map{})[1]
    let $kindCache := ($edescCache?($kind), map{})[1]
    let $kindCacheUpd := map:put($kindCache, $qname, $edesc)
    let $edescCacheUpd := map:put($edescCache, $kind, $kindCacheUpd)
    let $dcacheUpd := map:put($dcache, 'edesc', $edescCacheUpd)
    let $optionsNew := map:put($options, 'dcache', $dcacheUpd)
    let $countEdescs := $optionsNew?dcache?edesc?($kind) ! map:keys(.) => count()
    (:
    let $_DEBUG := trace('_DCACHE: EDESC STORED; '||
        'KIND='||$kind||', QNAME='||$qname||'; COUNT: '||$countEdescs0||'->'||$countEdescs)
     :)
    return $optionsNew
};        
module namespace sr="http://www.parsqube.de/ns/xco/schema-resolver";

import module namespace u="http://www.parsqube.de/ns/xco/util"
at "xco-util.xqm";

(:~
 : Returns a schema along with all other schemas obtained by
 : recursively resolveing all includes and imports. 
 : @param global only top-level element declarations are considered 
 : @return schema components matching the component type specific name filter 
 :)
declare function sr:resolveSchemas($uris as xs:string+)
        as element(xs:schema)* {
    (: sr:resolveSchemas_($uri, (), ()) :)    
    let $uris2 := $uris ! u:normalizeUri(., ())
    let $_LOG := trace('Resolve schema imports / inclusions') 
    let $schemas := sr:resolveSchemas_($uris2 => head(), $uris2 => tail(), ())
    let $_LOG := trace('Resolving finished')
    return    
        $schemas
};

declare function sr:resolveSchemas_($uri as xs:string, 
                                    $furtherUris as xs:string*,
                                    $visited as xs:string*)
        as item()* {
    if (not(file:exists($uri))) then error((), 'Cannot find schema at this URI: '||$uri) else
    
    let $node := doc($uri)[not($uri = $visited)]/*  
    let $bu := $node/base-uri(.) ! u:normalizeUri(., ())
    let $newVisited := ($visited, $bu)
    let $furtherUris2 := 
        $node/(xs:include, xs:import)/@schemaLocation/u:normalizeUri(., $bu)
        ! sr:editSchemaLocation(.)
        [not(. = $furtherUris)]
    let $newFU := ($furtherUris, $furtherUris2)
    return (
        $node,
        sr:resolveSchemas_(head($newFU), tail($newFU), $newVisited)[exists($newFU)]
    )            
};

declare function sr:editSchemaLocation($schemaLocation) {
    if (file:exists($schemaLocation)) then $schemaLocation else
    let $_DEBUG := trace($schemaLocation, '*** Imported/included schema not found:      ') 
    let $try := $schemaLocation
                ! replace(., '/siri/siri_model/', '/siri/xsd/siri_model/', 'i')
                ! replace(., '/xsd/wsdl/siri/', '/xsd/siri/', 'i')
                ! replace(., '/xsd/wsdl/siri_utility/', '/xsd/siri_utility/', 'i')
                ! replace(., '/xsd/wsdl/netex_service/', '/xsd/netex_service/', 'i')
                ! replace(., 'siriSg.xsd', 'NeTEx_siri_SG.xsd', 'i')
                ! replace(., '(/NeTEx/.*)/siri.xsd', '$1/NeTEx_siri.xsd', 'i')
    let $out :=
        if (file:exists($try)) then $try
        else $try ! replace(., '-v\d\.\d', '')
    let $_DEBUG := trace($out, '*** Path of imported/included schema edited: ')
    return $out
};




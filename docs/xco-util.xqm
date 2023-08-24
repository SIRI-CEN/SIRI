module namespace u="http://www.parsqube.de/ns/xco/util";
import module namespace cf="http://www.parsqube.de/ns/xco/comp-finder"
  at "xco-comp-finder.xqm";
import module namespace co="http://www.parsqube.de/ns/xco/constants"
  at "xco-constants.xqm";
import module namespace ns="http://www.parsqube.de/ns/xco/namespace"
  at "xco-namespace.xqm";
import module namespace sf="http://www.parsqube.de/ns/xco/string-filter"
  at "xco-sfilter.xqm";

declare namespace z="http://www.parsqube.de/ns/xco/structure";

(:~
 : Transforms a literal string into an equivalent regular
 : expression. Rules:
 : (1) string "%20" is replaced with \s
 : (2) string "." is replaced with \s
 : (3) wildcards "?" and "*" are retained
 :
 : @param literal a literal string
 : @return the equivalent regular expression
 :)
declare function u:literalToRegex($literal as xs:string)
        as xs:string {
    $literal 
    ! replace(., '\.', '\\.')
    ! replace(., '[(){}\[\]]', '\\$0')
    ! replace(., '%20', '\\s')
};

(:~
 : Resolves and normalizes a URI. The URI is resolved against
 : an explicit base URI, or against the current work directory,
 : if no explicit base URI is specified.
 :)
declare function u:normalizeUri($uri as xs:string, $base as xs:string?)
        as xs:string {
    let $base := ($base, file:current-dir())[1] 
    return
        file:resolve-path($uri, $base) ! replace(., '\\', '/') 
        ! replace(., '/$', '')
        ! replace(., 'file:/*(([^/]:)?/.*)', '$1')
};

declare function u:removeAnno($node as node()) {
    typeswitch($node)
    case document-node() return document {$node/node() ! u:removeAnno(.)}
    case element(xs:annotation) | element(z:annotation) return ()
    case element() return 
        element {node-name($node)} {
            $node/@* ! u:removeAnno(.),
            ns:getNamespaceNodes($node),            
            $node/node() ! u:removeAnno(.)
        }
    case text() return
        $node[not((preceding-sibling::*[1], following-sibling::*[1])
              /self::*:annotation)]
    case attribute() return $node
    default return $node
};

(:~
 : Removes from the deep content of an input node all attributes (1) in a 
 : namespace matching an optional namespace filter and (2) with a local name
 : not matching an optional positive filter or matching an optional negative 
 : filter.
 :) 
declare function u:removeAtts($node as node(), 
                              $nsFilter as xs:string?,
                              $keepFilter as xs:string?, 
                              $discardFilter as xs:string?)
        as node() {
    let $nsFilterElem := $nsFilter ! sf:compileStringFilter(.)
    let $keepFilterElem := $keepFilter ! sf:compileStringFilter(.)
    let $discardFilterElem := $discardFilter ! sf:compileStringFilter(.)
    return u:removeAttsREC($node, $nsFilterElem, $keepFilterElem, $discardFilterElem)
};        

(:~
 : Removes from the deep content of an input node all attributes in the z 
 : namespace with a local name not matching an optional positive filter or 
 : matching an optional negative filter.
 :) 
declare function u:removeZAtts($node as node(), 
                               $keepFilter as xs:string?, 
                               $discardFilter as xs:string?)
        as node() {
    let $nsFilterElem := 
        sf:compileStringFilter('http://www.parsqube.de/ns/xco/structure http://www.w3.org/XML/1998/namespace')
    let $keepFilterElem := $keepFilter ! sf:compileStringFilter(.)
    let $discardFilterElem := $discardFilter ! sf:compileStringFilter(.)
    return u:removeAttsREC($node, $nsFilterElem, $keepFilterElem, $discardFilterElem)
};        

(:~
 : Removes from the deep content of an input node all attributes (1) 
 : in a namespace matching an optional namespace filter and (2) with 
 : a local name not matching an optional positive filter or matching 
 : an optional negative filter.
 :) 
declare function u:removeAttsREC($node as node(), 
                                 $nsFilter as element()?,
                                 $keepFilter as element()?, 
                                 $discardFilter as element()?) 
        as node()? {
    typeswitch($node)
    case document-node() return document {$node/node() ! 
        u:removeAttsREC(., $nsFilter, $keepFilter, $discardFilter)}
    case element() return 
        element {node-name($node)} {
            $node/@* ! u:removeAttsREC(., $nsFilter, $keepFilter, $discardFilter),
            $node/node() ! u:removeAttsREC(., $nsFilter, $keepFilter, $discardFilter)
        }
    case attribute() return
        let $ns := namespace-uri($node)
        return
            if ($nsFilter and not(sf:matchesStringFilter($ns, $nsFilter))) then $node
            else
            
        let $cond := (
            $keepFilter ! sf:matchesStringFilter(local-name($node), .),
            $discardFilter ! not(sf:matchesStringFilter(local-name($node), .))
            )
        return
            $node[every $c in $cond satisfies $cond]
    default return $node
};

declare function u:prettyNode($node as node()) {
    typeswitch($node)
    case document-node() return document {$node/node() ! u:prettyNode(.)}
    case element() return 
        element {node-name($node)} {
            $node/@*,
            ns:getNamespaceNodes($node),
                (: [$node/not(deep-equal(in-scope-prefixes(.), parent::*/in-scope-prefixes(.)))], :)
            $node/node() ! u:prettyNode(.)
        }
    case attribute() return $node
    case text() return
        $node[not(../*) or matches(., '\S')]
    default return $node
};

declare function u:copyNode($node as node()) {
    typeswitch($node)
    case document-node() return document {$node/node()}
    case element() return 
        element {node-name($node)} {
            in-scope-prefixes($node)
                ! namespace {.} {namespace-uri-for-prefix(., $node)},
            $node/(@*, node())
        }
    default return $node
};

(:~
 : Modifies a set of schemas, adding to anonymous type definitions
 : a @z:typeID attribute.
 :)
declare function u:addLocalTypeIds($schemas as element(xs:schema)*)
        as element(xs:schema)* {
    for $schema at $snr in $schemas/root()
    return
        copy $schema_ := $schema
        modify
            let $atypes := $schema_//(xs:simpleType, xs:complexType)[not(@name)]
            where $atypes
            return (
                for $atype at $tnr in $atypes return
                    insert node attribute z:typeID {'typedef-'||$snr||'.'||$tnr} into $atype,
                insert node attribute xml:base {$schema/base-uri(.)} into $schema_/*
        )
        return $schema_/*
};

(:~
 : Returns the type category for a given type name.
 :)
declare function u:typeCategory($typeName as xs:QName, $schemas as element(xs:schema)*)
        as xs:string? {
    if (ns:isQNameBuiltin($typeName)) then 
        if (local-name-from-QName($typeName) = ('any', 'anyAttribute')) then 'at' else 'sb' 
    else
        let $typeDef := cf:findType($typeName, $schemas)
        let $typeCat := $typeDef[1] ! u:typeCategory(.)
        return $typeCat[1]
};        

declare function u:typeCategory($type as element())
        as xs:string {
    if ($type/self::xs:simpleType) then
        if ($type/xs:restriction) then 
            if (empty($type/xs:restriction/(* except xs:annotation)) 
            and $type/xs:restriction/@base/resolve-QName(., ..)
                ! ns:isQNameBuiltin(.)) then 'se'
            else 'sr'
        else if ($type/xs:list) then 'sl'
        else if ($type/xs:union) then 'su'
        else 's?'
    else
        if ($type/xs:complexContent) then 'cc'
        else if ($type/xs:simpleContent) then 'cs'
        else 
            let $children := 
                $type/(., xs:complexContent/(xs:extension, xs:restriction))/
                (xs:sequence, xs:choice, xs:all, xs:group)
            let $atts :=
                $type/(., xs:complexContent/(xs:extension, xs:restriction))/
                (xs:attribute, xs:attributeGroup)
            return
                if ($children) then 'cc'
                else if ($atts) then 'ca'
                else 'ce'
};        

declare function u:isTypeCategorySimple($typeCategory as xs:string?)
        as xs:boolean {
    $typeCategory ! starts-with(., 's')        
};

(:~
 : Maps a type definition to the simple type which it contains.
 :)
declare function u:extractSimpleType($typeDef as element()?, 
                                     $schemas as element(xs:schema)*)
        as item()? {
    if (not($typeDef)) then () else        
    typeswitch($typeDef)
    case element(xs:simpleType) return $typeDef
    case element(xs:complexType) return
        let $extension := $typeDef/xs:simpleContent/xs:extension
        where $extension
        return
            let $localType := $extension/(xs:simpleType, xs:complexType)
            return
                if ($localType) then $localType/u:extractSimpleType(., $schemas)
                else
                    let $base := $extension/@base/resolve-QName(., ..)
                    return
                        if (ns:isQNameBuiltin($base)) then $base else
                        $base ! cf:findType(., $schemas)
                              ! u:extractSimpleType(., $schemas)
    default return ()                    
};

(:~
 : Maps an integer number to a letter representing it (1=a, 2=b, ...).
 :)
declare function u:letterNumber($number as xs:integer)
        as xs:string {
    substring('abcdefghijklmnopqrstuvwxyz', $number, 1)
};    

(:~
 : Returns a string describing the location of a local type definition.
 :)
declare function u:getLocalTypeLocator($type as element(),
                                       $nsmap as element(z:nsMap),
                                       $options as map(xs:string, item()*)?)
        as xs:string? {
    if (not($type/@z:typeID)) then () else
    let $globalComp := $type/ancestor::*[parent::xs:schema]
    let $globalCompName := $globalComp/@name/resolve-QName(., ..) ! ns:normalizeQName(., $nsmap)
    let $globalCompKind := $globalComp/local-name()
    let $withinCompPath := 
        $type/(ancestor::xs:element, ancestor::xs:attribute)
        [. >> $globalComp]/
        @name/concat(parent::attribute()/'@', .) => string-join('/')
    return
        string-join((
            $globalCompKind||'['||$globalCompName||']',
            $withinCompPath[string()]
        ), '/')||'#'||$type/local-name(.)
};    

(:~
 : Returns a label identifying a local type definition.
 :)
declare function u:getLocalTypeLabel($type as element(),
                                     $nsmap as element(z:nsMap),
                                     $options as map(xs:string, item()*)?)
        as xs:string? {
    u:getLocalTypeLocator($type, $nsmap, $options) 
    ! concat(., ' (', $type/@z:typeID, ')')
};

(:~
 : Returns the type label of a type descriptor.
 :)
declare function u:getDescriptorLocalTypeLabel($desc as element())
        as xs:string? {
    $desc/@z:typeID ! concat(../@z:typeLocator, ' (', .,')')
};

(:~
 : Returns the type label of a type descriptor as a couple of
 : <div> elements. (Useful for display in two lines.)
 :)
declare function u:getDescriptorLocalTypeLabelDivs($desc as xs:string)
        as element(div)+ {
    let $suffix := $desc ! replace(., '.*\s*(\(typedef.*)', '$1')[not(. eq $desc)]        
    let $prefix := $desc ! replace(., '\s*\(.*', '')
    return (
        <div><code>{$prefix}</code></div>,
        $suffix ! <div><code>{.}</code></div>
    )
};

(:~
 : Writes a document to the file system. If the folder does not
 : yet exist, it is created now.
 :
 : If no serialization parameters are specified, the output document
 : is indented.
 :
 : @param path the file system path of the output file
 : @param doc the documednt to be written (document or element node)
 : @serParams optional serialization parameters
 : @return the empty sequence
 :)
declare function u:writeXmlDoc($path as xs:string, 
                               $doc as node(), 
                               $serParams as map(xs:string, item()*)?)
        as empty-sequence() {
    let $dir := $path ! replace(., '/[^/]*$', '')
    let $_CRDIR := if (file:exists($dir)) then () else file:create-dir($dir)
    let $spar := if (exists($serParams)) then $serParams else map{'indent': 'yes'}
    return
        file:write($path, $doc, $spar)
};

declare function u:writeXmlDoc($path as xs:string, 
                               $doc as node())
        as empty-sequence() {
    u:writeXmlDoc($path, $doc, ())
};


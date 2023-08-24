(:
 : Namespace-related tool functions
 :)
module namespace ns="http://www.parsqube.de/ns/xco/namespace";

import module namespace co="http://www.parsqube.de/ns/xco/constants"
at "xco-constants.xqm";

declare namespace z="http://www.parsqube.de/ns/xco/structure";

(:~
 : Returns the qualified name of a top-level component.
 :
 : @param comp a schema component
 : @return the QName of the component
 :)
declare function ns:componentQName($comp as element()) 
        as xs:QName {
    $comp/QName(ancestor::xs:schema/@targetNamespace, @name)
};    

(:~
 : Returns the normalized QName of an XSD component. The comonent
 : is expected to be a child element of the schema element, with
 : a @name attribute.
 :
 : @param comp a schema component
 : @param nsmap a map representing the binding of namespace prefixes
 : @return the normalized QName of the component
 :)
declare function ns:normalizedComponentQName(
                        $comp as element(), 
                        $nsmap as element(z:nsMap)?) 
        as xs:QName {
    ns:componentQName($comp) ! ns:normalizeQName(., $nsmap)
};    



(:~
 : Normalizes a QName in accordance with a map of namespace bindings.
 :
 : @param qname the QName to be normalized
 : @param nsmap a map representing the binding of namespace prefixes
 : @return the normalized QName
 :)
declare function ns:normalizeQName(
                        $qname as xs:QName, 
                        $nsmap as element(z:nsMap)?) 
        as xs:QName {
        
   if (empty($nsmap)) then $qname
   else
      let $uri := namespace-uri-from-QName($qname)[string()]
                    (: if no namespace, the URI must be empty sequence :)
      return
         if (empty($uri)) then $qname else

         let $prefix := $nsmap/z:ns[@uri eq $uri]/@prefix
         return
             if (empty($prefix)) then $qname else
             let $lexName := string-join(($prefix, local-name-from-QName($qname)), ':')
             return QName($uri, $lexName)
};

(:~
 : Resolves a normalized lexical name to a QName.
 :
 : @param name a normalized lexical name
 : @param nsmap a map representing the binding of namespace prefixes
 : @return a QName
 :)
declare function ns:resolveNormalizedLexName(
                        $name as xs:string, 
                        $nsmap as element(z:nsMap)?) 
        as xs:QName {
    if (not(contains($name, ':'))) then QName((), $name) else        
    
    let $prefix := replace($name, '^(.+):.*', '$1')
    let $uri := $nsmap/z:ns[@prefix eq $prefix]/@uri
    return QName($uri, $name)
};

(:~
 : Determines whether a given QName belongs to the XSD namespace.
 :
 : @param qname the QName to be normalized
 : @return true or false, dependent on whether the name is in the XSD namespace
 :)
declare function ns:isQNameBuiltin($qname as xs:QName?) 
        as xs:boolean? {
    $qname ! (namespace-uri-from-QName(.) eq $co:URI_XSD)            
};        

(:~
 : Creates a map associating all target namespaces with normalized prefixes.
 : A normalized prefix is either customized prefix or a computed prefix. 
 : Customized namespace bindings are defined by config data:
 :   config/namespaces/namespace/(@prefix, @uri)
 : 
 : The map contains additional entries, associating the prefix 'z' with the 
 : namespace of xco structures, 'xml' and 'xs' with the official xml and XSD
 : namespaces.
 :
 : @schemas the schemas to be evaluated
 : @return a map containing prefix/uri pairs
 :)
declare function ns:getTnsPrefixMap($schemas as element(xs:schema)*,
                                    $custom as element()?)
      as element(z:nsMap) {
   let $customBindings := $custom/namespaces/namespace
   let $tnss := 
      for $t in distinct-values($schemas/@targetNamespace)
      order by lower-case($t) 
      return $t
    let $tnssCustom := $tnss[. = $customBindings/@uri]      
   return
      <z:nsMap>{
         (: Customized bindings :)
         for $tns in $tnssCustom
         return $customBindings[@uri eq $tns]/<z:ns prefix="{@prefix}" uri="{$tns}"/>,
         (: Computed bindings :)
         let $prefixTnsPairs := $tnss[not(. = $tnssCustom)] => ns:_getPrefixTnsPairs()
         for $pair in $prefixTnsPairs
         let $prefix := substring-before($pair, ':')
         let $tns := substring-after($pair, ':')
         where not($tns eq $co:URI_XSD)         
         return
            <z:ns>{
               attribute prefix {$prefix},
               attribute uri {$tns}
            }</z:ns>,
         (: Standard bindings :)
         <z:ns prefix="xml" uri="http://www.w3.org/XML/1998/namespace"/>,
         <z:ns prefix="xs" uri="http://www.w3.org/2001/XMLSchema"/>,
         <z:ns prefix="z" uri="http://www.parsqube.de/ns/xco/structure"/>
      }</z:nsMap>
};

(:~
 : Returns for a sequence of namespace URIs the normalized prefixes. For each 
 : namespace a colon-separated concatenation of prefix and namespace URI is 
 : returned. Normalized prefixes are the lower case letters corresponding to 
 : the position of the namespace URI within the list of namespace URIs. If 
 : the position is gt 25, the letters are reused and a suffix is appended 
 : which indicates the number of the current letter cycle (2, 3, ...). The 
 : prefixses therefore are:
 : 'a', 'b', 'c', ..., 'x', 'y', 'a2', 'b2', .....
 :
 : @tnss the target namespaces
 : @return the prefix/tns pairs
 :)
declare function ns:_getPrefixTnsPairs($tnss as xs:string*) 
      as xs:string* {
   for $tns at $pos in $tnss
   let $seriesNr := ($pos - 1) idiv 25
   let $postfix := if (not($seriesNr)) then () else $seriesNr + 1
   let $p := 1 + ($pos - 1) mod 25
   let $char := substring('abcdefghijklmnopqrstuvwxy', $p, 1)
   let $prefix := concat($char, $postfix)
   where not($tns eq 'http://www.w3.org/XML/1998/namespace')
   return concat($prefix, ':', $tns)
};

(:~
 : Adds to an element the namespace bindings described by a namespace map.
 :
 : @param elem the element to be modified
 : @param nsmap a namespace map, associating prefixes with URIs
 : @param options currently not evaluated
 : @return a copy of the element with namespace bindings added
 :)
declare function ns:addNamespaceContext($elem as element(), 
                                        $nsmap as element(z:nsMap),
                                        $options as map(xs:string, item()*)?)
        as element() {
    element {node-name($elem)} {
        if ($options?discard) then () else
        $elem/in-scope-prefixes(.) 
            ! namespace {.} {namespace-uri-for-prefix(., $elem)},
        $nsmap/z:ns/namespace {@prefix} {@uri},
        $elem/@*,
        ($options?baseUri ! attribute xml:base {.})[not($elem/@xml:base)],
        $elem/node()
    }
};        

(:~
 : Returns the namespace nodes of an element.
 :
 : @param elem an element
 : @return a copy of its namespace nodes
 :)
declare function ns:getNamespaceNodes($elem as element())
        as node()* {
    $elem/in-scope-prefixes(.)[string()]
    ! namespace {.} {namespace-uri-for-prefix(., $elem)}
};        






Server Interface for Real-time Information
==========================================

v2.0 As CEN draft European Standard
	prCEN/EN EN 00278181
	prCEN/EN EN 15531  

v1.0 As CEN Technical Standard
	CEN/TS 00278181
	CEN/TS 15531

(C) Copyright CEN SIRI 2004-2013

===========================================
This ReadMe describes Changes to the SIRI schema up to  v2.0 version 2.0   since v1.3  (2012/03/30)

   
========================     
     	Future: handbook  UML DIagrams
========================
Changes to  SIRI schema v2.0   since v1.4

 2015.05.13 Bug fix (from french feedback) SIRI 2.0p
	* replacement of "NotifyExtension" (appearing 10 times) with "SiriExtension" in siri_wsConsumer.wsdl in order to ensure compatibility with the Document version

 2015.05.13 Bug fix (from SG7 feedback) SIRI 2.0o
 	* update annotation in siri.xsd and and siri_all_functionalService.xsd (to add <Requires> siri__facilityMonitoring_service.xsd ...)
	* siri.xsd: move of a SituationExchangeDelivery, renamed IncludedSituationExchangeDelivery, before other complemented service deliveries.
	* siri_situationExchange_service.xsd: addition of IncludedSituationExchangeDelivery element

 2015.05.11 Bug fix (from SG7 skype meeting on May 11th 2015) SIRI 2.0o
 	* Allow multiple tags within an extension (reapply lost chnage from 2012.06.18 SIRI 2.0d) - siri_utility.xsd
	* siri_estimatedVehicleJourney.xsd : in EstimatedTimetableAlterationGroup, addition of FramedVehicleJourneyRef as an alternative to DatedVehicleJourneyRef (choice) and deprecation of DatedVehicleJourneyRef and EstimatedVehicleJourneyCode
	* siri_datedVehicleJourney.xsd : DatedVehicleJourneyCode is now optional
	* siri.xsd: SituationExchangeDelivery now can be provided as a complement to any other Service delivery (and can still be provided standalone)... note that the SituationExchangeDelivery must be after the other Delivery to get a validating, non-ambiguous XSD.
	* siri_estimatedVehicleJourney.xsd : EstimatedVehicleJourneyStructure brought back to SIRI 2.0k situation
		* Replacement of EstimatedJourneyInfoGroup by JourneyEndTimesGroup 
		* Replacement of inclusion of siri_journey.xsd by siri_monitoredVehicleJourney.xsd
		* Replacement of EstimatedRealtimeInfoGroup by journeyProgressGroup
		* Replacement of OperationalInfoGroup by TrainOperationalInfoGroup


 2015.02.10 Bug fix (from french feedback)
 	* [fr] siri_wsProducer-Framework.xsd: use of siri:CheckStatusRequestStructure instead of siri:RequestStructure for checkStatus (one addition non mandatory version attribute)
 	* [fr] siri_wsProducer.wsdl: use of siri:CheckStatusRequestStructure instead of siri:RequestStructure for checkStatus (one addition non mandatory version attribute)
 	* [fr] siri_wsConsumer-Framework.xsd: update type of NotifySubscriptionTerminated to siri:SubscriptionTerminatedNotificationStructure (instead of TerminateSubbscriptionREquest !)

 2014.11.17 Correction (from french feedback)
 	* [fr] fix RPC-Document compatibility issue for GetSiri in Document WSDL  (siri_wsProducer-Services.xsd): addition of Request/Answer wrapper
 	* [fr] fix WSDL Document issue: GetCapability was using Answer instead of Request (siri_wsProducer-DiscoveryCapability.xsd)
 	* [fr] fix RPC-Document compatibility issue for LinesDiscovery,ConnectionLinksDiscovery,StopPointsDiscovery in Document WSDL (siri_wsProducer-DiscoveryCapability.xsd): deletion of useless «xxxAnswerInfo» wrapper

 2014.06.20 Correction and revisions from Stenungsund 
       [Part2]
        * [fx] Document SubscriptionTerminatedNotification and add error code. (siri-requests.xsd)
        * [fx] StopDiscovery response. Add RouteDirection. Rename JourneyPattern/Stops to JourneyPattern/StopsInPattern  SubscriptionTerminatedNotification and add error code. (siri-requests.xsd)
        * [de] Add Extensions to discovery requests. (siri_discovery.xsd)

       [Part3]
        * [ch] Add origin display whereever destination display as per Cologne meeting (siri-Journey.xsd,   siri-DatedVehicleJourney.xsd, 
        * [xh[ Add OriginAtDestination    wherever destination display as per Cologne meeting (siri-Journey.xsd) 
        * [fx] Set default on new DetailLevels on ConnectionMonitoring and EstimatedJourney for backwards compatability. (siri_connectionMonitoring_ervice.xsd siri_EstimatedTimetable_service.xsd
        * [ch] Add recordedCall to Estimated jouernesy to allow times for passed stops to be included.  iri_EstimatedVehicleJourney.xsd
       [Part5 SituationExchange]
        * [de] Add missing AffectedFacility that was in document but missing from schema. VehicleJourney, STop & StopComponent siri_situationAffects.xsd.
emporal filter siri_situationExchaneg_service.xsd.
        * [de] Add temporal filter to request with ValidityPeriod in   siri_situationExchange_service.xsd.  
	* [se] Add end time precision to halfopen time rangefor  input a siri_time.xsd.
	* [se] Add end time status  to halfopen time range output  siri_time.xsd.
        * [fr] Add additional small delay bands siri_situation.xsd
        * [de] Add IncludeOnly-IfInPublicationWindow to situation request temporal filter siri_situationExchange_service.xsd.
        * [fx] StopPlaceFilterGroup: add missing component ref and facility that was in doc but missing from schema  siri_situationExchange_service.xsd.
        * [fx] Add missing AccessFeature type to AFfectedStopPlaceComponent   siri_situationAffects.xsd.
        * [fx] Correct cardinality on FacilitRef on request to match doc siri_situationExchaneg_service.xsd.
        * [fx] Correct spec to include projection attributes for AFfectedStopPlaceComponent  doc.
        * [doc] Document FacilityRef as part of request doc
        * [doc] Document Access Mode as part of request doc
        * [doc] Document Scope as part of request doc
        * [doc] Document RoadFilter and Accessibility need filter  as part of request doc
        * [doc] Correct Documentation of AfFfectedRoads as part of Delivery doc
        * [doc/fx] Correct Documentation of capability Matrix and update in schemas well siri_situationExchange_service.xsd.
        * [doc/fx] Correct Documentation of Reason codes and correct in schema siri_reasons.xsd
        * [doc] Add Annex D to Doc on GTFS real-time mapping
        
 2014.05.26 Changes to answer comment from the EU ballot
	* [fr]  Addition of SubscriptionTerminatedNotification (XSD and WSDL SOAP Web Services(RPC/Document & WSDL2))
			- File siri_common_services.xsd: Addition of SubscriptionTerminatedNotification (SubscriptionTerminatedNotification element + SubscriptionTerminatedNotificationStructure )
			- File siri.xsd: addition of SubscriptionTerminatedNotification in servicesResponseGroup
			- Update of siri_wsConsumer-Document.wsdl, siri_wsConsumer.wsdl, siri_wsConsumer-WSDL2.wsdl to add a NotifyTerminateSubscription
			- File siri_wsConsumer-Framework.xsd: Addition of  WsSubscriptionTerminatedNotificationStructure and NotifySubscriptionTerminated
	* [fr]  Added ParameterName [0..*] to ParametersIgnoredErrorStructure (siri_request_errorConditions.xsd)
	* [fr]  Added ExtensionName [0..*] to UnknownExtensionsErrorStructure (siri_request_errorConditions.xsd)
	* [fr]  Added InvalidRef [0..*] to InvalidDataReferencesErrorStructure (siri_request_errorConditions.xsd)
	* [fr]  Added Vesion attribute (non mandatory) to CheckStatus request (siri_common_services.xsd)
	* [fr]  ChangeBeforeUpdates not anymore mandatory in EstimatedTimetableSubscriptionPolicyGroup
	* [fr]  added optional RecordedAtTime to EstimatedVehicleJourney
	* [fr]  added ConnectionLinksDiscovery service to WSDL (RPC/Document & WSDL2) (and siri_wsProducerDicoveryCapability.xsd)
	

 2013.06.26 French comments (compatibility issue)
	* [fr]  Change SOAP Web Service namesapce to http://wsdl.siri.org.uk (previously http://wsdl.siri.org.uk/siri)

	* [fr]  update EstimatedVehicleJourney in order to have it consistent with MonitoredVehicleJourney and Siri 2.0 
    		- use JourneyEndTimesGroup  in place of EstimatedJourneyInfoGroup
    		- use JourneyProgressGroup in place of EstimatedRealtimeInfoGroup
    		- use TrainOperationalInfoGroup in place of OperationalInfoGroup
    		- addCallRailGroup (containing PlateformTraversal ) and CallRealTime to EstimatedCall
 2013.02.20 WG3 SG meeting Munich
	* [se]  Add JourneyEndNamesInfoGroup to EstimatedDirectionAtStop to DestinationDisplayAtStop
	        This makes destination name available on EstimatedJourney.
	* [us]  Rename ProgrssStatusEnumeration  to CallStatusENumeration to avoid confusion.
	* [fr}  Add FramedVehicleJourney references as alternative  wherever a simple VehicleJourneyRef exists and deprecate use of simple reference.
	        - DatedVehicleJourney - identifier group.
		- FacilityMonitoring - FacilityLocation.
		- SituationExchangeService - SituationFilterGroup. 
		- SituationExchangeService - AffectedVehicleJourneyRef. 
	* [ch]  StopTimeTableCancellation - Add Reason code to be consistet with St	opMonitoring.
	* [de]  ArrivalTimesDepartureGroup - add ExpectedArrivalPredictionQuality element.
	* [fr] MonitoredStopVisit Cancellation make VisitNo LineRef DirectionRef optional.
	* [fr] EstimatedTimetable, COnnectionMonitoring  add detailed level to reqyest

	* [fr] Make AdditionalVersionRefS to OperationalInfoGroup.
	* [fr] Add JourneyPatternName The JourneyPatternInfoGroup.  
	
 2013.02.11
	* [SE]  Align documentation and XSD. See comments in individual xsd-files.
	* [SE]  Add StopNotice and StopNoticeCancellation to StopMonitoringDelivery.
	* [SE]  Revise ProductionTimetableDelviery to correct  ServcieJourneyInterchange to include visit numbers.
	* [FR]  Updated with latest WDSL from CD.


 2012.08.01
         SIRI 2.0e.1. 
	* [DE]  Align documentation and XSD using GT's amendments.
	* [FR] Update WDSL and add WSDL2..   Add WSDl chapter by CD to gudie..
	* [DE] Add Delegation elements to more mesages.
	* [US] Revise Siri Lite  chapter.
	*[DE] Revise commends on Prediction quality based on  CB's  comments

 2012.06.18
    SIRI 2.0d.2. 
       * [CH]   Allow multiple tags within an extension
       * [CH]   Make most NL String elements unbounded to allow for  NL translations. x dx
       			Add IncludeTranslations to RequestPolicy. 
       			Add Translations to Cpabilities
       * [DE]    Add PredictionQuality elements to MonitoredVehicleJourney Onward Call. & EstimatedVehcielJourney
    	* [FR]    Add GroupOfLinesRef to JourneyPattenrInforGroup on MonitoredVehcile Joruney and elsewhere
    	* [FR]    Add Extensions tag to EstimatedTimetableSubscriptionRequest x tx
    	* [FR]    Add Extensions tag to FacilityMonitoringSubscriptionRequest x  
     	* [FR]    Add Extensions tag to SituationExchangeSubscriptionRequest x
     	* [FR]    Add Extensions tag to ConnectionMonitoringSubscriptionRequest     x	tx
     	* [FR]    Add Extensions tag to Connection|TimetableSubscriptionRequest x tx
     	* [FR]    Add Extensions tag to VehicleMonitoringSubscriptionRequest x tx
     	* [FR]    Add Extensions tag to Terminate SubscriptionRequest x tx
    	* [DE]   Correct EstimatedTimetable EstimatedServiceJourneyInterchange  x tx
	 *[US]   Add SIRILite chapter to manual.
     	* [DE]   Add DelegatorAddress and DelegatorRef to servicerequest and service response. x tx
     	* [SE]  Correct latestExopectedArrivalTime
     	* [SE]  Add Vehicle Status    add additional arrival and departure states
     	    	
     	    	
 2012.05.31
      SIRI 2.0d.1. 
	* [MTA] Discovery Revise StopLine discovery to include line direction x
	* [MTA] Discovery Revise  Line discovery to include Direction/Line x
	* [MTA] Correcct typo in name of   RouteDirection x
	* [Init] Add DriverRef to vehiclejourney x tx

 SIRI 2.0c.1. 
      2012.06.11
	  SIRI 2.0c
	    Relax typing on NotifcationRef to be normalized string x
	    Add wsdl subdirectory  for  wsd .xsds	x
	         
   2012.06.08
     WSDL [FR] x
	In siri-wsProducer-Document.xsd rename StopMonitoringType and StopMonitoringMultipleType to StopMonitoringRequestType to StopMonitoringMultipleRequestType (for more consistent naming)
	Add comment to point out that usage of SOAP Fault are now deprecated
	Add comment to point out that usage of MultipleStopMonitoring is now deprecated (utilise GetSiriService)
	Addition of a Document Wrapped encoding style fully compatible with the RPC Style (Producer and Consumer)
	Add GetSiriService in RPC and Document Wrapped mode
	Addition of StopDiscovery and LineDiscovery 
	Cleaning of xmlns:xxx in siri_wsProducer-Document
	Suppression of comments on <operation name="GetCapabilities"> and <operation name="CheckStatus"> (for http://www.validwsdl.com/ compliance) .. in poducer and producer-Document WSDL
	Rename of Port/Binding/Service in order to clearly diffirentiate them
	Change <import> to <type>+<include>
 	  
   2012.05.17
      SIRI 2.0b.3
	 [MTA]  Add filtering to StopPoints and Lines Discovery requests by point + radius  x
	 [MTA]  Add filtering to Lines Discovery  request by LineRef and Direction x
	 [MTA]  Add stops in pattern to Lines Discovery, with OnwardLinkShap and   LineDetailParameter x
	 [NeTEx]    Add StopAreaRef &  url to annotated stop on StopDiscovery x
	 [General] Correct capability definition
	 
   2012.04.18
      SIRI 2.0b.2
          [VDV] Add ValidUntil to individual SIRI-CM MonitoredFeederArrival x e
   	  [VDV] Add ValidUntil to individual SIRI-SM MonitoredStopVisit x e
   	  
   	  
	  [MTA] Add DistanceFromStop and NumberOfStopsAway to  to MonitoredCall & OnwardsCall  x tx 

   2012.03.23
        SIRI 2.0b.1
	  [MTA]  Add filtering to StopPoints request by point + radius  

   2012.03.23
     WDSL
     	Add explicit namespace to body  x
     	Use a SIRI namespace  http://wsdl.siri.org.uk/siri  x
     	Correct GetStopTimentable to have soapAction x
     	Turn annotations into comments  x
     	Use FaultLiteral x
     	     
     SIRI 2.0a
     	Changes to framework
     		[VDV] Add DataReady to CheckStatus response x. tx.
     		
  	JourneyInfo group SIRI-ST SIRI-SM SIRI-VM SIRI-PT SIRI-ET MonitoredJourney, etc
		[VDV] Add PublicContact & Operations contact to JourneyInfo group    in  x tx
		[VDV] Add ViaPriority to ViaNames using a new ViaNameStructure x tx
		[VDV] at DirectionAtOrigin name to JourneyInfo  SIRI-PT, SIRI-ET, SIRI-SM. SIRI-VM
		
		[VDV] Add EstimatedServiceInterchange  to EstimatedTimetableDelivery x tx.
		[VDV] Add ServiceJourneyInterchange to ProductionTimetableDelivery  SIRI PT x tx
     
   	Changes to MonitoredVehicleJourney     SIRI-SM SIRI-VM
		[VDV, SE] Add EarliestExpectedArrivalTimeForVehicle to Arrival Times Group x tx
		[VDV] Add ProvisionalExpectedDepartureTime  to  Departure Times Group  x tx
		[VDV, SE] Add latesExpectedArrivalTimeForVehicle to Departure Times Group x tx 
		[SE] Add Aimed and expected Platform assignments to CALLs including a reference code. 

		[FR] Add FirstOrLastJourney to JourneyTimesGroup x.tx.
		[FR] add ArrivalOperatorRefs and DepartureOperatorRefs to Call arrival and  Departure
		[VDV] Add Velocity to MonitoredVehicleJourney JoueyProgerssGroup  SIRI-SM and SIRI-VM
		
		[FR] Add AimedLatestPassengerAccessTime to MonitoredCall & OnwardsCall  x tx  
		[MTA,FR,UK] Add ArrivalProximityText & DepartureProximityText to MonitoredCall & OnwardsCall  x tx 
		[FR, MTA] Add Velocity to Journey & VelocityType x tx
		
	StopMonitoringRequest SIRI-SM
		[VDV] Add   Minimum-StopVisits¬PerVia to STopMonitoringRequestPolicy x tx
		[VDV] Add  HasMinimum-StopVisits¬Via  to STopMonitoringCapabilities x tx
		
	StopMonitoringDelivery  SIRI-SM  
		 [FR] Add Service Exception element
		 [VDV] Add delivery variant to LineNote	
		 [MTA] Add MaximumNumberOfCalls to VehiclelMonitoring request
	
	StopMonitoringDelivery  SIRI-SX  
		Upgrade to DatexII	
	
	ConnectionMonitoringDelivery  SIRI-CM  				 
		[VDV] Add SuggestedWaitDecisionTime to MonitoredFeederArrival SIRI-CM  x tx
	
	Enabling SIRI Lite
		[MTA, UK] Add optional authenitication  Key to Servce Request TODO 
		[MTA, UK] Add optional name  to StopMonitoring response x tx
		[MTA, UK] Add optional  name  to VehicleMonitoring response x tx
	
	Discovery services
		[Fr] Add location to stop discovery x. 		
		
	General Framework 
		[VDV] Add ErrorNumber to Error Structure  SIRI - All 
	
		[VDV] Add new error conditions

			UnknownParticipant	Recipient for a message to be distributed is unknown. +SIRI v2.0
			UnknownEndpoint	Endpoint to which a message is to be distributed is unknown. +SIRI v2.0
			EndpointDeniedAccess	Distribution message could not be delivered because not authorised.. +SIRI v2.0
			EndpointNotAvailable	Recipient of a message to be distributed is not available. +SIRI v2.0
			UnapprovedKey	User authorisation Key is not  enabled. +SIRI v2.0

			InvalidDataReferences	Request contains references to  identifiers that are not known.  +SIRI v2.0
			ParametersIgnored	Request contained parameters that were not supported by the producer. A response has been provided but some parameters have been ignored. +SIRI v2.0
			UnknownExtensions	Request contained extensions that were not supported bu the producer. A response has been provided but some or all extensions have been ignored.. +SIRI v2.0

		[FR] Add DistanceUnits & Velocity Units to ServiceRequestContext x tx	

	General improvements to internal structure  maintainability 
	     Tidy up comments. x tx.
	     Improve modularisation (eg permissions/model permissions) to avoid circuloar refs x
	         Separate subdirectories for common request, model and core  elements x
	         Separate out some model elements into separate packages x
	         Separate out model journeys from SIRI service packagaes x
	         Separate out discovery models from discovery services x
	         
        Start of v2,0 ==>

Changes to SIRI schema v1.4a   since v1.3 
============================ 

2011-04-18 Corrections - New cumulative fix version 1.4a
   Minor corrections arising from user feedback

     (a) siri_generalMessage_service.xsd (line 221) Missing extension point in InfoMessageStructure in  Robin Vettier Ixxi.biz
           (i) 	 Add to general message request   x
           (ii)  and siri_generalMessage_service.xsd subscription structure  x
           (iii) Missing type: Assign a type of normalizedString to formatRef x dx
           
     (b) siri_requests.xsd  (line 814) ErrorConditionStructure  should not be abstract . Fix from RV ixxi.biz- 
          made abstract x
          
     (c) siri_journey.xsd (l.1015).  FramedVehicleJourneyRef isn't mandatory in MonitoredCall SIRI-SM answer  according to CEN TS (prCEN/TS 15531-3:2006 (E)  p.56). Make optional.  RV  ixxx.com
          made optional Fix from RV ixxi.biz x ??
          
     (d) siri_productionTimetable_service.xsd Type on request ValidityPeriod start and end should be datetime not time 
		 - Change to ClosedTimestampRange instead of ClosedDateeRange x tx.
                 - Fix  Subscription request to be an element and to have IncrementalUpdate parameter Extensions x
                 
     (e) siri_situation.xsd AffectedVehicleJourney should allow multiple journeys. Brian Ferris onebusaway.org>, x
     
     (f) ifopt_location.xsd Correct  siri: namespace  x
     
     (g) Fix up examples 
		(i) correct estimated timetable request, production timetable request, stop monitoring request, stop monitoring eprmissions. drop flat examples tx.
		(ii) Add examples for facility monitorign and situation exchange ex
		
     (h) Drop vestigial   As Flatgroup alternative coding  tx
		siri_connectionTimetable_service.xsd	InterchangeHourneys x tx
		siri_estimatedTimetable_service.xsd	  EstimatedCalls --> x tx
		siri_productionTimetable_service.xsd	  DatedCalls --> x tx
		
     (i) Add missing type
		siri_requests.xsd	formatRef x
	  	DATEXIISchema_1_0_1_0.xsd modelBaseversion
	  	
     (j)siri_facility.xsd TidyUp empty ValidityConditionGroup x
     
     (g) Add xmlSPy project spp. x

======================
Version 1.3 Approved to accompany SIRI-SX & SIRI-FM 

2009-03-31  Corrections 
    (a) siri.xsd Correct cardinality on SIRI-SX request & SIRI-FM request to be many x
    (b) siriSg.xsd Remove unnecessary groups for decoupled version x tx.
    
2009-03-31  Corrections 
    (a) StopMonitoring  
    Change the element type of MaximumNumberOfCalls.Previous, MaximumNumberOfCalls.Onwards  from xsd:positiveInteger to xsd:nonNegativeInteger  x tx.
    
   and clarify handling of 
    
    MaximumNumberOfCalls :  If calls are to be returned, maximum number of calls to include in response. If absent, exclude all calls.  tx.
    
    Previous :  Maximum number of previous calls to include. Zero for none. Only applies if MaximumNumberOfCalls  specified. Zero for none. If MaximumNumber of Calls specified but  MaximumNumberOfCalls.previous absent, include all previous calls. tx.
    
    Onwards : Maximum number of onwards calls to include. Zero for none. Only applies if MaximumNumberOfCalls  specified. Zero for none. If MaximumNumber of Calls specified but  MaximumNumberOfCalls.Onwards absent, include all onwards  calls. tx.
    
___________________________________________________________________________
    
    (b) siriSg.xsd Remove uneccessary groups for decoupled version
    
2009-03-03  Corrections 
    (a) siri.xsd Correct cardinality on SIRI-SX request & SIRI-FM request to be many x
    (b) siriSg.xsd Correct cardinality on servcierequest & subscription request to be many x
    
2009-09-18  Siricommon - allow empty Terminate subscription response  x
    (a) Relax mandatory on  in siri_common x
    
2008-11-18  Revise FM servics 
    (a) Revise daytypes in siri_time.xsd x
    
2008-11-17  Revise to support substitution groups
    (a) Make all requests subtypes of abstract request.  Add Subst elements x
    
    (b) Introduce  AbstractFunctionalServiceRequest, AbstractCapabilityServiceRequest, AbstractDiscoveryRequest
    as common supertypes. revised versiosn of siri_requests.xsd,  siri_journey.xsd and siri_permissions.xsd, siri-All and siribase
    
    (c) add SiriSg and Siri_base.xsd packages
2008-11-12  Corrections to the Caridnailities on the siri_discovery services  x

    (a) Change min maxes on >LineRef, StopPoints, Features etc etc x
    
2008-10-08  Corrections to the SIRI  service  
    (a) Add SubscriberRef to TerminateSubscriptionRequest  x tx. 
    
2008-10-06  Corrections to the SIRI  service  
    (a) Correct StopTimetable SubscriptionRequest to use group  x
    (b) Correct cardinality on AnnotatedStopPointRef in StopPointDelivery  x
    
2008-10-01  Corrections to the SIRI-SX service  
    (a) Add StatusFilterGroup  to SIRI-SX request with Verification,   Progress and Reality 
    (b) add Predictability
    
2008-09-30  Corrections to the SIRI-SX service      
    (a) Make Undefined and Unknown reason codes strinsg so they do not require content
    (b) Extensions change defaults to lax,  type =#any   to simplify binding
    
2008-07-07  Corrections to the SIRI-SX service      
    (a) Allow link projection and start / end offset.
    (b) Introduce a separate AffectedSection to handle this (refines SectionRef) 
        used on AffectedRoute    
    (c) Allow a link projection & Offset  on connection Link via AffectedPathLink
    (d) Add an AfFfectedRoad to hold basic road details 
    (e) Correct SX request to be predctability not nature
    (f) Add Scope to SX request
     
2008-07-05  Corrections to the SIRI-SX service               
    (a) SIRI_SX Rename AccessibilityDisruption to AccessibilityAssessment & reuse ifopt defs
2008-07-05  Corrections toi the SIRI-SX service               
    (a) SIRI_SX Add missing SituationRecord to RoadSituation
    (b) SIRI_SX correct type to be participant ref  not participant pair ref--> x
    (c) Allow zero PT or Road Situation elements in a delivery x
    (d) Affects Line group corrected to ref a lineref and not a route ref  x
    (e) Add missing scopeType to Situation classifier group x 
    (f) Add other subreasons x
    (g) add secondary reasons x

2008 05 08  StopMonitoring service 
    (a) Correct type on  FeatureRef in Stop monitoring   x    
    (b) Add StopMonitoringMultipleRequest x tx
    (c) Add optional MonitoringRef to StopMonitoringDelivery so that can return id even if no data  x tx.
 
2008 03 27
    Fix up ifopt & ACSB version numbers to match ifopt 0.4  x
    
    
2008-03-26 EstimatedTimetable Production Timetable Service Service 
     Add wrapper tag for Line + Direction to help binding to Axisx  x tx.
     Wraps multiple instances x
     ** Note this will break strict Compaptibility with 1.0    
     
2008 03  12    
       Add comments for elements and arrtributes that lacked them x 
       Correct wdsl errors  x
       Strip out degree character  x 
       BeyondHorizon type corrected  x
       
2008 02  12    
      Add SIRI-SX revisions & Datex2 harmonisation features

2008 02 12 V1.3 draft
=====================================
2007 10  17 
      Add Situation Exchange & Facility Exchange services. x tx
      Added a  siri_all.xsd, ifopt_allStopPlace.xsd, acsp_all.xsd packages to force explicit declaration of all elements in an imported namespace on the first reference. This overcomes a limitation of some XML tools that only pick up thos elements on the first import and ignotre all subsequent imports.  


2007 04 17 
    Name Space improvements
        revise to use explicit namespaces x
        Change name space :  http://www.siri.org.uk/  to www.siri.org.uk/siri   x.tx.
        
    harmonise Facility Monitoring 
         Revise SpecialNeeds to use  acsb package   x.
         Use Ifopt facility etc x.       
         Factor out Extensions to utility file  x.
         
2007 04 V1.2 
=======================================

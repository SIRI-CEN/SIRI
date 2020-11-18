# Changelog

## 20201117 - Sync CEN Integration 
(https://github.com/SIRI-CEN/SIRI/commit/ad55f2c45f97e67ac6abf00a00020e6ec149565c)
* SituationExchangeRequestPolicyGroup:Language unbounded
* ProductionTimetableServiceCapabilitiesStructure:ProductionTimetableServiceCapabilitiesStructure new Filters added
* DatedTimetableVersionFrameStructure: new elements added
* ProductionTimetableRequestPolicyGroup: new elements added, Language unbounded
* Changes in ProductionTimetableTopicGroup
* GeneralMessageRequestPolicyGroup:Language unbounded
* FacilityMonitoringRequestPolicyGroup:Language unbounded
* EstimatedTimetableServiceCapabilitiesStructure: new elements added
* EstimatedTimetableSubscriptionPolicyGroup: new elements added
* EstimatedTimetableRequestPolicyGroup: new elements added, Language unbounded
* VehicleFeaturesRequestPolicyGroup: Language unbounded
* ProductCategoriesRequestPolicyGroup: Language unbounded
* LinesDiscoveryRequestPolicyGroup: Language unbounded
* StopPointsDiscoveryRequestPolicyGroup: Language unbounded
* ConnectionTimetableRequestPolicyGroup: Language unbounded
* ConnectionMonitoringRequestPolicyGroup: Language unbounded
* KeyListStructure added
* LengthType, WeightType, NumberOfPassengers, PercentageType added
* DayTypeEnumeration / TimetableTypeEnumeration / RoutePointTypeEnumeration / StopPointTypeEnumeration / BookingStatusEnumeration / TicketRestrictionEnumeration / InterchangeStatusEnumeration / ReportTypeEnumeration   
* TpegReasonGroup clean up
* SituationBaseIdentityGroup.ParticipantRef 0.1 instead of 1.1
* VerificationStatus clean up
* Predictability uses PredictabilityEnumeration instead of  VerificationStatusEnumeration
* ServiceConditionEnumeration / SeverityEnumeration clean up
* StopPlaceTypeEnumeration added
* AffectedStopPlaceComponentStructure/AffectedPathLinkStructure:AccessibilityFeatureEnumeration in Siri namespace instead of ifopt
* AffectedStopPlaceStructure: StopPlaceTypeEnumeration in Siri namespace instead of ifopt
* PtAdviceStructure: new elements added
* PtConsequenceStructure:ConditionGroup instead of element condition 
* DefaultedTextStructure extends NaturalLanguageStringStructure instead of PopulatedStringType with xml:lang optional
* ScopeTypeEnumeration: new values added
* StatusGroup:Progress 0.1 instead of 1.1 (because default provided)
* SituationSourceStructure:Country element renaming undo, type set to ifopt:CountryRefStructure
* BrandingCodeType, BrandingRefStructure, BrandingStructure: new elements
* OccupancyEnumeration: new values added 
* TrainOperationalInfoGroup: new element JourneyFormationGroup added
* new element DatedTrainOperationalInfoGroup / DatedJourneyPartInfoStructure added
* JourneyPartInfoStructure: new elements and cardinality changes
* ProgressDataQualityGroup:PredictionInaccurateReason new element added
* VehicleModesOfTransportEnumeration new values added
* FilterByVehicleMode / FilterByProductCategoryRef: new elements added
* PredictionInaccurateReasonEnumeration, JourneyRelationTypeEnumeration, QuayTypeEnumeration, TrainElementTypeEnumeration, TrainSizeEnumeration, TypeOfFuelEnumeration, FareClass, FareClasses, FareClassListOfEnumerations, FareClassEnumeration, VehicleInFormationStatusEnumeration, FormationChangeEnumeration new elements added
* TrainElementCodeType, TrainElementRefStructure, TrainElementRef, TrainComponentCodeType, TrainComponentRefStructure, TrainComponentRef, TrainCodeType, TrainRefStructure, TrainRef, CompoundTrainCodeType, CompoundTrainRefStructure, CompoundTrainRef, TrainInCompoundTrainCodeType, TrainInCompoundTrainRefStructure, TrainInCompoundTrainRef, EntranceToVehicleCodeType, EntranceToVehicleRefStructure, EntranceToVehicleRef, TrainFormationReferenceGroup: new elements added
* ConnectingJourneyRefStructure, DatedVehicleJourneyIndirectRefStructure, QuayType, JourneyRelationsStructure, JourneyRelationStructure, JourneyRelationInfoGroup, RelatedCallStructure, RelatedJourneyPartStructure, RelatedJourneyStructure, JourneyFormationGroup, VehicleOrientationRelativeToQuay, FormationAssignmentStructure, FormationConditionStructure, FormationStatusStructure, VehicleInFormationStatusStructure, FormationStatusInfoGroup, RecommendationStructure, PassengerCapacityGroup, OccupancyScopeFilterGroup, OccupancyValuesGroup, GroupReservationStructure, VehicleOccupancyStructure, PassengerCapacityStructure, TrainElementStructure, TrainElementGroup, TrainComponentStructure, TrainComponentGroup, TrainStructure, TrainGroup, CompoundTrainStructure, TrainInCompoundTrainStructure, TrainInCompoundTrainGroup, PassageBetweenTrainsStructure, VehicleTypeGroup, VehicleTypePropertiesGroup, VehicleAccessibilityRequirementsGroup, VehicleDimensionsGroup, DepartureCancellationReason, ArrivalCancellationReason : new elements added
* StopAssignmentStructure: new elements added 
* OnwardVehicleArrivalTimesGroup/DatedVehicleJourneyStructure: new elements added
* MonitoredStopDepartureStatusGroup / MonitoredStopArrivalStatusGroup / AimedVehicleDepartureGroup / AimedVehicleArrivalGroup : new elements  added, cardinality of elements changed
* DatedOperationalInfoGroup/CountingTypeEnumeration/CountingTrendEnumeration/CountedFeatureUnitEnumeration/FacilityCategoryEnumeration: new elements
* /ToServiceJourneyInterchangeStructure/DatedCallStructure/ DisruptionGroup/RemedyStructure/FacilityConditionStructure/MonitoredCountingStructure/FacilityScheduleRefGroup/RecordedCallGroup/CallRealTimeInfoGroup/EstimatedVehicleJourneyStructure/EstimatedServiceJourneyInterchangeStructure: new elements added
* RemovedServiceJourneyInterchangeStructure/RemovedDatedVehicleJourneyStructure: new element
* ToServiceJourneyInterchangeStructure/AbstractServiceJourneyInterchangeStructure: some elements removed, new elements added
* RequestMessageRef: type changed to MessageQualifierStructure
* SubscriptionRef: type changed to SubscriptionRefStructure
* SubscriptionRenewal: new element added
* MessageRef: type changed to MessageRefStructure
* DataReceivedAcknowledgement/TerminationResponseStatusStructure:Status: cardinality changed to optional
* ReferenceContextGroup:Language: set unbounded
* remove used element: AreaOfInterestEnumeration
             
## 20201117 - Sync CEN Integration CR69
(https://github.com/SIRI-CEN/SIRI/commit/6929d799588e5f62fd6342f07882c8cfa9353e71)
* DescriptionGroup:Language type set xsd:language
* ImagesStructure new element
* DescriptionGroup:Internal new type InternalContentStructure
* DescriptionGroup:Images new type ImagesStructure
* DescriptionGroup:InfoLinksStructure new element InfoLinksStructure
* PublishingAction moved from ActionsStructure to ParameterisedActionStructure as a choice to ActionData
* PublishAtScope renamed to PublicationScope
* new element Classification in PassengerInformationActionStructure
* ActionsGroup:PublishByPerspectiveAction new element as a wrapper element for PublishingActions
* Delete unused elements in UmS ActionPeriodStructure, AffectsSegmentStructure, Duration235959
* TextualContentStructure: ActionsGroup deleted
* Element RemarkContent:Remark renamed to RemarkText
* TextualContentStructure:Internal moved after RemarkContent
* TextualContentStructure:Images new type ImagesStructure, moved after Internal
* TextualContentStructure:InfoLinks new type InfoLinksStructureStructure, moved after Images
* PublicEventTypeEnum: clean up 

## TODOs
### Remaining DIFFS with CEN
* AffectedStopDepartureGroup:DeparturePlatformName unbounded 
* AffectedStopPlaceStructure: new Lines element
* AffectedLineStructure: new elements StopPoints, StopPlaces
* AffectedStopPointStructure:StopPlaceRef / StopPlaceName / Lines
* PublishingAction subelements / PublicationWindow in ParameterisedActionStructure
* siri-modes-v1.1.xsd
* SX examples 

### TODO in CEN
* Delete zrescue
* integrate *cloze-elements

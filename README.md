# SIRI (Service interface for real-time information relating to public transport operations) XML schema
**(C) 2006-2026 NeTEx, CEN, Crown Copyright**


## Overview 🔍

SIRI is a European Norm (EN) and CEN Technical Specification (CEN/TS). It is published as a series referenced as EN 15531 and CEN/TS 15531. It is dedicated to the exchange of real-time data for public transportation between different computer systems and open data. It is based on Transmodel V6.2 (EN 12896 series) and relates to NeTEx (CEN/TS 16614 series).

SIRI services are:
- Discovery, general services to retrieve references for other services (e.g., list of lines)
- Production Timetable (SIRI-PT), for the provision of information on the planned progress of vehicles operating a specific service, identified by the vehicle time of arrival and departure at specific stops on a planned route for a particular Operational Day,
- Estimated Timetable (SIRI-ET), for the provision of information on the actual progress of Vehicle Journeys operating specific service lines, detailing expected arrival and departure times at specific stops on a planned route,
- Stop Monitoring (SIRI-SM), for a stop-centric view of vehicle arrivals and departures at a designated stop,
- Vehicle Monitoring (SIRI-VM), for the provision of information on the current location and status of a set of vehicles,
- Connection Monitoriting (SIRI-CM), for the provision of information about the expected arrival of a feeder vehicle to the operator of a connecting distributor service,
- General Message (SIRI-GM), for the exchange informative messages between identified individuals in free or an arbitrary structured format,
- Facility Monitoring (SIRI-FM), for the exchange of information about alterations to the availability of facilities for passengers among systems, including equipment monitoring, real-time management and dissemination systems,
- Situation Exchange (SIRI-SX), for the exchange of data about situations caused by planned and unplanned incidents and events, with situations being actual or potential perturbations to normal operation of a public transport network,
- Control Actions (SIRI-CA), for the exchange of information about decision made concerning the real-time management of the operation of a transport system as performed by operators while operating the services.

_Note : Many SIRI concepts are taken directly from Transmodel. The definitions and explanation of these concepts are extracted directly from the respective standard and reused in SIRI, sometimes with adaptions in order to fit the SIRI context._

### Repository content 📚

This repository contains the XML Schemas (XSD) for:
- Core
- Part 1 (Context and Framework) 
- Part 2 (Communications)
- Part 3 (Functional Service Interfaces: Production Timetable, Estimated Timetable, Stop Monitoring, Vehicle Monitoring, Connection Monitoring, General Message)
- Part 4 (Functional Service Interfaces: Facility Monitoring)
- Part 5 (Functional Service Interfaces: Situation Exchange)
- Part 6 (Functional Service Interfaces: Control Actions)

### Respository structure 📁

In each branch, we have:
- The folder `xsd` in which all the XML schemas can be found,
- The folder `examples` in which all examples can be found,
- At the root folder, `Siri.spp` which is the project for XMLSpy and `Siri.xpr` for Oxygen.

The `xsd` folder is sub-divided as follow:
- at the root, the XSD for all SIRI services,
-  `gml` for all geometry-related elements,
- `siri` for the common framework,
- `siri_model` for all components of SIRI services,
- other complementary sub-folders.

### Branches 🌿

|**Branch**|**Description**|**Maintenance status**|**Link**|
|----------|---------------|--------|--------|
|v2.2|The latest version of the XML Schema that matches the CEN documentation|Bug fixes only|[Direct link](https://github.com/SIRI-CEN/SIRI)|
|v2.1|The previous version of the XML Schema that matches the CEN documentation (without the Control Actions)|Not maintained|[Direct link](https://github.com/SIRI-CEN/SIRI/tree/v2.1)|
|v2.3-wip|All the upcoming work to improve v2.2|In development|In development|[Direct link](https://github.com/SIRI-CEN/SIRI/tree/v2.3-wip)|
|v3.0-wip|All the upcoming work preparing the migration from CEN/TS to CEN/EN for the entire SIRI series|Not yet published|[Direct link](https://github.com/SIRI-CEN/SIRI/tree/v3.0-wip)|

All other branches are considered as feature branches, meaning that they are used for development only and are to be deleted once a Pull Request is merged. See below for more details on contributions.

**Important notes:** 
- Any branch marked `wip` is a non-stable branch.
- For a specific XML Schema matching a published CEN document, use `releases`.

----

## Getting started 🛠️

### Main root schemas 

1. **siri.xsd**
Embeds SIRI:
- Common services
- Functional services
- RequestGroup and ResponseGroup

2. **siri_all_functionalServices.xsd**
Embeds all of SIRI functional services with direct links with the XML Schema of each SIRI service ().

### How to navigate the schemas

The schema is systematically divided into small modular files. Generally, for each SIRI service you should refer to their own XML Schema named **service_xxxx_service.xsd** which leads the embedded components for that given service.

### XML examples

The XML examples are sorted by SIRI Service. In each service folder, you will have the same structure:
- capabilities,
- request,
- response,
- subscription request.

----

## How to contribute 🖊️

### Starting a discussion 💬

Either for a modelling question or a request for change, please start a discussion using the [GitHub issues](https://github.com/SIRI-CEN/SIRI/issues). 
In your issue, make sure that:
- The title is a clear summary of your question / requst for change,
- The content sufficiently details:
   - The context,
   - The elements / features you want to discuss,
- If relevant, include extracts of your NeTEx file.

### Making a change 🚀

1. Identify which branch you need to target:
   - v2.3-wip for all changes that will apply to SIRI v2.2 (e.g., bug fixes, typos, improvement of certain features without breaking changes, etc.)
   - v3.0-wip for all changes that will apply when SIRI migrates to EN (e.g., deprecation of features, refactor of certain elements, breaking changes including new features, etc.) _Not yet published_
2. Create a feature branch with a clear name that identifies the SIRI service when relevant (e.g., sx_addedconcept)
3. Work on the changes and do the Pull Request

For new features, the decision between targetting v2.3-wip or v3.0-wip will be made by the group.

----

## Changelog 📰

### Releases
| Release Number | Release Date  | Description                                    | Link          |
| -------------- | ------------- | ---------------------------------------------- | ------------- |
| v2.0q          | October 2022  | Before the release of the documentation for the 2022 revision | [Code](https://github.com/SIRI-CEN/SIRI/releases/tag/v2.0r) |
| v2.1           | October 2022  | Release matching the CEN documentation for Part 1 to 5 as of 2022 revision | [Code](https://github.com/SIRI-CEN/SIRI/releases/tag/v2.1) |
| v2.2           | October 2025  | Addition of SIRI-CA, which is Part 6 in CEN documentation and was published in 2024 | [Code](https://github.com/SIRI-CEN/SIRI/releases/tag/v2.2) |

**Important notes:** 
- Releases (and their tags) are a snapshot of the corresponding working branch in time.
- For any official reference to a SIRI version, it is recommended to point to a 2-digit version (e.g., v1.3, v2.0).

### Comprehensive version history

The comprehensive versions history is available in [CHANGELOG.md](https://github.com/SIRI-CEN/SIRI/blob/v2.2/CHANGELOG.md).
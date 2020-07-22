# RTRank
Provides real time comparison against a given rank from Warcraftlogs.   
Basic use: "/rtr rank x" - to select your rank to compare to.  
Class, spec, role and encounter will be automatically inferred (Tanks are registered as DPS role for ranking).
Settings are stored across sessions.  
The data is subject to the build time of the AddOn code, which should be approximately download time.

###Commands (rtr or rtrank):  
* rank (x) -> sets the target rank to compare to to x
* background -> toggle background on or off
* text -> toggle text display on of off
* output (type) -> set output type; allowed values for (type) are "second" and "cumulative"/"total". Ex: For damage, second will show DPS, and cumulative will show total damage for the encounter.

* dummy -> toggle for "dummy use", this will in practice treat all combat entries as an encounter
reset -> resets to default settings
* dumpdb(NYI)  -> prints the current database
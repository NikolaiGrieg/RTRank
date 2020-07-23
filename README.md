# RTRank
Provides real time comparison against a mythic ranking from Warcraftlogs.  
For example when comparing against rank 1 (you can select the rank), the addon will tell the HPS/DPS of the
target rank at the current timestep into the encounter, and the relative DPS/HPS difference to you. 

For example: At 15 sec into the Wrathion encounter as a Discipline priest the rank 1 target would 
display 967k (total) or 64k (hps). If you were doing 50k hps at this timestep, the addon would also display the diff: 14k hps.

Basic use: "/rtr rank x" - to select your rank to compare to.  
Class, spec, role and encounter will be automatically inferred (Tanks are registered as DPS role for ranking).
Settings are stored across sessions.  
The data is subject to the build time of the AddOn code, which should be approximately download time.

In the current version, ranks 1-2 are available for all specs.
Only mythic raid data is available due to size constraints.

### Commands (rtr or rtrank):  
* rank (x) -> sets the target rank to compare to to x
* background -> toggle background on or off
* text -> toggle text display on of off
* output (type) -> set output type; allowed values for (type) are "second" and "cumulative"/"total". Ex: For damage, second will show DPS, and cumulative will show total damage for the encounter.

* dummy -> toggle for "dummy use", this will in practice treat all combat entries as an encounter
* reset -> resets to default settings
* dumpdb (encounterID)  -> prints the current database for the specified encounter
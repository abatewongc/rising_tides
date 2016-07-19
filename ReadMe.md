## Rising Tides

Rising Tides is an XCOM 2 content addition mod that aims to provide a DLC-like experience. Currently I looking to provide the following:

>- Three "hero"-type units, each with unique three-branch skill trees
>- A single Ghost "superclass" extension (as Soldier is to the Vanilla classes) which provides the following:
>  - Additional mobility options ("Icarus"-style vertical mobility, fall damage negation)
>  - Additional default abilities ("Mind Control", "Mind Wrack", "Mind Meld", "Reflection")
>  - Shared abilities across child classes ("Teek", "Vital Point Targeting", "Fade")
>- Special narrative missions to use these units in a controlled environment to ease balancing in a mod-rich environment

This would be a bare-bones content mod. I also have the following content in mind, but would be out of my current capability to do alone (IE I would either need to develop the skills and/or obtain additional contributors, either volunteers or contractors):

>- Voicework for each individual hero unit, as well as other characters 
>- New models/animations for armor, weapons, and map assets (and possibly faces)
>- High-quality 2D artwork (Producing Icons is possible ATM, but not much more)
>- New enemy units, possible returns from EW

###### Current TODOs:  
              - Tidy up class files (remove legacy code, document, etc)
              - Finish up current features
                - Time Stop damage pop-up (FINAL FEATURE W00t)
              - Implement Heat Channeling
              - Implement Harbinger
              - Implement Shock and Awe
                  - Design Shock and Awe
              - Fix RemoveUnitFromMeld so that it correctly removes the MeldEffect in response to a panic event (basically when the method is called other than the effect being removed) 


###### Current Unresolved:
              - // some snippets of the second to last chapter of Falling Stars
              - http://hastebin.com/raw/arukopovex
              - http://hastebin.com/ofibexiguv.avrasm
              - Heat Channel beginning implementation (http://hastebin.com/ucotodegan.vhdl, http://hastebin.com/adehowacuj.vhdl)
###### Current Table
              - Triangulation: Spread Over the Shoulder to all melded allies.
              - Heat Channeling: When this unit uses strenuous psionic abilities (listed, stuff like rift, mc, mw, li, burst) use the excess heat buildup from your weapon to fuel the ability, fully reloading the unit's weapon and reducing the ability's cooldown by one for each point of ammo restored.
              
              

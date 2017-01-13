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
  - Berserker:
      - Implement Stealth visual overlay
  - Marksman: 
      - Nothing
  - Gatherer: 
      - Everything

###### Current Unresolved:
      - Visuals
      - Dashing Strike
      - Add mental effect cleanse to RTMentor
      - Implement OnTacticalGameEnd() for all RTGameState_Effects
      - Prevent MultiTarget_Radius effects (TimeStop and OverTheShoulder) from randomly opening all doors in their AO
      - Implement Unrealscript-based Kismet Variable Handling for Time Stands Still
      - Implement RTEffect_Counter event-based cooldown tracker cleansing for Heat Channel
      - Implement cooldown tracker for Fade
      - Implement will-based damage increase for Psionic Blade
      - Implement Disabling Shot ap reduction (-1)
###### Current Table
      - Triangulation: Spread Over the Shoulder to all melded allies.
      - Shatter The Line: If this unit kills an enemy within X tiles, it triggers a flush effect on other enemies within X tiles. 2/3 turn cooldown. credits to /u/PostOfficeBuddy
###### Current Bugs
      - Time Stop damage calculation isn't visualized properly
      - Time Stop probably won't work on Frozen enemies
      - Time Stop doesn't work on Stasis'd units (despite this making no sense whatsoever) because it's hard-coded
      - Shock And Awe readout not displayed
              
              

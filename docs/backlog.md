# HTG backlog

Near-term build ideas. Canonical detail can live in GitHub Issues; this file is for a quick, repo-local view.

---

## Template

Copy from **Task name** through **What it is** for each item.

**Task name:**  
**Priority:** P0 | P1 | P2 | P3  
**Status:** Backlog | In progress | Complete  
**What it is:**  

---

**Task name:**  Secondary Colors on non-utilized icons on tab dock
**Priority:** P2
**Status:** Backlog
**What it is:**  Change the color of the icons in the dock which aren't being utilized in the view to be GTC_Colors secondary

---

**Task name:**  Remove "About Handicap" from the profile
**Priority:** P3  
**Status:** Backlog  
**What it is:**  In the Profile section, at the bottom there is a section "About Handicap". It should be removed entirely

---

**Task name:**  Change background color to GTC_Colors.Background for all sections
**Priority:** P3  
**Status:** Backlog 
**What it is:**  Change background color to GTC_Colors.Background for all sections when the user is in light mode

---

**Task name:**  New Feature: First Time Set Up
**Priority:** P3  
**Status:** Backlog  
**What it is:**  This should be a set-up for the first time a user is setting up their bag. At the bottom of the Profile section should be "Initial Bag Set Up". The basic process is the user picks and arranges their clubs. The first screen will be "Select the Woods in your bag?". Driver will auto selected, then a list of 2 - 9 with "Wood" after each one. Example "3 Wood". At the top of each of these screens will be a live counter of clubs selected (x/13), "Back", and "Next". Back and Next will be left and right arrows.  If a user clicks on 3 Wood, the counter will instantly go to "2/13" (driver was 1), and it will go back to 1/13 if they unselect it. Next will be Hybrids (1-9), Then will be Irons (1-9), and Wedges (Pitching, Gap, Sand, Lob). The application will not allow the user to select more than 13 clubs. After the user clicks "Next" on wedges, it will ask the user to rearrange their bag based on carry distance. The user can drag and drop the order. Next, it will ask the user to pre-fill any full yardages they know. After the user hits next, if there are unfilled yardages, it will ask say "Estimating other yardages". For clubs to estimate with yardages above and below them, an algorithm will linearly estimate yardages based on the number of clubs between known points and the gap. For example, if an 8 iron needs a yardage, and the 9 iron is 120 and the 7 iron is 140, the 8 iron will be 130. If the 9 iron is 120, the 7 iron is unknown, and the 6 iron is 135, the 8 iron will be 125 and the 7 iron is 130. For clubs needing an estimate without barriers, use 10 yards as the base case. For example, if the Sand Wedge is known as 90 and the Lob Wedge is next lower, it should be 80. If the 3 iron is 200 and there are a 3 wood and driver above, the 3 wood would be 210 and the driver 220. Once the algorithm has picked yardages, the user's bag is initially complete. The user will be told "Head to the Range to Dial In Your Yardages"

---

**Task name:**  Utilize wireframe from Claude design - Range Mode
**Priority:**  P1 
**Status:** In Progress
**What it is:**  Refactor Range Mode to match Golf Mode visual style using a documentation-first migration path.  
**Definition of done:**  

- `docs/wireframes/GolfModeWireFrame.md` is the canonical style reference.  
- `docs/wireframes/RangeModeWireFrame_Legacy.md` fully maps each wireframe box and subcomponent (settings, interactions, dependencies).  
- A legacy-to-shared conversion matrix and phased migration strategy are documented and implementation-ready.  
- Refactor implementation follows shared style defaults/tokens (no page-level hardcoded stylistic patterns).

---

**Task name:**  Utilize wireframe from Claude design - Club Mode
**Priority:**  P1 
**Status:** In Progress
**What it is:**  Refactor Club Management Mode to match Golf Mode visual style using a documentation-first migration path.  
**Definition of done:**  

- `docs/wireframes/GolfModeWireFrame.md` is the canonical style reference.  
- `docs/wireframes/ClubManagementModeWireFrame_Legacy.md` fully maps each wireframe box and subcomponent (settings, interactions, dependencies).  
- A legacy-to-shared conversion matrix and phased migration strategy are documented and implementation-ready.  
- Refactor implementation follows shared style defaults/tokens (no page-level hardcoded stylistic patterns).

---

**Task name:**  Utilize wireframe from Claude design - Profile
**Priority:**  P1 
**Status:** In Progress
**What it is:**  Attempting to build in Cursor
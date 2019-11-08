##  Changes made on 5 jan 2018
- Retrieval buffer does not clear when the operator that has fired has no actions (in Model.swift)
- There will be no operator compilation if there is any condition in operator 2 that has an RT in it (in Operator.swift)
- When compiling, also initiate a first association between the new operator and the current goal/skill
- Nixed the adding of a reference to successful operators (interferes with association learning)
## 8 jan 2018
- Added a Run 100 button
## 12 jan 2018
- Learning of associations between goals and operators is now between all chunks in goal buffer slots, instead of just slot1
- Add set-buffer-slot to ScriptFunctions
- Also added get-buffer-slot
- TODO: May need to record which goal was in the goal buffer when the operator fired, and strengthen those connections
## 21 jan 2018
- Used Charts framework for graphs
## 26 feb 2018
- Added the option to push a value in BufferName0 (e.g., WM0) to replace the whole chunk in the buffer. This makes it much easier for subgoals to push results to the parent

## 5 mar 2018
- implemented inter operator association learning. Now it is directly between two operators, it may have to become a three-way association between two operators and the goal

## 8 Mar 2018
- Added "skill" as a synomym for "goal" in the model syntax.

## 19 Mar 2018
- Added Instatiate-skill function that makes an instantiate of a skill, so that multiple instantiations of the same skill can be part of a single task.
- Rounded latencies to three digits in the trace.
- Removed the necessity to define skills in the task definition

## 2 May 2018
- Added a new viewer to inspect the conflict resolution trace
- Fixed spreading activation from the goal to prevent duplicate activation
- Spreading activation from the goal is now no longer divided by the number of slots

## 18 Oct 2018
- Automatic build number increase on archive
- Added option to view model code in trace window

## 30 Oct 2018
- Font changes in trace window when model code is displayed

## 8 Nov 2018
- Fan is always minimally 1 to prevent infinite spreading

## 30 Nov 2018
Adding the option to learn associations between operators and all the chunks in the buffers. To use this set context-operator-learning to true, beta to some learning speed and reward to some reward value. Also make sure to switch on spreading for
the relevant buffers, otherwise the new associations will not do very much.

## 4 Nov 2019
Fixed some issues in the conflict set trace. One problem that remains is that the noise on the learned Sji's is different in the trace than in the actual conflict resolution. This can only be solved by 
storing all these values, which may affect overall efficiency too much.
Added the read-file command that reads a text file into an array,


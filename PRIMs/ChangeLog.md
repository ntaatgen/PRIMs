#  Changes made on 5 jan 2018
- Retrieval buffer does not clear when the operator that has fired has no actions (in Model.swift)
- There will be no operator compilation if there is any condition in operator 2 that has an RT in it (in Operator.swift)
- When compiling, also initiate a first association between the new operator and the current goal/skill
- Nixed the adding of a reference to successful operators (interferes with association learning)
